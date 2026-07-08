///|
pub fn verify_fixpoint_invariance(
  prog : @ast.Program,
  db : Map[String, @core.Relation]
) -> Bool {
  // In a true fixpoint, running another naive evaluation iteration over db must yield ZERO new tuples!
  let next_db : Map[String, @core.Relation] = {}
  db.each(fn(name, rel) { next_db.set(name, rel.clone()) })

  match prog.stratify() {
    Some(strata) => {
      for s = 0; s < strata.length(); s = s + 1 {
        let stratum = strata[s]
        for r = 0; r < stratum.length(); r = r + 1 {
          let rule = stratum[r]
          let new_tuples = @engine.eval_rule(rule, next_db)
          let target_rel = match next_db.get(rule.head.rel_name) {
            Some(rel) => rel
            None => return false
          }
          for i = 0; i < new_tuples.tuples.length(); i = i + 1 {
            if target_rel.insert(new_tuples.tuples[i]) {
              // A new tuple was discovered after fixpoint termination! Invariance violated!
              return false
            }
          }
        }
      }
      true
    }
    None => false
  }
}

///|
pub fn verify_relation_deduplication(rel : @core.Relation) -> Bool {
  let seen : Map[@core.Tuple, Bool] = {}
  for i = 0; i < rel.tuples.length(); i = i + 1 {
    let t = rel.tuples[i]
    if seen.contains(t) {
      return false
    }
    seen.set(t, true)
  }
  true
}
