///|
/// Create a secure supply chain manifest and compute its Merkle root directly from memory buffers.
pub fn create_manifest(
  name : String,
  version : String,
  entries : Array[(String, Bytes)],
) -> @manifest.Manifest {
  let files : Array[@manifest.FileSnapshot] = []
  for i = 0; i < entries.length(); i = i + 1 {
    let (path, data) = entries[i]
    files.push(@manifest.FileSnapshot::from_bytes(path, data))
  }
  @manifest.Manifest::new(name, version, "2026-07-08T12:00:00Z", files)
}

///|
/// Compute SHA-256 hex digest for any byte array.
pub fn sha256_hex(data : Bytes) -> String {
  @digest.sha256_hex(data)
}

///|
/// Compute XXHash64 content fingerprint for any byte array.
pub fn xxhash64(data : Bytes) -> UInt64 {
  @digest.xxhash64(data)
}

///|
/// Encode bytes to Base64 (or Base64URL).
pub fn to_base64(data : Bytes, url_safe? : Bool = false) -> String {
  @codec.to_base64(data, url_safe~)
}

///|
/// Decode Base64 string to bytes.
pub fn from_base64(s : String) -> Result[Bytes, String] {
  @codec.from_base64(s)
}

///|
/// Construct a Merkle tree directly from leaf bytes.
pub fn make_merkle_tree(leaves : Array[Bytes]) -> @merkle.MerkleTree {
  @merkle.MerkleTree::new(leaves)
}
