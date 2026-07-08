///|
pub fn eval_program_naive(
  prog : @ast.Program
) -> Map[String, @core.Relation]? {
  let strata = match prog.stratify() {
    Some(s) => s
    None => return None // Unstratifiable
  }

  let db : Map[String, @core.Relation] = {}
  prog.relations.each(fn(name, rel) { db.set(name, rel.clone()) })

  // Initialize empty IDB relations if not present
  let idb_names = prog.get_idb_relations()
  for i = 0; i < idb_names.length(); i = i + 1 {
    let name = idb_names[i]
    if db.contains(name) == false {
      // Find schema from first rule head
      for r = 0; r < prog.rules.length(); r = r + 1 {
        if prog.rules[r].head.rel_name == name {
          db.set(
            name,
            @core.Relation::new(
              name,
              make_dummy_schema(prog.rules[r].head.terms.length()),
            ),
          )
          break
        }
      }
    }
  }

  for s = 0; s < strata.length(); s = s + 1 {
    let stratum = strata[s]
    for iter = 0; iter < 10000; iter = iter + 1 {
      let mut changed = false
      for r = 0; r < stratum.length(); r = r + 1 {
        let rule = stratum[r]
        let new_tuples = eval_rule(rule, db)
        let target_rel = match db.get(rule.head.rel_name) {
          Some(rel) => rel
          None => {
            let rel = @core.Relation::new(
              rule.head.rel_name,
              new_tuples.schema,
            )
            db.set(rule.head.rel_name, rel)
            rel
          }
        }
        for i = 0; i < new_tuples.tuples.length(); i = i + 1 {
          if target_rel.insert(new_tuples.tuples[i]) {
            changed = true
          }
        }
      }
      if changed == false {
        break
      }
    }
  }

  Some(db)
}

///|
pub fn eval_program_semi_naive(
  prog : @ast.Program
) -> Map[String, @core.Relation]? {
  let strata = match prog.stratify() {
    Some(s) => s
    None => return None
  }

  let accum_db : Map[String, @core.Relation] = {}
  prog.relations.each(fn(name, rel) { accum_db.set(name, rel.clone()) })

  let idb_set : Map[String, Bool] = {}
  let idb_names = prog.get_idb_relations()
  for i = 0; i < idb_names.length(); i = i + 1 {
    let name = idb_names[i]
    idb_set.set(name, true)
    if accum_db.contains(name) == false {
      for r = 0; r < prog.rules.length(); r = r + 1 {
        if prog.rules[r].head.rel_name == name {
          accum_db.set(
            name,
            @core.Relation::new(
              name,
              make_dummy_schema(prog.rules[r].head.terms.length()),
            ),
          )
          break
        }
      }
    }
  }

  for s = 0; s < strata.length(); s = s + 1 {
    let stratum = strata[s]
    let delta_db : Map[String, @core.Relation] = {}

    // Initialize empty delta tables for all relations in this stratum
    for r = 0; r < stratum.length(); r = r + 1 {
      let head_name = stratum[r].head.rel_name
      if delta_db.contains(head_name) == false {
        let schema = match accum_db.get(head_name) {
          Some(rel) => rel.schema
          None => make_dummy_schema(stratum[r].head.terms.length())
        }
        delta_db.set(head_name, @core.Relation::new(head_name, schema))
      }
    }

    // Round 0: Evaluate all rules against accum_db (base facts and lower strata)
    for r = 0; r < stratum.length(); r = r + 1 {
      let rule = stratum[r]
      let new_tuples = eval_rule(rule, accum_db)
      let target_rel = match accum_db.get(rule.head.rel_name) {
        Some(rel) => rel
        None => {
          let rel = @core.Relation::new(rule.head.rel_name, new_tuples.schema)
          accum_db.set(rule.head.rel_name, rel)
          rel
        }
      }
      let target_delta = match delta_db.get(rule.head.rel_name) {
        Some(rel) => rel
        None => {
          let rel = @core.Relation::new(rule.head.rel_name, new_tuples.schema)
          delta_db.set(rule.head.rel_name, rel)
          rel
        }
      }
      for i = 0; i < new_tuples.tuples.length(); i = i + 1 {
        let t = new_tuples.tuples[i]
        if target_rel.insert(t) {
          ignore(target_delta.insert(t))
        }
      }
    }

    // Fixpoint Loop: iterate using delta_db
    for iter = 0; iter < 10000; iter = iter + 1 {
      let mut any_delta = false
      delta_db.each(fn(_name, rel) {
        if rel.is_empty() == false {
          any_delta = true
        }
      })
      if any_delta == false {
        break
      }

      let next_delta_db : Map[String, @core.Relation] = {}
      delta_db.each(fn(name, rel) {
        next_delta_db.set(name, @core.Relation::new(name, rel.schema))
      })

      for r = 0; r < stratum.length(); r = r + 1 {
        let rule = stratum[r]
        let new_tuples = eval_rule_differentiated(
          rule, accum_db, delta_db, idb_set,
        )
        let target_rel = match accum_db.get(rule.head.rel_name) {
          Some(rel) => rel
          None => continue
        }
        let target_delta = match next_delta_db.get(rule.head.rel_name) {
          Some(rel) => rel
          None => {
            let rel = @core.Relation::new(
              rule.head.rel_name,
              new_tuples.schema,
            )
            next_delta_db.set(rule.head.rel_name, rel)
            rel
          }
        }
        for i = 0; i < new_tuples.tuples.length(); i = i + 1 {
          let t = new_tuples.tuples[i]
          if target_rel.insert(t) {
            ignore(target_delta.insert(t))
          }
        }
      }

      // Update delta_db for next round
      delta_db.clear()
      next_delta_db.each(fn(name, rel) { delta_db.set(name, rel) })
    }
  }

  Some(accum_db)
}
