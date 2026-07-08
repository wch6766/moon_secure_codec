///|
fn main {
  println("==================================================================")
  println("  MoonDatalog Benchmark: Naive vs. Semi-Naive Fixpoint Evaluation ")
  println("==================================================================")
  
  let prog = @ast.Program::new()
  let edges = @core.Relation::new("edge", ["from", "to"])
  let num_nodes : Int64 = 50L
  for i = 1L; i < num_nodes; i = i + 1L {
    ignore(
      edges.insert(
        @core.Tuple::new([
          @core.Value::from_int(i),
          @core.Value::from_int(i + 1L),
        ]),
      ),
    )
  }
  prog.add_relation(edges)

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

  println(
    "--> Graph Setup: Linear chain of " +
    num_nodes.to_string() +
    " nodes (" +
    (num_nodes - 1L).to_string() +
    " edges).",
  )
  println(
    "--> Expected reachability pairs: " +
    (num_nodes * (num_nodes - 1L) / 2L).to_string(),
  )
  println("")

  println("Running Semi-Naive Evaluation...")
  match @engine.eval_program_semi_naive(prog) {
    Some(db_semi) =>
      match db_semi.get("reach") {
        Some(rel_semi) => {
          println(
            "  [Semi-Naive] Discovered tuples: " + rel_semi.len().to_string(),
          )
          println("Running Naive Evaluation...")
          match @engine.eval_program_naive(prog) {
            Some(db_naive) =>
              match db_naive.get("reach") {
                Some(rel_naive) => {
                  println(
                    "  [Naive]      Discovered tuples: " +
                    rel_naive.len().to_string(),
                  )
                  if rel_semi.len() == rel_naive.len() {
                    println(
                      "  [VERIFIED] Both evaluation strategies yielded identical exact results!",
                    )
                  } else {
                    println("  [ERROR] Mismatch between Naive and Semi-Naive!")
                  }
                }
                None => println("Error: reach missing in naive")
              }
            None => println("Error: naive eval failed")
          }
        }
        None => println("Error: reach missing in semi-naive")
      }
    None => println("Error: semi-naive eval failed")
  }
  println("==================================================================")
}
