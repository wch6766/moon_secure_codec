///|
test "sha256_known_vectors" {
  let empty_hash = sha256_hex(b"")
  assert_eq(
    empty_hash, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  )

  let abc_hash = sha256_hex(b"abc")
  assert_eq(
    abc_hash, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  )
}

///|
test "xxhash64_fingerprint_stability" {
  let data1 = b"Supply Chain Manifest Item #1: MoonBit WASM Binary"
  let data2 = b"Supply Chain Manifest Item #1: MoonBit WASM Binary"
  let data3 = b"Supply Chain Manifest Item #2: MoonBit Native Binary"

  assert_eq(xxhash64(data1), xxhash64(data2))
  assert_true(xxhash64(data1) != xxhash64(data3))
}

///|
test "murmur3_fast_hash" {
  let h1 = murmur3_32(b"hello world", seed=0)
  let h2 = murmur3_32(b"hello world", seed=0)
  let h3 = murmur3_32(b"hello world", seed=12345)
  assert_eq(h1, h2)
  assert_true(h1 != h3)
}

///|
test "hmac_sha256_integrity" {
  let key = b"SecretSupplyChainKey"
  let msg = b"Package: Wchch/MoonSecureCodec v0.1.0"
  let mac1 = hmac_sha256_hex(key, msg)
  let mac2 = hmac_sha256_hex(key, msg)
  let mac3 = hmac_sha256_hex(b"WrongKey", msg)

  assert_eq(mac1, mac2)
  assert_true(mac1 != mac3)
}
