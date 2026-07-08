///|
test "transitive closure reachability naive vs semi-naive" {
  let prog = @ast.Program::new()
  let edges = @core.Relation::new("edge", ["from", "to"])
  ignore(edges.insert(@core.Tuple::new([@core.Value::from_int(1), @core.Value::from_int(2)])))
  ignore(edges.insert(@core.Tuple::new([@core.Value::from_int(2), @core.Value::from_int(3)])))
  ignore(edges.insert(@core.Tuple::new([@core.Value::from_int(3), @core.Value::from_int(4)])))
  ignore(edges.insert(@core.Tuple::new([@core.Value::from_int(4), @core.Value::from_int(5)])))
  prog.add_relation(edges)

  // reach(X, Y) :- edge(X, Y).
  // reach(X, Y) :- edge(X, Z), reach(Z, Y).
  ignore(
    prog.add_rule(
      @ast.Rule::new(
        @ast.Literal::new("reach", [@ast.Var("X"), @ast.Var("Y")], false),
        [@ast.Literal::new("edge", [@ast.Var("X"), @ast.Var("Y")], false)],
      ),
    ),
  )
  ignore(
    prog.add_rule(
      @ast.Rule::new(
        @ast.Literal::new("reach", [@ast.Var("X"), @ast.Var("Y")], false),
        [
          @ast.Literal::new("edge", [@ast.Var("X"), @ast.Var("Z")], false),
          @ast.Literal::new("reach", [@ast.Var("Z"), @ast.Var("Y")], false),
        ],
      ),
    ),
  )

  let res_naive = match eval_program_naive(prog) {
    Some(db) => db
    None => abort("naive eval failed")
  }
  let reach_naive = match res_naive.get("reach") {
    Some(r) => r
    None => abort("reach not found in naive")
  }
  // 4 edges: (1,2), (2,3), (3,4), (4,5) -> 4 + 3 + 2 + 1 = 10 reachable pairs!
  assert_eq(reach_naive.len(), 10)

  let res_semi = match eval_program_semi_naive(prog) {
    Some(db) => db
    None => abort("semi naive eval failed")
  }
  let reach_semi = match res_semi.get("reach") {
    Some(r) => r
    None => abort("reach not found in semi")
  }
  assert_eq(reach_semi.len(), 10)
  assert_eq(
    reach_semi.contains(
      @core.Tuple::new([@core.Value::from_int(1), @core.Value::from_int(5)]),
    ),
    true,
  )
}

///|
test "stratified negation evaluation" {
  let prog = @ast.Program::new()
  let nodes = @core.Relation::new("node", ["id"])
  ignore(nodes.insert(@core.Tuple::new([@core.Value::from_int(1)])))
  ignore(nodes.insert(@core.Tuple::new([@core.Value::from_int(2)])))
  ignore(nodes.insert(@core.Tuple::new([@core.Value::from_int(3)])))
  prog.add_relation(nodes)

  let edges = @core.Relation::new("edge", ["from", "to"])
  ignore(edges.insert(@core.Tuple::new([@core.Value::from_int(1), @core.Value::from_int(2)])))
  prog.add_relation(edges)

  // reach(X, Y) :- edge(X, Y).
  // isolated(X) :- node(X), !reach(1, X).
  ignore(
    prog.add_rule(
      @ast.Rule::new(
        @ast.Literal::new("reach", [@ast.Var("X"), @ast.Var("Y")], false),
        [@ast.Literal::new("edge", [@ast.Var("X"), @ast.Var("Y")], false)],
      ),
    ),
  )
  ignore(
    prog.add_rule(
      @ast.Rule::new(
        @ast.Literal::new("isolated", [@ast.Var("X")], false),
        [
          @ast.Literal::new("node", [@ast.Var("X")], false),
          @ast.Literal::new(
            "reach",
            [@ast.Const(@core.Value::from_int(1)), @ast.Var("X")],
            true,
          ),
        ],
      ),
    ),
  )

  let res = match eval_program_semi_naive(prog) {
    Some(db) => db
    None => abort("stratified eval failed")
  }
  let iso = match res.get("isolated") {
    Some(r) => r
    None => abort("isolated not found")
  }
  // Node 1 is not reachable from 1 (no self loop), Node 3 is not reachable from 1. Node 2 IS reachable from 1.
  // So isolated contains 1 and 3!
  assert_eq(iso.len(), 2)
  assert_eq(iso.contains(@core.Tuple::new([@core.Value::from_int(1)])), true)
  assert_eq(iso.contains(@core.Tuple::new([@core.Value::from_int(3)])), true)
  assert_eq(iso.contains(@core.Tuple::new([@core.Value::from_int(2)])), false)
}
