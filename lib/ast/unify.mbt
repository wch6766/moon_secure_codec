///|
pub(all) struct BindingEnv {
  bindings : Map[String, @core.Value]
} derive(Eq, Debug)

///|
pub fn BindingEnv::new() -> BindingEnv {
  { bindings: {} }
}

///|
pub fn BindingEnv::get(self : BindingEnv, var_name : String) -> @core.Value? {
  self.bindings.get(var_name)
}

///|
pub fn BindingEnv::set(self : BindingEnv, var_name : String, val : @core.Value) -> Unit {
  self.bindings.set(var_name, val)
}

///|
pub fn BindingEnv::clone(self : BindingEnv) -> BindingEnv {
  let res = BindingEnv::new()
  self.bindings.each(fn(k, v) { res.set(k, v) })
  res
}

///|
pub fn unify_literal(
  lit : Literal,
  tuple : @core.Tuple,
  env : BindingEnv
) -> Bool {
  if lit.arity() != tuple.arity() {
    return false
  }
  for i = 0; i < lit.terms.length(); i = i + 1 {
    match lit.terms[i] {
      Const(c) =>
        match tuple.get(i) {
          Some(v) => if c != v { return false }
          None => return false
        }
      Var(name) =>
        match tuple.get(i) {
          Some(v) =>
            match env.get(name) {
              Some(bound_val) => if bound_val != v { return false }
              None => env.set(name, v)
            }
          None => return false
        }
    }
  }
  true
}

///|
pub fn substitute_literal(lit : Literal, env : BindingEnv) -> Literal {
  let new_terms : Array[Term] = []
  for i = 0; i < lit.terms.length(); i = i + 1 {
    match lit.terms[i] {
      Const(c) => new_terms.push(Const(c))
      Var(name) =>
        match env.get(name) {
          Some(v) => new_terms.push(Const(v))
          None => new_terms.push(Var(name))
        }
    }
  }
  Literal::new(lit.rel_name, new_terms, lit.is_negative)
}

///|
pub fn eval_head_tuple(head : Literal, env : BindingEnv) -> @core.Tuple? {
  let vals : Array[@core.Value] = []
  for i = 0; i < head.terms.length(); i = i + 1 {
    match head.terms[i] {
      Const(c) => vals.push(c)
      Var(name) =>
        match env.get(name) {
          Some(v) => vals.push(v)
          None => return None // Unbound head variable!
        }
    }
  }
  Some(@core.Tuple::new(vals))
}
