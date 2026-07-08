///|
test "manifest_creation_and_integrity" {
  let f1 = FileSnapshot::from_bytes("src/main.mbt", b"fn main() { println(\"Hello\") }")
  let f2 = FileSnapshot::from_bytes("moon.pkg", b"import { \"moonbitlang/core/digest\" }")
  let manifest = Manifest::new("test_project", "v1.0.0", "2026-07-08T12:00:00Z", [f1, f2])

  assert_true(manifest.merkle_root.length() == 64)
  assert_true(manifest.verify_integrity())
}

///|
test "manifest_tamper_detection" {
  let f1 = FileSnapshot::from_bytes("src/utils.mbt", b"pub fn helper() -> Int { 42 }")
  let manifest = Manifest::new("app_core", "v0.1.0", "2026-07-08T12:00:00Z", [f1])
  assert_true(manifest.verify_integrity())

  // Tamper with file hash directly (simulating supply chain injection or corruption)
  manifest.files[0] = {
    path: f1.path,
    size: f1.size,
    hash_xx64: f1.hash_xx64,
    hash_sha256: "000000000000000000000000000000000000000000000000000000000000dead",
  }
  assert_false(manifest.verify_integrity())
}

///|
test "manifest_diff_audit" {
  let f_base = FileSnapshot::from_bytes("README.md", b"# MoonSecureCodec v1.0")
  let f_mod_old = FileSnapshot::from_bytes("src/lib.mbt", b"pub fn version() -> Int { 1 }")
  let f_rem = FileSnapshot::from_bytes("legacy.mbt", b"// old code")

  let old_manifest = Manifest::new("my_pkg", "v1.0.0", "2026-07-01", [f_base, f_mod_old, f_rem])

  let f_mod_new = FileSnapshot::from_bytes("src/lib.mbt", b"pub fn version() -> Int { 2 }")
  let f_added = FileSnapshot::from_bytes("SECURITY.md", b"# Security Policy")

  let new_manifest = Manifest::new("my_pkg", "v1.1.0", "2026-07-08", [f_base, f_mod_new, f_added])

  let diff = old_manifest.diff(new_manifest)
  assert_eq(diff.added.length(), 1)
  assert_eq(diff.added[0].path, "SECURITY.md")
  assert_eq(diff.removed.length(), 1)
  assert_eq(diff.removed[0].path, "legacy.mbt")
  assert_eq(diff.modified.length(), 1)
  assert_eq(diff.modified[0].path, "src/lib.mbt")
}

///|
test "manifest_json_formatting" {
  let f1 = FileSnapshot::from_bytes("test.mbt", b"test data")
  let manifest = Manifest::new("demo", "v0.1.0", "2026-07-08", [f1])
  let json = manifest.to_json_string()
  assert_true(json.length() > 50)
}
