///|
pub(all) struct PolicyEngine {
  prog : @ast.Program
  roles : @core.Relation
  permissions : @core.Relation
  admins : @core.Relation
  blocked : @core.Relation
}

///|
pub fn PolicyEngine::new() -> PolicyEngine {
  let prog = @ast.Program::new()
  let roles = @core.Relation::new("role", ["user", "role"])
  let permissions = @core.Relation::new(
    "permission",
    ["role", "resource", "action"],
  )
  let admins = @core.Relation::new("admin", ["user"])
  let blocked = @core.Relation::new("blocked", ["user"])

  prog.add_relation(roles)
  prog.add_relation(permissions)
  prog.add_relation(admins)
  prog.add_relation(blocked)

  // allow(U, Res, Act) :- role(U, R), permission(R, Res, Act).
  ignore(
    prog.add_rule(
      @ast.Rule::new(
        @ast.Literal::new(
          "allow",
          [@ast.Var("U"), @ast.Var("Res"), @ast.Var("Act")],
          false,
        ),
        [
          @ast.Literal::new(
            "role",
            [@ast.Var("U"), @ast.Var("R")],
            false,
          ),
          @ast.Literal::new(
            "permission",
            [@ast.Var("R"), @ast.Var("Res"), @ast.Var("Act")],
            false,
          ),
        ],
      ),
    ),
  )

  // allow(U, Res, Act) :- admin(U), permission(R, Res, Act).
  ignore(
    prog.add_rule(
      @ast.Rule::new(
        @ast.Literal::new(
          "allow",
          [@ast.Var("U"), @ast.Var("Res"), @ast.Var("Act")],
          false,
        ),
        [
          @ast.Literal::new("admin", [@ast.Var("U")], false),
          @ast.Literal::new(
            "permission",
            [@ast.Var("R"), @ast.Var("Res"), @ast.Var("Act")],
            false,
          ),
        ],
      ),
    ),
  )

  // deny(U, Res, Act) :- blocked(U), allow(U, Res, Act).
  ignore(
    prog.add_rule(
      @ast.Rule::new(
        @ast.Literal::new(
          "deny",
          [@ast.Var("U"), @ast.Var("Res"), @ast.Var("Act")],
          false,
        ),
        [
          @ast.Literal::new("blocked", [@ast.Var("U")], false),
          @ast.Literal::new(
            "allow",
            [@ast.Var("U"), @ast.Var("Res"), @ast.Var("Act")],
            false,
          ),
        ],
      ),
    ),
  )

  // authorized(U, Res, Act) :- allow(U, Res, Act), !deny(U, Res, Act).
  ignore(
    prog.add_rule(
      @ast.Rule::new(
        @ast.Literal::new(
          "authorized",
          [@ast.Var("U"), @ast.Var("Res"), @ast.Var("Act")],
          false,
        ),
        [
          @ast.Literal::new(
            "allow",
            [@ast.Var("U"), @ast.Var("Res"), @ast.Var("Act")],
            false,
          ),
          @ast.Literal::new(
            "deny",
            [@ast.Var("U"), @ast.Var("Res"), @ast.Var("Act")],
            true,
          ),
        ],
      ),
    ),
  )

  { prog, roles, permissions, admins, blocked }
}

///|
pub fn PolicyEngine::add_role(
  self : PolicyEngine,
  user : String,
  role : String
) -> Unit {
  ignore(
    self.roles.insert(
      @core.Tuple::new([
        @core.Value::from_str(user),
        @core.Value::from_str(role),
      ]),
    ),
  )
}

///|
pub fn PolicyEngine::add_permission(
  self : PolicyEngine,
  role : String,
  res : String,
  act : String
) -> Unit {
  ignore(
    self.permissions.insert(
      @core.Tuple::new([
        @core.Value::from_str(role),
        @core.Value::from_str(res),
        @core.Value::from_str(act),
      ]),
    ),
  )
}

///|
pub fn PolicyEngine::add_admin(self : PolicyEngine, user : String) -> Unit {
  ignore(
    self.admins.insert(@core.Tuple::new([@core.Value::from_str(user)])),
  )
}

///|
pub fn PolicyEngine::block_user(self : PolicyEngine, user : String) -> Unit {
  ignore(
    self.blocked.insert(@core.Tuple::new([@core.Value::from_str(user)])),
  )
}

///|
pub fn PolicyEngine::check_access(
  self : PolicyEngine,
  user : String,
  res : String,
  act : String
) -> Bool {
  match @engine.eval_program_semi_naive(self.prog) {
    Some(db) =>
      match db.get("authorized") {
        Some(auth_rel) =>
          auth_rel.contains(
            @core.Tuple::new([
              @core.Value::from_str(user),
              @core.Value::from_str(res),
              @core.Value::from_str(act),
            ]),
          )
        None => false
      }
    None => false
  }
}
