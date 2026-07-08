///|
test "value equality and string conversion" {
  let v1 = Value::from_int(42)
  let v2 = Value::from_int(42)
  let v3 = Value::from_str("hello")
  assert_eq(v1 == v2, true)
  assert_eq(v1 == v3, false)
  assert_eq(v1.to_string(), "42")
  assert_eq(v3.to_string(), "hello")
}

///|
test "tuple operations" {
  let t1 = Tuple::new([Value::from_int(1), Value::from_str("Alice")])
  let t2 = Tuple::new([Value::from_int(1), Value::from_str("Alice")])
  assert_eq(t1 == t2, true)
  assert_eq(t1.arity(), 2)
  assert_eq(t1.get(0) == Some(Value::from_int(1)), true)
  assert_eq(t1.get(2) == None, true)
}

///|
test "relation insertion and deduplication" {
  let rel = Relation::new("users", ["id", "name"])
  assert_eq(rel.arity(), 2)
  assert_eq(rel.get_col_idx("name") == Some(1), true)
  
  let t1 = Tuple::new([Value::from_int(101), Value::from_str("Alice")])
  let t2 = Tuple::new([Value::from_int(101), Value::from_str("Alice")])
  let t3 = Tuple::new([Value::from_int(102), Value::from_str("Bob")])
  
  assert_eq(rel.insert(t1), true)
  assert_eq(rel.insert(t2), false) // deduplicated
  assert_eq(rel.insert(t3), true)
  assert_eq(rel.len(), 2)
  assert_eq(rel.contains(t1), true)
}
