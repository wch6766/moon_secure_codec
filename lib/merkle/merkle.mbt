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
    return { leaves: [], levels: [[empty_root]] }
  }

  let l0 : Array[Bytes] = []
  for i = 0; i < leaves.length(); i = i + 1 {
    l0.push(hash_leaf(leaves[i]))
  }

  let levels : Array[Array[Bytes]] = [l0]
  let mut cur = l0

  while cur.length() > 1 {
    let next_len = (cur.length() + 1) / 2
    let next_level : Array[Bytes] = []
    for i = 0; i < next_len; i = i + 1 {
      let left = cur[i * 2]
      let right = if i * 2 + 1 < cur.length() {
        cur[i * 2 + 1]
      } else {
        cur[i * 2]
      }
      next_level.push(hash_node(left, right))
    }
    levels.push(next_level)
    cur = next_level
  }

  { leaves, levels }
}

///|
/// Get the Merkle root hash as raw bytes.
pub fn MerkleTree::root(self : MerkleTree) -> Bytes {
  if self.levels.length() == 0 {
    @digest.sha256(b"")
  } else {
    let top_idx = self.levels.length() - 1
    self.levels[top_idx][0]
  }
}

///|
/// Get the Merkle root hash formatted as lowercase hex string.
pub fn MerkleTree::root_hex(self : MerkleTree) -> String {
  @codec.to_hex(self.root())
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
  let leaf_hash = self.levels[0][index]
  let steps : Array[MerkleStep] = []
  let mut cur_idx = index

  for l = 0; l < self.levels.length() - 1; l = l + 1 {
    let level_nodes = self.levels[l]
    let is_right_node = cur_idx % 2 == 1
    if is_right_node {
      steps.push({ is_left: true, sibling_hash: level_nodes[cur_idx - 1] })
    } else {
      let sib_idx = cur_idx + 1
      let sib_hash = if sib_idx < level_nodes.length() {
        level_nodes[sib_idx]
      } else {
        level_nodes[cur_idx]
      }
      steps.push({ is_left: false, sibling_hash: sib_hash })
    }
    cur_idx = cur_idx / 2
  }

  Ok({ leaf_hash, steps })
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
