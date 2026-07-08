///|
test "selection and projection" {
  let rel = @core.Relation::new("emp", ["id", "name", "dept"])
  ignore(rel.insert(@core.Tuple::new([@core.Value::from_int(1), @core.Value::from_str("Alice"), @core.Value::from_str("Eng")])))
  ignore(rel.insert(@core.Tuple::new([@core.Value::from_int(2), @core.Value::from_str("Bob"), @core.Value::from_str("HR")])))
  ignore(rel.insert(@core.Tuple::new([@core.Value::from_int(3), @core.Value::from_str("Charlie"), @core.Value::from_str("Eng")])))

  let engs = select(rel, fn(t) {
    match t.get(2) {
      Some(v) => v == @core.Value::from_str("Eng")
      None => false
    }
  })
  assert_eq(engs.len(), 2)

  let names = project(engs, ["name"])
  assert_eq(names.arity(), 1)
  assert_eq(names.len(), 2)
}

///|
test "natural join and join on" {
  let r1 = @core.Relation::new("employees", ["emp_id", "dept_id", "name"])
  ignore(r1.insert(@core.Tuple::new([@core.Value::from_int(1), @core.Value::from_int(10), @core.Value::from_str("Alice")])))
  ignore(r1.insert(@core.Tuple::new([@core.Value::from_int(2), @core.Value::from_int(20), @core.Value::from_str("Bob")])))

  let r2 = @core.Relation::new("departments", ["dept_id", "dept_name"])
  ignore(r2.insert(@core.Tuple::new([@core.Value::from_int(10), @core.Value::from_str("Engineering")])))
  ignore(r2.insert(@core.Tuple::new([@core.Value::from_int(20), @core.Value::from_str("Marketing")])))

  let joined = join_natural(r1, r2)
  assert_eq(joined.len(), 2)
  assert_eq(joined.arity(), 4) // emp_id, dept_id, name, dept_name
}

///|
test "set operations union diff intersect" {
  let r1 = @core.Relation::new("A", ["x"])
  ignore(r1.insert(@core.Tuple::new([@core.Value::from_int(1)])))
  ignore(r1.insert(@core.Tuple::new([@core.Value::from_int(2)])))

  let r2 = @core.Relation::new("B", ["x"])
  ignore(r2.insert(@core.Tuple::new([@core.Value::from_int(2)])))
  ignore(r2.insert(@core.Tuple::new([@core.Value::from_int(3)])))

  assert_eq(union(r1, r2).len(), 3)
  assert_eq(intersect(r1, r2).len(), 1)
  assert_eq(diff(r1, r2).len(), 1)
}
