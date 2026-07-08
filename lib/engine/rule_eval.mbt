///|
fn eval_body_lits(
  body : Array[@ast.Literal],
  idx : Int,
  env : @ast.BindingEnv,
  db : Map[String, @core.Relation],
  results : @core.Relation,
  head : @ast.Literal
) -> Unit {
  if idx == body.length() {
    match @ast.eval_head_tuple(head, env) {
      Some(tuple) => ignore(results.insert(tuple))
      None => ()
    }
    return
  }

  let lit = body[idx]
  let rel_opt = db.get(lit.rel_name)
  let rel = match rel_opt {
    Some(r) => r
    None =>
      @core.Relation::new(
        lit.rel_name,
        make_dummy_schema(lit.terms.length()),
      )
  }

  if lit.is_negative {
    // Negation as failure (NAF): check if any tuple satisfies the substituted literal
    let mut satisfied = false
    for i = 0; i < rel.tuples.length(); i = i + 1 {
      let t = rel.tuples[i]
      let env_try = env.clone()
      if @ast.unify_literal(lit, t, env_try) {
        satisfied = true
        break
      }
    }
    if satisfied == false {
      eval_body_lits(body, idx + 1, env, db, results, head)
    }
  } else {
    // Positive literal: iterate over matching tuples
    for i = 0; i < rel.tuples.length(); i = i + 1 {
      let t = rel.tuples[i]
      let env_next = env.clone()
      if @ast.unify_literal(lit, t, env_next) {
        eval_body_lits(body, idx + 1, env_next, db, results, head)
      }
    }
  }
}

///|
fn make_dummy_schema(arity : Int) -> Array[String] {
  let schema : Array[String] = []
  for i = 0; i < arity; i = i + 1 {
    schema.push("c" + i.to_string())
  }
  schema
}

///|
pub fn eval_rule(
  rule : @ast.Rule,
  db : Map[String, @core.Relation]
) -> @core.Relation {
  let head_schema = match db.get(rule.head.rel_name) {
    Some(r) => r.schema
    None => make_dummy_schema(rule.head.terms.length())
  }
  let results = @core.Relation::new(rule.head.rel_name, head_schema)
  let initial_env = @ast.BindingEnv::new()
  eval_body_lits(rule.body, 0, initial_env, db, results, rule.head)
  results
}

///|
pub fn eval_rule_differentiated(
  rule : @ast.Rule,
  accum_db : Map[String, @core.Relation],
  delta_db : Map[String, @core.Relation],
  idb_set : Map[String, Bool]
) -> @core.Relation {
  let head_schema = match accum_db.get(rule.head.rel_name) {
    Some(r) => r.schema
    None => make_dummy_schema(rule.head.terms.length())
  }
  let total_results = @core.Relation::new(rule.head.rel_name, head_schema)

  // Count positive IDB literals in body
  let pos_idb_indices : Array[Int] = []
  for i = 0; i < rule.body.length(); i = i + 1 {
    let lit = rule.body[i]
    if lit.is_negative == false && idb_set.contains(lit.rel_name) {
      pos_idb_indices.push(i)
    }
  }

  if pos_idb_indices.length() == 0 {
    // No positive IDB literals: rule only depends on EDBs or non-recursive facts, evaluate directly against accum_db
    return eval_rule(rule, accum_db)
  }

  // For each positive IDB literal at index `delta_idx`, evaluate rule where:
  // body[delta_idx] comes from delta_db,
  // body[other < delta_idx] comes from accum_db,
  // body[other > delta_idx] comes from accum_db (or delta_db+accum_db depending on differentiation strategy).
  for idx_i = 0; idx_i < pos_idb_indices.length(); idx_i = idx_i + 1 {
    let delta_idx = pos_idb_indices[idx_i]
    let hybrid_db : Map[String, @core.Relation] = {}
    accum_db.each(fn(k, v) { hybrid_db.set(k, v) })

    // Replace the relation of body[delta_idx] with its delta relation exactly for this literal step!
    // To support multiple literals referencing the exact same table name with different delta vs accum,
    // we do a modified body literal evaluation:
    eval_body_lits_hybrid(
      rule.body,
      0,
      @ast.BindingEnv::new(),
      accum_db,
      delta_db,
      delta_idx,
      total_results,
      rule.head,
    )
  }

  total_results
}

///|
fn eval_body_lits_hybrid(
  body : Array[@ast.Literal],
  idx : Int,
  env : @ast.BindingEnv,
  accum_db : Map[String, @core.Relation],
  delta_db : Map[String, @core.Relation],
  delta_pos : Int,
  results : @core.Relation,
  head : @ast.Literal
) -> Unit {
  if idx == body.length() {
    match @ast.eval_head_tuple(head, env) {
      Some(tuple) => ignore(results.insert(tuple))
      None => ()
    }
    return
  }

  let lit = body[idx]
  let db_to_use = if idx == delta_pos { delta_db } else { accum_db }
  let rel_opt = db_to_use.get(lit.rel_name)
  let rel = match rel_opt {
    Some(r) => r
    None =>
      @core.Relation::new(
        lit.rel_name,
        make_dummy_schema(lit.terms.length()),
      )
  }

  if lit.is_negative {
    // Negations always check against accum_db (complete state of lower/current strata)
    let neg_rel = match accum_db.get(lit.rel_name) {
      Some(r) => r
      None =>
        @core.Relation::new(
          lit.rel_name,
          make_dummy_schema(lit.terms.length()),
        )
    }
    let mut satisfied = false
    for i = 0; i < neg_rel.tuples.length(); i = i + 1 {
      let t = neg_rel.tuples[i]
      let env_try = env.clone()
      if @ast.unify_literal(lit, t, env_try) {
        satisfied = true
        break
      }
    }
    if satisfied == false {
      eval_body_lits_hybrid(
        body,
        idx + 1,
        env,
        accum_db,
        delta_db,
        delta_pos,
        results,
        head,
      )
    }
  } else {
    for i = 0; i < rel.tuples.length(); i = i + 1 {
      let t = rel.tuples[i]
      let env_next = env.clone()
      if @ast.unify_literal(lit, t, env_next) {
        eval_body_lits_hybrid(
          body,
          idx + 1,
          env_next,
          accum_db,
          delta_db,
          delta_pos,
          results,
          head,
        )
      }
    }
  }
}
