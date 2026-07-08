///|
test "literal unification and substitution" {
  let lit = Literal::new("edge", [Var("X"), Const(@core.Value::from_int(2)), Var("Y")], false)
  let tuple = @core.Tuple::new([@core.Value::from_int(1), @core.Value::from_int(2), @core.Value::from_int(3)])
  let env = BindingEnv::new()
  assert_eq(unify_literal(lit, tuple, env), true)
  assert_eq(env.get("X") == Some(@core.Value::from_int(1)), true)
  assert_eq(env.get("Y") == Some(@core.Value::from_int(3)), true)

  let head = Literal::new("path", [Var("X"), Var("Y")], false)
  let head_tuple = eval_head_tuple(head, env)
  assert_eq(head_tuple == Some(@core.Tuple::new([@core.Value::from_int(1), @core.Value::from_int(3)])), true)
}

///|
test "rule safety verification" {
  // Safe: path(X, Y) :- edge(X, Z), path(Z, Y).
  let safe_rule = Rule::new(
    Literal::new("path", [Var("X"), Var("Y")], false),
    [
      Literal::new("edge", [Var("X"), Var("Z")], false),
      Literal::new("path", [Var("Z"), Var("Y")], false),
    ],
  )
  assert_eq(safe_rule.is_safe(), true)

  // Unsafe: unsafe(X) :- edge(Y, Z). (X not in positive body)
  let unsafe_rule = Rule::new(
    Literal::new("unsafe", [Var("X")], false),
    [Literal::new("edge", [Var("Y"), Var("Z")], false)],
  )
  assert_eq(unsafe_rule.is_safe(), false)
}

///|
test "stratification and negative cycle detection" {
  let prog = Program::new()
  // reach(X, Y) :- edge(X, Y).
  // reach(X, Y) :- edge(X, Z), reach(Z, Y).
  // not_reach(X, Y) :- node(X), node(Y), !reach(X, Y).
  ignore(
    prog.add_rule(
      Rule::new(
        Literal::new("reach", [Var("X"), Var("Y")], false),
        [Literal::new("edge", [Var("X"), Var("Y")], false)],
      ),
    ),
  )
  ignore(
    prog.add_rule(
      Rule::new(
        Literal::new("reach", [Var("X"), Var("Y")], false),
        [
          Literal::new("edge", [Var("X"), Var("Z")], false),
          Literal::new("reach", [Var("Z"), Var("Y")], false),
        ],
      ),
    ),
  )
  ignore(
    prog.add_rule(
      Rule::new(
        Literal::new("not_reach", [Var("X"), Var("Y")], false),
        [
          Literal::new("node", [Var("X")], false),
          Literal::new("node", [Var("Y")], false),
          Literal::new("reach", [Var("X"), Var("Y")], true),
        ],
      ),
    ),
  )

  let strata_opt = prog.stratify()
  assert_eq(strata_opt == None, false)
  match strata_opt {
    Some(strata) => {
      assert_eq(strata.length(), 2) // Stratum 0: reach, Stratum 1: not_reach
    }
    None => ()
  }
}

///|
test "unstratifiable program negative cycle" {
  let prog = Program::new()
  // p(X) :- q(X), !r(X).
  // r(X) :- p(X).
  ignore(
    prog.add_rule(
      Rule::new(
        Literal::new("p", [Var("X")], false),
        [
          Literal::new("q", [Var("X")], false),
          Literal::new("r", [Var("X")], true),
        ],
      ),
    ),
  )
  ignore(
    prog.add_rule(
      Rule::new(
        Literal::new("r", [Var("X")], false),
        [Literal::new("p", [Var("X")], false)],
      ),
    ),
  )
  assert_eq(prog.stratify() == None, true)
}
