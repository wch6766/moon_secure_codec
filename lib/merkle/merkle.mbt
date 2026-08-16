///|
/// A single step along a Merkle verification path.
pub(all) struct MerkleStep {
  is_left : Bool
  sibling_hash : Bytes
}

///|
/// A complete Merkle inclusion proof for a leaf.
pub(all) struct MerkleProof {
  leaf_hash : Bytes
  steps : Array[MerkleStep]
}

///|
/// RFC 6962 compliant Merkle Tree with domain separation against second-preimage attacks.
pub(all) struct MerkleTree {
  leaves : Array[Bytes]
  levels : Array[Array[Bytes]]
  root_hash : Bytes
}

///|
/// Hash a leaf with 0x00 domain separation prefix (RFC 6962).
fn hash_leaf(leaf : Bytes) -> Bytes {
  let buf : Array[Byte] = [b'\x00']
  for i = 0; i < leaf.length(); i = i + 1 {
    buf.push(leaf[i])
  }
  @digest.sha256(Bytes::from_array(buf))
}

///|
/// Hash an internal node with 0x01 domain separation prefix (RFC 6962).
fn hash_node(left : Bytes, right : Bytes) -> Bytes {
  let buf : Array[Byte] = [b'\x01']
  for i = 0; i < left.length(); i = i + 1 {
    buf.push(left[i])
  }
  for i = 0; i < right.length(); i = i + 1 {
    buf.push(right[i])
  }
  @digest.sha256(Bytes::from_array(buf))
}

///|
/// Construct a new Merkle Tree from an array of leaf data bytes.
pub fn MerkleTree::new(leaves : Array[Bytes]) -> MerkleTree {
  if leaves.length() == 0 {
    let empty_root = @digest.sha256(b"")
    return { leaves: [], levels: [], root_hash: empty_root }
  }

  let root_hash = tree_hash_range(leaves, 0, leaves.length())
  { leaves, levels: [[root_hash]], root_hash }
}

///|
/// Get the Merkle root hash as raw bytes.
pub fn MerkleTree::root(self : MerkleTree) -> Bytes {
  self.root_hash
}

///|
/// Get the Merkle root hash formatted as lowercase hex string.
pub fn MerkleTree::root_hex(self : MerkleTree) -> String {
  @codec.to_hex(self.root())
}

///|
/// Return the number of original leaves in the tree.
pub fn MerkleTree::leaf_count(self : MerkleTree) -> Int {
  self.leaves.length()
}

///|
/// Generate and verify every inclusion proof against the current root.
/// This is useful as a release-time self-check before publishing a manifest.
pub fn MerkleTree::verify_all(self : MerkleTree) -> Bool {
  for i = 0; i < self.leaves.length(); i = i + 1 {
    match self.get_proof(i) {
      Ok(proof) => if !verify_proof(proof, self.root()) { return false }
      Err(_) => return false
    }
  }
  true
}

///|
/// Generate a Merkle inclusion proof for the leaf at the specified index.
pub fn MerkleTree::get_proof(
  self : MerkleTree,
  index : Int,
) -> Result[MerkleProof, String] {
  if index < 0 || index >= self.leaves.length() {
    return Err("Index out of bounds: " + index.to_string())
  }
  let steps : Array[MerkleStep] = []
  if !build_proof(self.leaves, 0, self.leaves.length(), index, steps) {
    return Err("Unable to construct proof for index: " + index.to_string())
  }
  Ok({ leaf_hash: hash_leaf(self.leaves[index]), steps })
}

///|
/// Compute the RFC 6962 tree hash using the largest-power-of-two split rule.
fn tree_hash_range(leaves : Array[Bytes], start : Int, count : Int) -> Bytes {
  if count == 0 {
    return @digest.sha256(b"")
  }
  if count == 1 {
    return hash_leaf(leaves[start])
  }
  let split = largest_power_of_two_less_than(count)
  let left = tree_hash_range(leaves, start, split)
  let right = tree_hash_range(leaves, start + split, count - split)
  hash_node(left, right)
}

///|
fn largest_power_of_two_less_than(value : Int) -> Int {
  let mut power = 1
  while power * 2 < value {
    power = power * 2
  }
  power
}

///|
/// Append the sibling path for a leaf using RFC 6962's recursive shape.
fn build_proof(
  leaves : Array[Bytes],
  start : Int,
  count : Int,
  target : Int,
  steps : Array[MerkleStep],
) -> Bool {
  if count == 1 {
    return target == start
  }
  let split = largest_power_of_two_less_than(count)
  if target < start + split {
    if !build_proof(leaves, start, split, target, steps) {
      return false
    }
    steps.push({
      is_left: false,
      sibling_hash: tree_hash_range(leaves, start + split, count - split),
    })
  } else {
    if !build_proof(leaves, start + split, count - split, target, steps) {
      return false
    }
    steps.push({
      is_left: true,
      sibling_hash: tree_hash_range(leaves, start, split),
    })
  }
  true
}

///|
/// Verify a Merkle inclusion proof against an expected root hash.
pub fn verify_proof(proof : MerkleProof, expected_root : Bytes) -> Bool {
  let mut cur = proof.leaf_hash
  for i = 0; i < proof.steps.length(); i = i + 1 {
    let step = proof.steps[i]
    if step.is_left {
      cur = hash_node(step.sibling_hash, cur)
    } else {
      cur = hash_node(cur, step.sibling_hash)
    }
  }
  bytes_eq(cur, expected_root)
}

///|
fn bytes_eq(a : Bytes, b : Bytes) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i = 0; i < a.length(); i = i + 1 {
    if a[i] != b[i] {
      return false
    }
  }
  true
}
