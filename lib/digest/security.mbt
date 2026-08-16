///|
/// Compare two byte strings without returning early on content mismatch.
/// This is appropriate for comparing already-computed MACs and digests.
pub fn constant_time_equal(left : Bytes, right : Bytes) -> Bool {
  let mut difference = left.length() ^ right.length()
  let limit = if left.length() > right.length() {
    left.length()
  } else {
    right.length()
  }
  for i = 0; i < limit; i = i + 1 {
    let a = if i < left.length() { left[i].to_int() } else { 0 }
    let b = if i < right.length() { right[i].to_int() } else { 0 }
    difference = difference | (a ^ b)
  }
  difference == 0
}

///|
/// Compare lowercase hexadecimal digests without decoding intermediate strings.
pub fn constant_time_hex_equal(left : String, right : String) -> Bool {
  if left.length() != right.length() {
    return false
  }
  let mut difference = 0
  for i = 0; i < left.length(); i = i + 1 {
    difference = difference | (left[i].to_int() ^ right[i].to_int())
  }
  difference == 0
}

///|
/// Verify an HMAC-SHA256 tag using a constant-time comparison.
pub fn verify_hmac_sha256(
  key : Bytes,
  message : Bytes,
  expected : Bytes,
) -> Bool {
  constant_time_equal(hmac_sha256(key, message), expected)
}

///|
/// Return SHA-256 digests for a batch of independent payloads.
pub fn sha256_batch(payloads : Array[Bytes]) -> Array[Bytes] {
  let result : Array[Bytes] = []
  for payload in payloads {
    result.push(sha256(payload))
  }
  result
}

///|
/// Return hexadecimal SHA-256 digests for a batch of independent payloads.
pub fn sha256_hex_batch(payloads : Array[Bytes]) -> Array[String] {
  let result : Array[String] = []
  for payload in payloads {
    result.push(sha256_hex(payload))
  }
  result
}
