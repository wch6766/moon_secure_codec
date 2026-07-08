///|
pub fn join_natural(r1 : @core.Relation, r2 : @core.Relation) -> @core.Relation {
  let shared_cols : Array[String] = []
  let r1_shared_idx : Array[Int] = []
  let r2_shared_idx : Array[Int] = []
  let r2_non_shared_cols : Array[String] = []
  let r2_non_shared_idx : Array[Int] = []

  for i = 0; i < r2.schema.length(); i = i + 1 {
    let col = r2.schema[i]
    match r1.get_col_idx(col) {
      Some(idx1) => {
        shared_cols.push(col)
        r1_shared_idx.push(idx1)
        r2_shared_idx.push(i)
      }
      None => {
        r2_non_shared_cols.push(col)
        r2_non_shared_idx.push(i)
      }
    }
  }

  let new_schema : Array[String] = []
  for i = 0; i < r1.schema.length(); i = i + 1 {
    new_schema.push(r1.schema[i])
  }
  for i = 0; i < r2_non_shared_cols.length(); i = i + 1 {
    new_schema.push(r2_non_shared_cols[i])
  }

  let res = @core.Relation::new(r1.name + "_" + r2.name, new_schema)

  if shared_cols.length() == 0 {
    // Cartesian product
    for i = 0; i < r1.tuples.length(); i = i + 1 {
      let t1 = r1.tuples[i]
      for j = 0; j < r2.tuples.length(); j = j + 1 {
        let t2 = r2.tuples[j]
        let merged : Array[@core.Value] = []
        for k = 0; k < t1.values.length(); k = k + 1 {
          merged.push(t1.values[k])
        }
        for k = 0; k < t2.values.length(); k = k + 1 {
          merged.push(t2.values[k])
        }
        ignore(res.insert(@core.Tuple::new(merged)))
      }
    }
    return res
  }

  // Hash Join using shared keys from r2
  let hash_index : Map[@core.Tuple, Array[@core.Tuple]] = {}
  for i = 0; i < r2.tuples.length(); i = i + 1 {
    let t2 = r2.tuples[i]
    let key_vals : Array[@core.Value] = []
    for j = 0; j < r2_shared_idx.length(); j = j + 1 {
      match t2.get(r2_shared_idx[j]) {
        Some(v) => key_vals.push(v)
        None => ()
      }
    }
    let key = @core.Tuple::new(key_vals)
    match hash_index.get(key) {
      Some(arr) => arr.push(t2)
      None => hash_index.set(key, [t2])
    }
  }

  for i = 0; i < r1.tuples.length(); i = i + 1 {
    let t1 = r1.tuples[i]
    let key_vals : Array[@core.Value] = []
    for j = 0; j < r1_shared_idx.length(); j = j + 1 {
      match t1.get(r1_shared_idx[j]) {
        Some(v) => key_vals.push(v)
        None => ()
      }
    }
    let key = @core.Tuple::new(key_vals)
    match hash_index.get(key) {
      Some(matches) =>
        for j = 0; j < matches.length(); j = j + 1 {
          let t2 = matches[j]
          let merged : Array[@core.Value] = []
          for k = 0; k < t1.values.length(); k = k + 1 {
            merged.push(t1.values[k])
          }
          for k = 0; k < r2_non_shared_idx.length(); k = k + 1 {
            match t2.get(r2_non_shared_idx[k]) {
              Some(v) => merged.push(v)
              None => ()
            }
          }
          ignore(res.insert(@core.Tuple::new(merged)))
        }
      None => ()
    }
  }

  res
}

///|
pub fn join_on(
  r1 : @core.Relation,
  r2 : @core.Relation,
  col1 : String,
  col2 : String
) -> @core.Relation {
  let idx1 = match r1.get_col_idx(col1) {
    Some(i) => i
    None => return r1.clone_empty()
  }
  let idx2 = match r2.get_col_idx(col2) {
    Some(i) => i
    None => return r1.clone_empty()
  }

  let new_schema : Array[String] = []
  for i = 0; i < r1.schema.length(); i = i + 1 {
    new_schema.push(r1.schema[i])
  }
  for i = 0; i < r2.schema.length(); i = i + 1 {
    new_schema.push(r2.schema[i])
  }
  let res = @core.Relation::new(r1.name + "_" + r2.name, new_schema)

  let hash_index : Map[@core.Value, Array[@core.Tuple]] = {}
  for i = 0; i < r2.tuples.length(); i = i + 1 {
    let t2 = r2.tuples[i]
    match t2.get(idx2) {
      Some(val) =>
        match hash_index.get(val) {
          Some(arr) => arr.push(t2)
          None => hash_index.set(val, [t2])
        }
      None => ()
    }
  }

  for i = 0; i < r1.tuples.length(); i = i + 1 {
    let t1 = r1.tuples[i]
    match t1.get(idx1) {
      Some(val) =>
        match hash_index.get(val) {
          Some(matches) =>
            for j = 0; j < matches.length(); j = j + 1 {
              let t2 = matches[j]
              let merged : Array[@core.Value] = []
              for k = 0; k < t1.values.length(); k = k + 1 {
                merged.push(t1.values[k])
              }
              for k = 0; k < t2.values.length(); k = k + 1 {
                merged.push(t2.values[k])
              }
              ignore(res.insert(@core.Tuple::new(merged)))
            }
          None => ()
        }
      None => ()
    }
  }

  res
}
