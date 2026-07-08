///|
pub fn select(
  rel : @core.Relation,
  predicate : (@core.Tuple) -> Bool
) -> @core.Relation {
  let res = rel.clone_empty()
  for i = 0; i < rel.tuples.length(); i = i + 1 {
    let t = rel.tuples[i]
    if predicate(t) {
      ignore(res.insert(t))
    }
  }
  res
}

///|
pub fn project(
  rel : @core.Relation,
  target_cols : Array[String]
) -> @core.Relation {
  let indices : Array[Int] = []
  for i = 0; i < target_cols.length(); i = i + 1 {
    match rel.get_col_idx(target_cols[i]) {
      Some(idx) => indices.push(idx)
      None => return @core.Relation::new(rel.name + "_proj", target_cols)
    }
  }
  let res = @core.Relation::new(rel.name + "_proj", target_cols)
  for i = 0; i < rel.tuples.length(); i = i + 1 {
    let t = rel.tuples[i]
    let new_vals : Array[@core.Value] = []
    for j = 0; j < indices.length(); j = j + 1 {
      match t.get(indices[j]) {
        Some(v) => new_vals.push(v)
        None => ()
      }
    }
    if new_vals.length() == target_cols.length() {
      ignore(res.insert(@core.Tuple::new(new_vals)))
    }
  }
  res
}

///|
pub fn rename(
  rel : @core.Relation,
  new_name : String,
  new_schema : Array[String]
) -> @core.Relation {
  if new_schema.length() != rel.arity() {
    return rel.clone()
  }
  let res = @core.Relation::new(new_name, new_schema)
  for i = 0; i < rel.tuples.length(); i = i + 1 {
    ignore(res.insert(rel.tuples[i]))
  }
  res
}

///|
pub fn union(r1 : @core.Relation, r2 : @core.Relation) -> @core.Relation {
  let res = r1.clone()
  if r1.arity() == r2.arity() {
    for i = 0; i < r2.tuples.length(); i = i + 1 {
      ignore(res.insert(r2.tuples[i]))
    }
  }
  res
}

///|
pub fn diff(r1 : @core.Relation, r2 : @core.Relation) -> @core.Relation {
  let res = r1.clone_empty()
  if r1.arity() != r2.arity() {
    return r1.clone()
  }
  for i = 0; i < r1.tuples.length(); i = i + 1 {
    let t = r1.tuples[i]
    if r2.contains(t) == false {
      ignore(res.insert(t))
    }
  }
  res
}

///|
pub fn intersect(r1 : @core.Relation, r2 : @core.Relation) -> @core.Relation {
  let res = r1.clone_empty()
  if r1.arity() != r2.arity() {
    return res
  }
  for i = 0; i < r1.tuples.length(); i = i + 1 {
    let t = r1.tuples[i]
    if r2.contains(t) {
      ignore(res.insert(t))
    }
  }
  res
}
