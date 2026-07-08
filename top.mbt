///|
pub fn parse_and_eval(
  input : String
) -> Result[Map[String, @core.Relation], String] {
  match @parser.parse_program(input) {
    Ok(prog) =>
      match @engine.eval_program_semi_naive(prog) {
        Some(db) => Ok(db)
        None =>
          Err("Evaluation failed: unstratifiable program or negative cycle")
      }
    Err(msg) => Err(msg)
  }
}

///|
pub fn explain_query_plan(input : String) -> Result[String, String] {
  match @parser.parse_program(input) {
    Ok(prog) => Ok(@parser.explain_strata(prog))
    Err(msg) => Err(msg)
  }
}

///|
pub fn new_policy_engine() -> @policy.PolicyEngine {
  @policy.PolicyEngine::new()
}

///|
pub fn query_reachability(
  edges : @core.Relation,
  from_id : Int64,
  to_id : Int64
) -> Bool {
  @graph.reachable(edges, from_id, to_id)
}
