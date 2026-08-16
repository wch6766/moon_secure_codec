///|
test "manifest_creation_and_integrity" {
  let f1 = FileSnapshot::from_bytes(
    "src/main.mbt", b"fn main() { println(\"Hello\") }",
  )
  let f2 = FileSnapshot::from_bytes(
    "moon.pkg", b"import { \"moonbitlang/core/digest\" }",
  )
  let manifest = Manifest::new(
    "test_project",
    "v1.0.0",
    "2026-07-08T12:00:00Z",
    [f1, f2],
  )

  assert_true(manifest.merkle_root.length() == 64)
  assert_true(manifest.verify_integrity())
}

///|
test "manifest_tamper_detection" {
  let f1 = FileSnapshot::from_bytes(
    "src/utils.mbt", b"pub fn helper() -> Int { 42 }",
  )
  let manifest = Manifest::new("app_core", "v0.1.0", "2026-07-08T12:00:00Z", [
    f1,
  ])
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
  let f_mod_old = FileSnapshot::from_bytes(
    "src/lib.mbt", b"pub fn version() -> Int { 1 }",
  )
  let f_rem = FileSnapshot::from_bytes("legacy.mbt", b"// old code")

  let old_manifest = Manifest::new("my_pkg", "v1.0.0", "2026-07-01", [
    f_base, f_mod_old, f_rem,
  ])

  let f_mod_new = FileSnapshot::from_bytes(
    "src/lib.mbt", b"pub fn version() -> Int { 2 }",
  )
  let f_added = FileSnapshot::from_bytes("SECURITY.md", b"# Security Policy")

  let new_manifest = Manifest::new("my_pkg", "v1.1.0", "2026-07-08", [
    f_base, f_mod_new, f_added,
  ])

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

///|
test "manifest_audit_accepts_canonical_snapshot" {
  let file = FileSnapshot::from_bytes("lib/codec.mbt", b"stable source")
  let manifest = Manifest::new("pkg", "1.0.0", "2026-08-12T00:00:00Z", [file])
  let report = manifest.audit_with_policy([".mbt"], 1024L)
  assert_false(report.has_errors())
  assert_eq(report.files_checked, 1)
  assert_eq(report.total_bytes, 13L)
}

///|
test "manifest_audit_rejects_traversal_duplicate_and_bad_hash" {
  let first = FileSnapshot::from_bytes("../secret.mbt", b"x")
  let duplicate : FileSnapshot = {
    path: "../secret.mbt",
    size: -1L,
    hash_xx64: first.hash_xx64,
    hash_sha256: "not-a-sha256",
  }
  let manifest = Manifest::new("pkg", "1.0.0", "2026-08-12T00:00:00Z", [
    first, duplicate,
  ])
  let report = manifest.audit()
  assert_true(report.has_errors())
  assert_true(report.to_text().length() > 100)
  assert_true(report.count(AuditSeverity::Error) >= 4)
}

///|
test "manifest_audit_detects_tampered_root_and_policy_limits" {
  let file = FileSnapshot::from_bytes("release.bin", b"artifact")
  let manifest = Manifest::new("pkg", "1.0.0", "2026-08-12T00:00:00Z", [file])
  manifest.merkle_root = "0000000000000000000000000000000000000000000000000000000000000000"
  let report = manifest.audit_with_policy([".mbt"], 2L)
  assert_true(report.has_errors())
  assert_true(report.count(AuditSeverity::Warning) >= 1)
}

///|
test "dependency_policy_accepts_pinned_apache_dependency" {
  let dependency : Dependency = {
    name: "moonbitlang/core",
    version: "0.10.3",
    license: "Apache-2.0",
    source: "https://github.com/moonbitlang/core",
    digest: "0123456789abcdef0123456789abcdef",
  }
  let audit = audit_dependencies(
    [dependency],
    LicensePolicy::strict(["Apache-2.0"]),
  )
  assert_false(audit.has_errors())
  assert_eq(audit.count(AuditSeverity::Error), 0)
}

///|
test "dependency_policy_reports_unreviewed_metadata" {
  let dependency : Dependency = {
    name: "untrusted/package",
    version: "",
    license: "GPL-3.0-only",
    source: "",
    digest: "",
  }
  let audit = audit_dependencies(
    [dependency],
    LicensePolicy::strict(["Apache-2.0"]),
  )
  assert_true(audit.has_errors())
  assert_true(audit.count(AuditSeverity::Error) >= 3)
}

///|
test "manifest_statistics_submanifest_and_diff_summary" {
  let first = FileSnapshot::from_bytes("src/main.mbt", b"main")
  let second = FileSnapshot::from_bytes("dist/app.wasm", b"wasm")
  let manifest = Manifest::new("pkg", "1.0.0", "now", [first, second])
  let stats = manifest.statistics()
  assert_eq(stats.file_count, 2)
  assert_eq(stats.total_bytes, 8L)
  assert_eq(stats.largest_path, "src/main.mbt")
  assert_true(manifest.find("src/main.mbt") is Some(_))
  assert_eq(manifest.files_under("src").length(), 1)
  assert_eq(manifest.submanifest("src").files.length(), 1)
  assert_true(manifest.summary().length() > 100)

  let changed = Manifest::new("pkg", "1.1.0", "later", [
    FileSnapshot::from_bytes("src/main.mbt", b"changed"),
  ])
  let diff = manifest.diff(changed)
  assert_true(diff.has_changes())
  assert_true(diff.summary().contains("modified=1"))
}

///|
test "manifest_merge_keeps_newer_snapshot_and_unique_paths" {
  let old = Manifest::new("pkg", "1.0.0", "old", [
    FileSnapshot::from_bytes("README.md", b"old"),
    FileSnapshot::from_bytes("src/a.mbt", b"a"),
  ])
  let newer = Manifest::new("pkg", "1.1.0", "new", [
    FileSnapshot::from_bytes("README.md", b"new"),
    FileSnapshot::from_bytes("src/b.mbt", b"b"),
  ])
  let merged = old.merge(newer)
  assert_true(merged.has_unique_paths())
  assert_eq(merged.files.length(), 3)
  assert_eq(
    merged.find("README.md").unwrap().hash_sha256,
    @digest.sha256_hex(b"new"),
  )
  assert_true(merged.has_complete_digests())
}

///|
test "release_policy_checks_required_files_and_generated_outputs" {
  let manifest = Manifest::new("pkg", "1.0.0", "now", [
    FileSnapshot::from_bytes("README.md", b"readme"),
    FileSnapshot::from_bytes("LICENSE", b"license"),
    FileSnapshot::from_bytes("moon.mod", b"module"),
    FileSnapshot::from_bytes("target/app.wasm", b"binary"),
  ])
  let policy = ReleasePolicy::source_package()
  assert_false(manifest.is_source_release_ready())
  assert_true(manifest.missing_paths(["README.md", "NOTICE"]).length() == 1)
  assert_false(manifest.contains_only_extensions([".md", ".toml"]))
  let report = manifest.release_check(policy)
  assert_true(report.has_errors())
  assert_true(report.to_text().contains("GENERATED_FILE_REJECTED"))
}

///|
test "approval_record_binds_to_exact_merkle_root" {
  let manifest = Manifest::new("pkg", "1.0.0", "now", [
    FileSnapshot::from_bytes("README.md", b"readme"),
    FileSnapshot::from_bytes("LICENSE", b"license"),
    FileSnapshot::from_bytes("moon.mod", b"module"),
  ])
  let approval : ApprovalRecord = {
    reviewer: "release-bot",
    ticket: "REL-101",
    reviewed_root: manifest.merkle_root,
    approved_at: "2026-08-12T10:00:00Z",
    notes: "automated and human review complete",
  }
  assert_true(approval.matches(manifest))
  assert_true(ApprovalGate::strict().evaluate(manifest, Some(approval)))
  assert_true(manifest.approval_payload().contains(manifest.merkle_root))
  assert_true(manifest.approval_finding(None) is Some(_))
}
