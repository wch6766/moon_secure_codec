///|
pub(all) struct Program {
  relations : Map[String, @core.Relation]
  rules : Array[Rule]
}

///|
pub fn Program::new() -> Program {
  { relations: {}, rules: [] }
}

///|
pub fn Program::add_relation(self : Program, rel : @core.Relation) -> Unit {
  self.relations.set(rel.name, rel)
}

///|
pub fn Program::get_relation(self : Program, name : String) -> @core.Relation? {
  self.relations.get(name)
}

///|
pub fn Program::add_rule(self : Program, rule : Rule) -> Bool {
  if rule.is_safe() == false {
    return false
  }
  self.rules.push(rule)
  true
}

///|
pub fn Program::get_edb_relations(self : Program) -> Array[String] {
  let idb : Map[String, Bool] = {}
  for i = 0; i < self.rules.length(); i = i + 1 {
    idb.set(self.rules[i].head.rel_name, true)
  }
  let edb : Array[String] = []
  self.relations.each(fn(name, _rel) {
    if idb.contains(name) == false {
      edb.push(name)
    }
  })
  edb
}

///|
pub fn Program::get_idb_relations(self : Program) -> Array[String] {
  let idb : Map[String, Bool] = {}
  for i = 0; i < self.rules.length(); i = i + 1 {
    idb.set(self.rules[i].head.rel_name, true)
  }
  let res : Array[String] = []
  idb.each(fn(name, _val) {
    res.push(name)
  })
  res
}

///|
pub fn Program::stratify(self : Program) -> Array[Array[Rule]]? {
  let idb_set : Map[String, Bool] = {}
  for i = 0; i < self.rules.length(); i = i + 1 {
    idb_set.set(self.rules[i].head.rel_name, true)
  }
  let idb_names : Array[String] = []
  idb_set.each(fn(name, _val) {
    idb_names.push(name)
  })
  let num_idb = idb_names.length()

  let ranks : Map[String, Int] = {}
  for i = 0; i < num_idb; i = i + 1 {
    ranks.set(idb_names[i], 0)
  }

  // Bellman-Ford style relaxation to find strata and negative cycles
  for iter = 0; iter < num_idb + 1; iter = iter + 1 {
    let mut changed = false
    for r = 0; r < self.rules.length(); r = r + 1 {
      let rule = self.rules[r]
      let head_name = rule.head.rel_name
      let head_rank = match ranks.get(head_name) {
        Some(v) => v
        None => 0
      }

      for b = 0; b < rule.body.length(); b = b + 1 {
        let lit = rule.body[b]
        if idb_set.contains(lit.rel_name) {
          let body_rank = match ranks.get(lit.rel_name) {
            Some(v) => v
            None => 0
          }
          let weight = if lit.is_negative { 1 } else { 0 }
          let req = body_rank + weight
          if req > head_rank {
            if iter == num_idb {
              // Negative cycle detected! Unstratifiable program
              return None
            }
            ranks.set(head_name, req)
            changed = true
          }
        }
      }
    }
    if changed == false {
      break
    }
  }

  // Group rules by strata index
  let mut max_stratum = 0
  for i = 0; i < self.rules.length(); i = i + 1 {
    let rank = match ranks.get(self.rules[i].head.rel_name) {
      Some(v) => v
      None => 0
    }
    if rank > max_stratum {
      max_stratum = rank
    }
  }

  let strata : Array[Array[Rule]] = []
  for s = 0; s <= max_stratum; s = s + 1 {
    strata.push([])
  }

  for i = 0; i < self.rules.length(); i = i + 1 {
    let rule = self.rules[i]
    let rank = match ranks.get(rule.head.rel_name) {
      Some(v) => v
      None => 0
    }
    strata[rank].push(rule)
  }

  Some(strata)
}
