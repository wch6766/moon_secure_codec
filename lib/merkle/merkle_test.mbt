///|
test "merkle_tree_empty" {
  let tree = MerkleTree::new([])
  assert_eq(tree.root_hex().length(), 64)
}

///|
test "merkle_tree_single_leaf" {
  let leaves = [b"Package #1: wch6766/moon_secure_codec"]
  let tree = MerkleTree::new(leaves)
  let proof = tree.get_proof(0).unwrap()
  assert_true(verify_proof(proof, tree.root()))
}

///|
test "merkle_tree_multi_leaf_and_tamper_detection" {
  let leaves = [
    b"dependency: moonbitlang/core v0.1.0", b"dependency: wch6766/moon_secure_codec v0.1.0",
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
