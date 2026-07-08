///|
test "rbac and admin authorization check" {
  let engine = PolicyEngine::new()
  engine.add_role("alice", "developer")
  engine.add_role("bob", "guest")
  engine.add_admin("charlie")

  engine.add_permission("developer", "repo", "push")
  engine.add_permission("developer", "repo", "pull")
  engine.add_permission("guest", "repo", "pull")

  assert_eq(engine.check_access("alice", "repo", "push"), true)
  assert_eq(engine.check_access("alice", "repo", "pull"), true)
  assert_eq(engine.check_access("bob", "repo", "push"), false)
  assert_eq(engine.check_access("bob", "repo", "pull"), true)

  // Admin can do any permission defined
  assert_eq(engine.check_access("charlie", "repo", "push"), true)
  assert_eq(engine.check_access("charlie", "repo", "delete"), false) // not defined in permissions

  // Block alice!
  engine.block_user("alice")
  assert_eq(engine.check_access("alice", "repo", "push"), false)
}
