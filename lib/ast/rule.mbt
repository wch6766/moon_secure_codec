///|
pub(all) struct Rule {
  head : Literal
  body : Array[Literal]
} derive(Eq, Compare, Hash, Debug)

///|
pub fn Rule::new(head : Literal, body : Array[Literal]) -> Rule {
  { head, body }
}

///|
pub fn Rule::is_safe(self : Rule) -> Bool {
  if self.head.is_negative {
    return false
  }
  let pos_vars : Map[String, Bool] = {}
  for i = 0; i < self.body.length(); i = i + 1 {
    let lit = self.body[i]
    if lit.is_negative == false {
      for j = 0; j < lit.terms.length(); j = j + 1 {
        match lit.terms[j] {
          Var(name) => pos_vars.set(name, true)
          Const(_) => ()
        }
      }
    }
  }

  // Check head vars
  for i = 0; i < self.head.terms.length(); i = i + 1 {
    match self.head.terms[i] {
      Var(name) =>
        if pos_vars.contains(name) == false {
          return false
        }
      Const(_) => ()
    }
  }

  // Check negative literal vars
  for i = 0; i < self.body.length(); i = i + 1 {
    let lit = self.body[i]
    if lit.is_negative {
      for j = 0; j < lit.terms.length(); j = j + 1 {
        match lit.terms[j] {
          Var(name) =>
            if pos_vars.contains(name) == false {
              return false
            }
          Const(_) => ()
        }
      }
    }
  }

  true
}

///|
pub impl Show for Rule with output(self, logger) {
  logger.write_string(self.head.to_string())
  if self.body.length() > 0 {
    logger.write_string(" :- ")
    for i = 0; i < self.body.length(); i = i + 1 {
      if i > 0 {
        logger.write_string(", ")
      }
      logger.write_string(self.body[i].to_string())
    }
  }
  logger.write_char('.')
}
