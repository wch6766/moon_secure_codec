///|
test "lexing tokens and comments" {
  let input =
    #|// Edge declarations
    #|edge(1, 2).
    #|edge(2, -5).
    #|reach(X, Y) :- edge(X, Z), reach(Z, Y).
  let tokens = lex(input)
  assert_eq(tokens[0] == TIdent("edge"), true)
  assert_eq(tokens[1] == TLParen, true)
  assert_eq(tokens[2] == TInt(1L), true)
  assert_eq(tokens[3] == TComma, true)
  assert_eq(tokens[4] == TInt(2L), true)
  assert_eq(tokens[5] == TRParen, true)
  assert_eq(tokens[6] == TDot, true)
  assert_eq(tokens[7] == TIdent("edge"), true)
  assert_eq(tokens[8] == TLParen, true)
  assert_eq(tokens[9] == TInt(2L), true)
  assert_eq(tokens[10] == TComma, true)
  assert_eq(tokens[11] == TInt(-5L), true)
}

///|
test "parsing program and explain plan" {
  let input =
    #|edge(1, 2).
    #|edge(2, 3).
    #|reach(X, Y) :- edge(X, Y).
    #|reach(X, Y) :- edge(X, Z), reach(Z, Y).
    #|isolated(X) :- node(X), !reach(1, X).
  let prog = match parse_program(input) {
    Ok(p) => p
    Err(msg) => abort("Parse failed: " + msg)
  }
  assert_eq(prog.rules.length(), 3)
  
  let edge_rel = match prog.get_relation("edge") {
    Some(r) => r
    None => abort("edge relation not created")
  }
  assert_eq(edge_rel.len(), 2)

  let explain = explain_strata(prog)
  assert_eq(explain.contains("Stratum 0"), true)
  assert_eq(explain.contains("Stratum 1"), true)
}
