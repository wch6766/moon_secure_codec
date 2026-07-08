///|
pub fn reachable(
  edges : @core.Relation,
  from_node : Int64,
  to_node : Int64
) -> Bool {
  let prog = @ast.Program::new()
  prog.add_relation(edges)

  let rule1 = @ast.Rule::new(
    @ast.Literal::new("reach", [@ast.Var("X"), @ast.Var("Y")], false),
    [@ast.Literal::new(edges.name, [@ast.Var("X"), @ast.Var("Y")], false)],
  )
  let rule2 = @ast.Rule::new(
    @ast.Literal::new("reach", [@ast.Var("X"), @ast.Var("Y")], false),
    [
      @ast.Literal::new(edges.name, [@ast.Var("X"), @ast.Var("Z")], false),
      @ast.Literal::new("reach", [@ast.Var("Z"), @ast.Var("Y")], false),
    ],
  )
  ignore(prog.add_rule(rule1))
  ignore(prog.add_rule(rule2))

  match @engine.eval_program_semi_naive(prog) {
    Some(db) =>
      match db.get("reach") {
        Some(reach_rel) =>
          reach_rel.contains(
            @core.Tuple::new([
              @core.Value::from_int(from_node),
              @core.Value::from_int(to_node),
            ]),
          )
        None => false
      }
    None => false
  }
}

///|
pub fn connected_components(edges : @core.Relation) -> @core.Relation {
  let prog = @ast.Program::new()
  prog.add_relation(edges)

  // undir(X, Y) :- edge(X, Y).
  // undir(X, Y) :- edge(Y, X).
  // comp(X, Y) :- undir(X, Y).
  // comp(X, Y) :- undir(X, Z), comp(Z, Y).
  ignore(
    prog.add_rule(
      @ast.Rule::new(
        @ast.Literal::new("undir", [@ast.Var("X"), @ast.Var("Y")], false),
        [@ast.Literal::new(edges.name, [@ast.Var("X"), @ast.Var("Y")], false)],
      ),
    ),
  )
  ignore(
    prog.add_rule(
      @ast.Rule::new(
        @ast.Literal::new("undir", [@ast.Var("X"), @ast.Var("Y")], false),
        [@ast.Literal::new(edges.name, [@ast.Var("Y"), @ast.Var("X")], false)],
      ),
    ),
  )
  ignore(
    prog.add_rule(
      @ast.Rule::new(
        @ast.Literal::new("comp", [@ast.Var("X"), @ast.Var("Y")], false),
        [@ast.Literal::new("undir", [@ast.Var("X"), @ast.Var("Y")], false)],
      ),
    ),
  )
  ignore(
    prog.add_rule(
      @ast.Rule::new(
        @ast.Literal::new("comp", [@ast.Var("X"), @ast.Var("Y")], false),
        [
          @ast.Literal::new("undir", [@ast.Var("X"), @ast.Var("Z")], false),
          @ast.Literal::new("comp", [@ast.Var("Z"), @ast.Var("Y")], false),
        ],
      ),
    ),
  )

  match @engine.eval_program_semi_naive(prog) {
    Some(db) =>
      match db.get("comp") {
        Some(r) => r
        None => @core.Relation::new("comp", ["node1", "node2"])
      }
    None => @core.Relation::new("comp", ["node1", "node2"])
  }
}

///|
pub fn has_cycle(edges : @core.Relation) -> Bool {
  let prog = @ast.Program::new()
  prog.add_relation(edges)

  let rule1 = @ast.Rule::new(
    @ast.Literal::new("reach", [@ast.Var("X"), @ast.Var("Y")], false),
    [@ast.Literal::new(edges.name, [@ast.Var("X"), @ast.Var("Y")], false)],
  )
  let rule2 = @ast.Rule::new(
    @ast.Literal::new("reach", [@ast.Var("X"), @ast.Var("Y")], false),
    [
      @ast.Literal::new(edges.name, [@ast.Var("X"), @ast.Var("Z")], false),
      @ast.Literal::new("reach", [@ast.Var("Z"), @ast.Var("Y")], false),
    ],
  )
  ignore(prog.add_rule(rule1))
  ignore(prog.add_rule(rule2))

  match @engine.eval_program_semi_naive(prog) {
    Some(db) =>
      match db.get("reach") {
        Some(reach_rel) => {
          for i = 0; i < reach_rel.tuples.length(); i = i + 1 {
            let t = reach_rel.tuples[i]
            if t.get(0) == t.get(1) {
              return true
            }
          }
          false
        }
        None => false
      }
    None => false
  }
}
