///|
test "graph reachability and cycle detection" {
  let edges = @core.Relation::new("edge", ["from", "to"])
  ignore(edges.insert(@core.Tuple::new([@core.Value::from_int(1), @core.Value::from_int(2)])))
  ignore(edges.insert(@core.Tuple::new([@core.Value::from_int(2), @core.Value::from_int(3)])))
  ignore(edges.insert(@core.Tuple::new([@core.Value::from_int(3), @core.Value::from_int(4)])))

  assert_eq(reachable(edges, 1L, 4L), true)
  assert_eq(reachable(edges, 4L, 1L), false)
  assert_eq(has_cycle(edges), false)

  // Add cycle 4 -> 2
  ignore(edges.insert(@core.Tuple::new([@core.Value::from_int(4), @core.Value::from_int(2)])))
  assert_eq(has_cycle(edges), true)
  assert_eq(reachable(edges, 4L, 2L), true)
}

///|
test "connected components" {
  let edges = @core.Relation::new("edge", ["u", "v"])
  // Component 1: {1, 2}
  ignore(edges.insert(@core.Tuple::new([@core.Value::from_int(1), @core.Value::from_int(2)])))
  // Component 2: {10, 20}
  ignore(edges.insert(@core.Tuple::new([@core.Value::from_int(10), @core.Value::from_int(20)])))

  let comps = connected_components(edges)
  assert_eq(comps.contains(@core.Tuple::new([@core.Value::from_int(1), @core.Value::from_int(2)])), true)
  assert_eq(comps.contains(@core.Tuple::new([@core.Value::from_int(2), @core.Value::from_int(1)])), true)
  assert_eq(comps.contains(@core.Tuple::new([@core.Value::from_int(1), @core.Value::from_int(10)])), false)
}
