///|
pub(all) enum Value {
  VInt(Int64)
  VFloat(Double)
  VStr(String)
  VBool(Bool)
} derive(Eq, Compare, Hash, Debug)

///|
pub impl Show for Value with output(self, logger) {
  match self {
    VInt(i) => logger.write_string(i.to_string())
    VFloat(f) => logger.write_string(f.to_string())
    VStr(s) => {
      logger.write_char('"')
      logger.write_string(s)
      logger.write_char('"')
    }
    VBool(b) => logger.write_string(b.to_string())
  }
}

///|
pub fn Value::to_string(self : Value) -> String {
  match self {
    VInt(i) => i.to_string()
    VFloat(f) => f.to_string()
    VStr(s) => s
    VBool(b) => b.to_string()
  }
}

///|
pub fn Value::from_int(i : Int64) -> Value {
  VInt(i)
}

///|
pub fn Value::from_str(s : String) -> Value {
  VStr(s)
}

///|
pub fn Value::from_bool(b : Bool) -> Value {
  VBool(b)
}
