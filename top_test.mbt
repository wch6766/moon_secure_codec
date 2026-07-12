///|
test "facade_integration_workflow" {
  let entries : Array[(String, Bytes)] = [
    ("moon.mod", b"name = \"wch6766/moon_secure_codec\""),
    ("src/lib.mbt", b"pub fn hash() -> Int { 1 }"),
    ("README.md", b"# MoonSecureCodec"),
  ]
  let manifest = create_manifest("moon_secure_codec", "v0.1.0", entries)
  assert_true(manifest.verify_integrity())
  assert_true(manifest.merkle_root.length() == 64)

  let b64 = to_base64(b"test data")
  let decoded = from_base64(b64).unwrap()
  assert_eq(decoded, b"test data")

  let tree = make_merkle_tree([b"L1", b"L2"])
  assert_true(tree.root_hex().length() == 64)
}
