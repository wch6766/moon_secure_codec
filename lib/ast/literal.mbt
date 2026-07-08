///|
pub(all) struct Literal {
  rel_name : String
  terms : Array[Term]
  is_negative : Bool
} derive(Eq, Compare, Hash, Debug)

///|
pub fn Literal::new(
  rel_name : String,
  terms : Array[Term],
  is_negative : Bool
) -> Literal {
  { rel_name, terms, is_negative }
}

///|
pub fn Literal::arity(self : Literal) -> Int {
  self.terms.length()
}

///|
pub impl Show for Literal with output(self, logger) {
  if self.is_negative {
    logger.write_char('!')
  }
  logger.write_string(self.rel_name)
  logger.write_char('(')
  for i = 0; i < self.terms.length(); i = i + 1 {
    if i > 0 {
      logger.write_string(", ")
    }
    logger.write_string(self.terms[i].to_string())
  }
  logger.write_char(')')
}
