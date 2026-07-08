///|
pub(all) enum Term {
  Var(String)
  Const(@core.Value)
} derive(Eq, Compare, Hash, Debug)

///|
pub impl Show for Term with output(self, logger) {
  match self {
    Var(name) => logger.write_string(name)
    Const(v) => logger.write_string(v.to_string())
  }
}

///|
pub fn Term::is_var(self : Term) -> Bool {
  match self {
    Var(_) => true
    Const(_) => false
  }
}
