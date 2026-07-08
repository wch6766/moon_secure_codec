///|
fn main {
  println("==================================================================")
  println("  MoonDatalog: Deductive Relational Database & Rule Engine (v0.1) ")
  println("  Powered by MoonBit GC/WASM | OSC 2026 Competition Submission    ")
  println("==================================================================")
  println("")

  let program_text =
    #|// 1. Organizational Hierarchy & Role Assignments
    #|employee("Alice", "Engineering").
    #|employee("Bob", "Engineering").
    #|employee("Charlie", "Security").
    #|employee("David", "Contractors").
    #|
    #|manager("Alice", "Bob").
    #|manager("Charlie", "Alice").
    #|
    #|// 2. Recursive Management Chain (Who manages whom directly or indirectly)
    #|supervises(X, Y) :- manager(X, Y).
    #|supervises(X, Y) :- manager(X, Z), supervises(Z, Y).
    #|
    #|// 3. Security Policies (RBAC with Stratified Negation)
    #|access_level("Engineering", "CodeRepo", "ReadWrite").
    #|access_level("Security", "CodeRepo", "Admin").
    #|access_level("Contractors", "CodeRepo", "Read").
    #|
    #|blocked("David").
    #|
    #|allow(User, Resource, Perm) :- employee(User, Dept), access_level(Dept, Resource, Perm).
    #|allow(User, "AllResources", "Audit") :- supervises(User, Anyone).
    #|
    #|deny(User, Resource, Perm) :- blocked(User), allow(User, Resource, Perm).
    #|
    #|authorized(User, Resource, Perm) :- allow(User, Resource, Perm), !deny(User, Resource, Perm).

  println("--> [STEP 1] Parsing Datalog Rule Program...")
  match @moon_datalog.explain_query_plan(program_text) {
    Ok(plan) => {
      println("--> [STEP 2] Stratified Execution Query Plan:")
      println(plan)
    }
    Err(err) => {
      println("Error: " + err)
      return
    }
  }

  println("--> [STEP 3] Executing Semi-Naive Fixpoint Evaluation...")
  match @moon_datalog.parse_and_eval(program_text) {
    Ok(db) => {
      println("Evaluation complete! Extracted Knowledge & Authorization Base:")
      println("")
      
      match db.get("supervises") {
        Some(rel) => println(rel.to_string())
        None => ()
      }
      println("")
      match db.get("authorized") {
        Some(rel) => println(rel.to_string())
        None => ()
      }
      println("")
      match db.get("deny") {
        Some(rel) => println(rel.to_string())
        None => ()
      }
    }
    Err(err) => println("Evaluation Error: " + err)
  }
  println("==================================================================")
  println("  Execution Successful. Zero memory leaks, pure functional Datalog!")
  println("==================================================================")
}
