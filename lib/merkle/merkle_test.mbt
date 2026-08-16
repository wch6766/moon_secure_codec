///|
test "merkle_tree_empty" {
  let tree = MerkleTree::new([])
  assert_eq(tree.root_hex().length(), 64)
}

///|
test "merkle_tree_single_leaf" {
  let leaves = [b"Package #1: wch6766/MoonSecureCodec"]
  let tree = MerkleTree::new(leaves)
  let proof = tree.get_proof(0).unwrap()
  assert_true(verify_proof(proof, tree.root()))
}

///|
test "merkle_tree_multi_leaf_and_tamper_detection" {
  let leaves = [
    b"dependency: moonbitlang/core v0.1.0", b"dependency: wch6766/MoonSecureCodec v0.1.0",
    b"manifest_hash: 48656c6c6f204d6f6f6e426974", b"license: Apache-2.0", b"build_target: wasm-gc",
  ]
  let tree = MerkleTree::new(leaves)
  let root_hash = tree.root()

  for i = 0; i < leaves.length(); i = i + 1 {
    let proof = tree.get_proof(i).unwrap()
    assert_true(verify_proof(proof, root_hash))
  }

  let tampered_proof = tree.get_proof(1).unwrap()
  assert_false(verify_proof(tampered_proof, @digest.sha256(b"FakeRootHash")))
}

///|
test "merkle_proof_out_of_bounds" {
  let tree = MerkleTree::new([b"A", b"B"])
  match tree.get_proof(5) {
    Err(_) => ()
    Ok(_) => panic()
  }
}

///|
test "merkle_tree_release_self_check" {
  let tree = MerkleTree::new([b"one", b"two", b"three", b"four", b"five"])
  assert_eq(tree.leaf_count(), 5)
  assert_true(tree.verify_all())
}

///|
test "rfc6962_reference_vectors_for_leaf_and_two_leaf_tree" {
  let single = MerkleTree::new([b"a"])
  assert_eq(
    single.root_hex(),
    "022a6979e6dab7aa5ae4c3e5e45f7e977112a7e63593820dbec1ec738a24f93c",
  )
  let pair = MerkleTree::new([b"a", b"b"])
  assert_eq(
    pair.root_hex(),
    "b137985ff484fb600db93107c77b0365c80d78f5b429ded0fd97361d077999eb",
  )
}

///|
test "rfc6962_non_power_of_two_tree_proofs" {
  let tree = MerkleTree::new([b"a", b"b", b"c"])
  assert_eq(
    tree.root_hex(),
    "36642e73c2540ab121e3a6bf9545b0a24982cd830eb13d3cd19de3ce6c021ec1",
  )
  for index = 0; index < 3; index = index + 1 {
    assert_true(verify_proof(tree.get_proof(index).unwrap(), tree.root()))
  }
}
