///|
pub(all) struct Parser {
  tokens : Array[Token]
  mut pos : Int
}

///|
pub fn Parser::new(input : String) -> Parser {
  { tokens: lex(input), pos: 0 }
}

///|
fn Parser::peek(self : Parser) -> Token {
  if self.pos < self.tokens.length() {
    self.tokens[self.pos]
  } else {
    EOF
  }
}

///|
fn Parser::advance(self : Parser) -> Token {
  let t = self.peek()
  if self.pos < self.tokens.length() {
    self.pos = self.pos + 1
  }
  t
}

///|
fn Parser::expect(self : Parser, expected : Token) -> Bool {
  if self.peek() == expected {
    ignore(self.advance())
    true
  } else {
    false
  }
}

///|
fn make_schema(arity : Int) -> Array[String] {
  let schema : Array[String] = []
  for i = 0; i < arity; i = i + 1 {
    schema.push("col" + i.to_string())
  }
  schema
}

///|
pub fn Parser::parse_term(self : Parser) -> @ast.Term? {
  match self.advance() {
    TVar(name) => Some(@ast.Var(name))
    TIdent(name) => Some(@ast.Const(@core.Value::from_str(name))) // Lowercase constant symbol or string
    TStr(s) => Some(@ast.Const(@core.Value::from_str(s)))
    TInt(i) => Some(@ast.Const(@core.Value::from_int(i)))
    _ => None
  }
}

///|
pub fn Parser::parse_literal(self : Parser) -> @ast.Literal? {
  let mut is_neg = false
  if self.peek() == TNot {
    ignore(self.advance())
    is_neg = true
  }

  let rel_name = match self.advance() {
    TIdent(name) => name
    _ => return None
  }

  if self.expect(TLParen) == false {
    return None
  }

  let terms : Array[@ast.Term] = []
  if self.peek() != TRParen {
    while true {
      match self.parse_term() {
        Some(t) => terms.push(t)
        None => return None
      }
      if self.peek() == TComma {
        ignore(self.advance())
      } else {
        break
      }
    }
  }

  if self.expect(TRParen) == false {
    return None
  }

  Some(@ast.Literal::new(rel_name, terms, is_neg))
}

///|
pub fn parse_program(input : String) -> Result[@ast.Program, String] {
  let parser = Parser::new(input)
  let prog = @ast.Program::new()

  while parser.peek() != EOF {
    let lit_opt = parser.parse_literal()
    let lit = match lit_opt {
      Some(l) => l
      None =>
        return Err("Syntax error parsing literal at token index " + parser.pos.to_string())
    }

    if parser.peek() == TDot {
      // EDB Fact!
      ignore(parser.advance())
      if lit.is_negative {
        return Err("Fact cannot be negative: " + lit.to_string())
      }
      let vals : Array[@core.Value] = []
      for i = 0; i < lit.terms.length(); i = i + 1 {
        match lit.terms[i] {
          Const(c) => vals.push(c)
          Var(name) => return Err("Fact cannot contain variables: " + name)
        }
      }
      let tuple = @core.Tuple::new(vals)
      let rel = match prog.get_relation(lit.rel_name) {
        Some(r) => r
        None => {
          let r = @core.Relation::new(lit.rel_name, make_schema(lit.arity()))
          prog.add_relation(r)
          r
        }
      }
      ignore(rel.insert(tuple))
    } else if parser.peek() == TImplies {
      // Rule!
      ignore(parser.advance())
      let body : Array[@ast.Literal] = []
      while true {
        match parser.parse_literal() {
          Some(body_lit) => body.push(body_lit)
          None => return Err("Syntax error parsing rule body")
        }
        if parser.peek() == TComma {
          ignore(parser.advance())
        } else {
          break
        }
      }
      if parser.expect(TDot) == false {
        return Err("Expected '.' at end of rule")
      }
      let rule = @ast.Rule::new(lit, body)
      if prog.add_rule(rule) == false {
        return Err("Unsafe rule rejected: " + rule.to_string())
      }
    } else {
      return Err("Expected '.' or ':-' after literal: " + lit.to_string())
    }
  }

  Ok(prog)
}

///|
pub fn explain_strata(prog : @ast.Program) -> String {
  match prog.stratify() {
    None => "EXPLAIN: Unstratifiable program (Negative cycle detected!)\n"
    Some(strata) => {
      let mut out = "EXPLAIN QUERY PLAN (IDB Stratification Report):\n"
      for s = 0; s < strata.length(); s = s + 1 {
        out = out + "--- Stratum " + s.to_string() + " ---\n"
        for r = 0; r < strata[s].length(); r = r + 1 {
          out = out + "  " + strata[s][r].to_string() + "\n"
        }
      }
      out
    }
  }
}
