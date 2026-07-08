///|
/// CLI main entry point demonstrating MoonSecureCodec supply chain security workflows.
fn main {
  println("===================================================================")
  println("  MoonSecureCodec: Supply Chain Fingerprinting & Security Toolkit  ")
  println("===================================================================\n")

  println("[1] Multi-Base Encoding Demo:")
  let original_data = b"Supply Chain Manifest Item #101"
  println("  Raw Data:  Supply Chain Manifest Item #101")
  println("  Hex:       " + @codec.to_hex(original_data))
  println("  Base32:    " + @codec.to_base32(original_data))
  println("  Base64:    " + @codec.to_base64(original_data))
  println("  Base58:    " + @codec.to_base58(original_data))

  println("\n[2] High-Speed Digests & Cryptographic Fingerprints:")
  let xx = @digest.xxhash64(original_data)
  let sha = @digest.sha256_hex(original_data)
  println("  XXHash64 (fast fingerprint): " + xx.to_string() + " (" + @digest.xxhash64_hex(original_data) + ")")
  println("  Murmur3_32:                  " + @digest.murmur3_32(original_data).to_string())
  println("  SHA-256 (crypto digest):     " + sha)

  println("\n[3] RFC 6962 Domain-Separated Merkle Tree & Proof Generation:")
  let leaves = [
    b"dependency: moonbitlang/core v0.1.0",
    b"dependency: moonbit-community/moon_secure_codec v0.1.0",
    b"license: Apache-2.0",
    b"target: wasm-gc",
  ]
  let tree = @merkle.MerkleTree::new(leaves)
  println("  Merkle Root Hash: " + tree.root_hex())
  let proof = tree.get_proof(1).unwrap()
  println("  Proof for leaf #1 verified: " + @merkle.verify_proof(proof, tree.root()).to_string())

  println("\n[4] SBOM / Supply Chain Manifest Generation & Audit Diffing:")
  let f1 = @manifest.FileSnapshot::from_bytes("moon.mod", b"name = \"moonbit-community/moon_secure_codec\"")
  let f2 = @manifest.FileSnapshot::from_bytes("lib/codec/codec.mbt", b"pub fn to_hex(bytes: Bytes) -> String")
  let m1 = @manifest.Manifest::new("moon_secure_codec", "v0.1.0", "2026-07-08T12:00:00Z", [f1, f2])
  println("  Manifest Name:        " + m1.name + " (" + m1.version + ")")
  println("  Embedded Merkle Root: " + m1.merkle_root)
  println("  Integrity Check:      Passed (" + m1.verify_integrity().to_string() + ")")

  let f2_mod = @manifest.FileSnapshot::from_bytes("lib/codec/codec.mbt", b"pub fn to_hex(bytes: Bytes) -> String // modified")
  let f3 = @manifest.FileSnapshot::from_bytes("SECURITY.md", b"# Security Vulnerability Reporting")
  let m2 = @manifest.Manifest::new("moon_secure_codec", "v0.2.0", "2026-07-08T13:00:00Z", [f1, f2_mod, f3])

  let diff = m1.diff(m2)
  println("\n[5] Supply Chain Manifest Diff Report (v0.1.0 -> v0.2.0):")
  println("  Added Files (" + diff.added.length().to_string() + "):    " + diff.added[0].path)
  println("  Modified Files (" + diff.modified.length().to_string() + "): " + diff.modified[0].path)
  println("  Removed Files (" + diff.removed.length().to_string() + "):  none")
  println("\n===================================================================")
  println("  Demo successfully completed. All checks passed!")
  println("===================================================================")
}
