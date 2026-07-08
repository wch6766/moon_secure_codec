///|
pub(all) struct Relation {
  name : String
  schema : Array[String]
  col_indices : Map[String, Int]
  tuples : Array[Tuple]
  tuple_set : Map[Tuple, Bool]
}

///|
pub fn Relation::new(name : String, schema : Array[String]) -> Relation {
  let col_indices : Map[String, Int] = {}
  for i = 0; i < schema.length(); i = i + 1 {
    col_indices.set(schema[i], i)
  }
  {
    name,
    schema,
    col_indices,
    tuples: [],
    tuple_set: {},
  }
}

///|
pub fn Relation::arity(self : Relation) -> Int {
  self.schema.length()
}

///|
pub fn Relation::insert(self : Relation, tuple : Tuple) -> Bool {
  if tuple.arity() != self.arity() {
    return false
  }
  if self.tuple_set.contains(tuple) {
    return false
  }
  self.tuple_set.set(tuple, true)
  self.tuples.push(tuple)
  true
}

///|
pub fn Relation::contains(self : Relation, tuple : Tuple) -> Bool {
  self.tuple_set.contains(tuple)
}

///|
pub fn Relation::len(self : Relation) -> Int {
  self.tuples.length()
}

///|
pub fn Relation::is_empty(self : Relation) -> Bool {
  self.tuples.length() == 0
}

///|
pub fn Relation::get_col_idx(self : Relation, col_name : String) -> Int? {
  self.col_indices.get(col_name)
}

///|
pub fn Relation::clear(self : Relation) -> Unit {
  self.tuples.clear()
  self.tuple_set.clear()
}

///|
pub fn Relation::clone_empty(self : Relation) -> Relation {
  Relation::new(self.name, self.schema)
}

///|
pub fn Relation::clone(self : Relation) -> Relation {
  let res = Relation::new(self.name, self.schema)
  for i = 0; i < self.tuples.length(); i = i + 1 {
    ignore(res.insert(self.tuples[i]))
  }
  res
}

///|
pub impl Show for Relation with output(self, logger) {
  logger.write_string("Relation: ")
  logger.write_string(self.name)
  logger.write_string(" [")
  for i = 0; i < self.schema.length(); i = i + 1 {
    if i > 0 {
      logger.write_string(", ")
    }
    logger.write_string(self.schema[i])
  }
  logger.write_string("]\n")
  for i = 0; i < self.tuples.length(); i = i + 1 {
    logger.write_string("  ")
    logger.write_string(self.tuples[i].to_string())
    logger.write_char('\n')
  }
}
