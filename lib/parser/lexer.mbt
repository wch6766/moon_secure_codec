///|
pub(all) enum Token {
  TIdent(String) // lowercase start
  TVar(String) // uppercase start
  TInt(Int64)
  TStr(String)
  TImplies // :-
  TComma // ,
  TDot // .
  TLParen // (
  TRParen // )
  TNot // !
  EOF
} derive(Eq, Debug)

///|
fn parse_int64_str(s : String) -> Int64 {
  let chars = s.to_array()
  let mut val : Int64 = 0L
  let mut start = 0
  let mut sign : Int64 = 1L
  if chars.length() > 0 && chars[0] == '-' {
    sign = -1L
    start = 1
  }
  for j = start; j < chars.length(); j = j + 1 {
    let digit = (chars[j].to_int() - '0'.to_int()).to_int64()
    val = val * 10L + digit
  }
  val * sign
}

///|
pub fn lex(input : String) -> Array[Token] {
  let chars = input.to_array()
  let len = chars.length()
  let mut i = 0
  let tokens : Array[Token] = []

  while i < len {
    let c = chars[i]
    if c == ' ' || c == '\t' || c == '\r' || c == '\n' {
      i = i + 1
      continue
    }

    // Comments // or %
    if c == '%' {
      while i < len && chars[i] != '\n' {
        i = i + 1
      }
      continue
    }
    if c == '/' && i + 1 < len && chars[i + 1] == '/' {
      while i < len && chars[i] != '\n' {
        i = i + 1
      }
      continue
    }

    if c == '(' {
      tokens.push(TLParen)
      i = i + 1
      continue
    }
    if c == ')' {
      tokens.push(TRParen)
      i = i + 1
      continue
    }
    if c == ',' {
      tokens.push(TComma)
      i = i + 1
      continue
    }
    if c == '.' {
      tokens.push(TDot)
      i = i + 1
      continue
    }
    if c == '!' {
      tokens.push(TNot)
      i = i + 1
      continue
    }
    if c == ':' && i + 1 < len && chars[i + 1] == '-' {
      tokens.push(TImplies)
      i = i + 2
      continue
    }

    // Strings
    if c == '"' {
      i = i + 1
      let mut s = ""
      while i < len && chars[i] != '"' {
        if chars[i] == '\\' && i + 1 < len {
          i = i + 1
          s = s + chars[i].to_string()
        } else {
          s = s + chars[i].to_string()
        }
        i = i + 1
      }
      if i < len && chars[i] == '"' {
        i = i + 1
      }
      tokens.push(TStr(s))
      continue
    }

    // Integers
    if (c >= '0' && c <= '9') ||
      (c == '-' && i + 1 < len && chars[i + 1] >= '0' && chars[i + 1] <= '9') {
      let mut s = ""
      if c == '-' {
        s = "-"
        i = i + 1
      }
      while i < len && chars[i] >= '0' && chars[i] <= '9' {
        s = s + chars[i].to_string()
        i = i + 1
      }
      let val = parse_int64_str(s)
      tokens.push(TInt(val))
      continue
    }

    // Identifiers or Variables
    if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' {
      let mut s = ""
      let is_var = c >= 'A' && c <= 'Z'
      while i < len &&
            ((chars[i] >= 'a' && chars[i] <= 'z') ||
            (chars[i] >= 'A' && chars[i] <= 'Z') ||
            (chars[i] >= '0' && chars[i] <= '9') ||
            chars[i] == '_') {
        s = s + chars[i].to_string()
        i = i + 1
      }
      if is_var {
        tokens.push(TVar(s))
      } else {
        tokens.push(TIdent(s))
      }
      continue
    }

    // Unrecognized char, skip
    i = i + 1
  }

  tokens.push(EOF)
  tokens
}
