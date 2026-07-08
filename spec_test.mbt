///|
test "formal specification: fixpoint invariance" {
  let input =
    #|edge(1, 2).
    #|edge(2, 3).
    #|edge(3, 4).
    #|reach(X, Y) :- edge(X, Y).
    #|reach(X, Y) :- edge(X, Z), reach(Z, Y).
  let prog = match @parser.parse_program(input) {
    Ok(p) => p
    Err(msg) => abort("Parse failed: " + msg)
  }
  let db = match @engine.eval_program_semi_naive(prog) {
    Some(res) => res
    None => abort("Eval failed")
  }

  // Verify fixpoint invariance!
  assert_eq(verify_fixpoint_invariance(prog, db), true)

  // Verify deduplication!
  let reach_rel = match db.get("reach") {
    Some(r) => r
    None => abort("reach missing")
  }
  assert_eq(verify_relation_deduplication(reach_rel), true)
}

///|
test "top level facade evaluation" {
  let input =
    #|parent("Alice", "Bob").
    #|parent("Bob", "Charlie").
    #|ancestor(X, Y) :- parent(X, Y).
    #|ancestor(X, Y) :- parent(X, Z), ancestor(Z, Y).
  let res = match parse_and_eval(input) {
    Ok(db) => db
    Err(msg) => abort("eval failed: " + msg)
  }
  let anc = match res.get("ancestor") {
    Some(r) => r
    None => abort("ancestor missing")
  }
  assert_eq(anc.len(), 3) // (Alice, Bob), (Bob, Charlie), (Alice, Charlie)
  assert_eq(anc.contains(@core.Tuple::new([@core.Value::from_str("Alice"), @core.Value::from_str("Charlie")])), true)
}
