///|
pub(all) struct Tuple {
  values : Array[Value]
} derive(Eq, Compare, Hash, Debug)

///|
pub fn Tuple::new(values : Array[Value]) -> Tuple {
  { values, }
}

///|
pub fn Tuple::arity(self : Tuple) -> Int {
  self.values.length()
}

///|
pub fn Tuple::get(self : Tuple, idx : Int) -> Value? {
  if idx >= 0 && idx < self.values.length() {
    Some(self.values[idx])
  } else {
    None
  }
}

///|
pub impl Show for Tuple with output(self, logger) {
  logger.write_char('(')
  for i = 0; i < self.values.length(); i = i + 1 {
    if i > 0 {
      logger.write_string(", ")
    }
    logger.write_string(self.values[i].to_string())
  }
  logger.write_char(')')
}
