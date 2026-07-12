///|
/// Fast 64-bit non-cryptographic content fingerprint (XXHash64 algorithm).
/// Extremely fast for checking supply chain manifest item equality.
pub fn xxhash64(bytes : Bytes, seed? : UInt64 = 0UL) -> UInt64 {
  let p1 : UInt64 = 11400714785074694791UL
  let p2 : UInt64 = 14029467366897019727UL
  let p3 : UInt64 = 1609587929392839161UL
  let p4 : UInt64 = 9650029242287828579UL
  let p5 : UInt64 = 2870177450012600261UL

  let len = bytes.length()
  let mut h64 : UInt64 = 0UL
  let mut idx = 0

  if len >= 32 {
    let mut v1 = seed + p1 + p2
    let mut v2 = seed + p2
    let mut v3 = seed + 0UL
    let mut v4 = seed - p1
    while idx <= len - 32 {
      v1 = xx_round(v1, read_u64_le(bytes, idx), p1, p2)
      v2 = xx_round(v2, read_u64_le(bytes, idx + 8), p1, p2)
      v3 = xx_round(v3, read_u64_le(bytes, idx + 16), p1, p2)
      v4 = xx_round(v4, read_u64_le(bytes, idx + 24), p1, p2)
      idx = idx + 32
    }
    h64 = rotl64(v1, 1) + rotl64(v2, 7) + rotl64(v3, 12) + rotl64(v4, 18)
    h64 = xx_merge_round(h64, v1, p1, p2, p4)
    h64 = xx_merge_round(h64, v2, p1, p2, p4)
    h64 = xx_merge_round(h64, v3, p1, p2, p4)
    h64 = xx_merge_round(h64, v4, p1, p2, p4)
  } else {
    h64 = seed + p5
  }

  h64 = h64 + len.to_int64().reinterpret_as_uint64()

  while idx <= len - 8 {
    let k1 = read_u64_le(bytes, idx)
    let k1_rot = rotl64(k1 * p2, 31) * p1
    h64 = (h64 ^ k1_rot) * p1 + p4
    h64 = rotl64(h64, 27) * p1 + p4
    idx = idx + 8
  }

  if idx <= len - 4 {
    let k1 = read_u32_le(bytes, idx)
      .reinterpret_as_int()
      .to_int64()
      .reinterpret_as_uint64()
    h64 = (h64 ^ (k1 * p1)) * p2 + p3
    h64 = rotl64(h64, 23) * p2 + p3
    idx = idx + 4
  }

  while idx < len {
    let k1 = bytes[idx].to_int().to_int64().reinterpret_as_uint64()
    h64 = (h64 ^ (k1 * p5)) * p1
    h64 = rotl64(h64, 11) * p1
    idx = idx + 1
  }

  h64 = h64 ^ (h64 >> 33)
  h64 = h64 * p2
  h64 = h64 ^ (h64 >> 29)
  h64 = h64 * p3
  h64 = h64 ^ (h64 >> 32)
  h64
}

///|
pub fn xxhash64_hex(bytes : Bytes, seed? : UInt64 = 0UL) -> String {
  let h = xxhash64(bytes, seed~)
  let out : Array[Byte] = []
  for i = 7; i >= 0; i = i - 1 {
    out.push(
      ((h >> (i * 8)) & 0xFFUL).reinterpret_as_int64().to_int().to_byte(),
    )
  }
  @codec.to_hex(Bytes::from_array(out))
}

///|
fn rotl64(x : UInt64, r : Int) -> UInt64 {
  (x << r) | (x >> (64 - r))
}

///|
fn xx_round(acc : UInt64, input : UInt64, p1 : UInt64, p2 : UInt64) -> UInt64 {
  let mut a = acc + input * p2
  a = rotl64(a, 31)
  a * p1
}

///|
fn xx_merge_round(
  acc : UInt64,
  val : UInt64,
  p1 : UInt64,
  p2 : UInt64,
  p4 : UInt64,
) -> UInt64 {
  let v = xx_round(0UL, val, p1, p2)
  let mut a = acc ^ v
  a = a * p1 + p4
  a
}

///|
fn read_u64_le(b : Bytes, offset : Int) -> UInt64 {
  let b0 = b[offset].to_int().to_int64()
  let b1 = b[offset + 1].to_int().to_int64()
  let b2 = b[offset + 2].to_int().to_int64()
  let b3 = b[offset + 3].to_int().to_int64()
  let b4 = b[offset + 4].to_int().to_int64()
  let b5 = b[offset + 5].to_int().to_int64()
  let b6 = b[offset + 6].to_int().to_int64()
  let b7 = b[offset + 7].to_int().to_int64()
  let val : Int64 = b0 |
    (b1 << 8) |
    (b2 << 16) |
    (b3 << 24) |
    (b4 << 32) |
    (b5 << 40) |
    (b6 << 48) |
    (b7 << 56)
  val.reinterpret_as_uint64()
}

///|
fn read_u32_le(b : Bytes, offset : Int) -> UInt {
  let b0 = b[offset].to_int().reinterpret_as_uint()
  let b1 = b[offset + 1].to_int().reinterpret_as_uint()
  let b2 = b[offset + 2].to_int().reinterpret_as_uint()
  let b3 = b[offset + 3].to_int().reinterpret_as_uint()
  b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
}

///|
/// Fast 32-bit Murmur3 hash for compact indexing.
pub fn murmur3_32(bytes : Bytes, seed? : UInt = 0) -> UInt {
  let c1 : UInt = 0xcc9e2d51
  let c2 : UInt = 0x1b873593
  let len = bytes.length()
  let mut h1 = seed
  let nblocks = len / 4

  for i = 0; i < nblocks; i = i + 1 {
    let mut k1 = read_u32_le(bytes, i * 4)
    k1 = k1 * c1
    k1 = (k1 << 15) | (k1 >> 17)
    k1 = k1 * c2

    h1 = h1 ^ k1
    h1 = (h1 << 13) | (h1 >> 19)
    h1 = h1 * 5 + 0xe6546b64
  }

  let tail_idx = nblocks * 4
  let mut k1 : UInt = 0
  let rem = len & 3
  if rem == 3 {
    k1 = k1 ^ (bytes[tail_idx + 2].to_int().reinterpret_as_uint() << 16)
  }
  if rem >= 2 {
    k1 = k1 ^ (bytes[tail_idx + 1].to_int().reinterpret_as_uint() << 8)
  }
  if rem >= 1 {
    k1 = k1 ^ bytes[tail_idx].to_int().reinterpret_as_uint()
    k1 = k1 * c1
    k1 = (k1 << 15) | (k1 >> 17)
    k1 = k1 * c2
    h1 = h1 ^ k1
  }

  h1 = h1 ^ len.reinterpret_as_uint()
  h1 = h1 ^ (h1 >> 16)
  h1 = h1 * 0x85ebca6b
  h1 = h1 ^ (h1 >> 13)
  h1 = h1 * 0xc2b2ae35
  h1 = h1 ^ (h1 >> 16)
  h1
}

///|
/// Cryptographic SHA-256 hash function producing a 32-byte digest.
pub fn sha256(bytes : Bytes) -> Bytes {
  let len = bytes.length()
  let padded : Array[Byte] = []
  for i = 0; i < len; i = i + 1 {
    padded.push(bytes[i])
  }
  padded.push(b'\x80')
  while padded.length() % 64 != 56 {
    padded.push(b'\x00')
  }
  let bit_len = len.to_int64() * 8L
  for i = 7; i >= 0; i = i - 1 {
    padded.push(((bit_len >> (i * 8)) & 0xFFL).to_int().to_byte())
  }

  let mut h0 : UInt = 0x6a09e667
  let mut h1 : UInt = 0xbb67ae85
  let mut h2 : UInt = 0x3c6ef372
  let mut h3 : UInt = 0xa54ff53a
  let mut h4 : UInt = 0x510e527f
  let mut h5 : UInt = 0x9b05688c
  let mut h6 : UInt = 0x1f83d9ab
  let mut h7 : UInt = 0x5be0cd19

  let k : Array[UInt] = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4,
    0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe,
    0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f,
    0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc,
    0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
    0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116,
    0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7,
    0xc67178f2,
  ]

  let w : Array[UInt] = Array::make(64, 0)
  let total_len = padded.length()
  let nchunks = total_len / 64
  let padded_bytes = Bytes::from_array(padded)

  for c = 0; c < nchunks; c = c + 1 {
    let offset = c * 64
    for i = 0; i < 16; i = i + 1 {
      w[i] = read_u32_be(padded_bytes, offset + i * 4)
    }
    for i = 16; i < 64; i = i + 1 {
      let s0 = rotr32(w[i - 15], 7) ^ rotr32(w[i - 15], 18) ^ (w[i - 15] >> 3)
      let s1 = rotr32(w[i - 2], 17) ^ rotr32(w[i - 2], 19) ^ (w[i - 2] >> 10)
      w[i] = w[i - 16] + s0 + w[i - 7] + s1
    }

    let mut a = h0
    let mut b = h1
    let mut c_reg = h2
    let mut d = h3
    let mut e = h4
    let mut f = h5
    let mut g = h6
    let mut h_reg = h7

    for i = 0; i < 64; i = i + 1 {
      let s1 = rotr32(e, 6) ^ rotr32(e, 11) ^ rotr32(e, 25)
      let not_e = e ^ 0xFFFFFFFF
      let ch = (e & f) ^ (not_e & g)
      let temp1 = h_reg + s1 + ch + k[i] + w[i]
      let s0 = rotr32(a, 2) ^ rotr32(a, 13) ^ rotr32(a, 22)
      let maj = (a & b) ^ (a & c_reg) ^ (b & c_reg)
      let temp2 = s0 + maj

      h_reg = g
      g = f
      f = e
      e = d + temp1
      d = c_reg
      c_reg = b
      b = a
      a = temp1 + temp2
    }

    h0 = h0 + a
    h1 = h1 + b
    h2 = h2 + c_reg
    h3 = h3 + d
    h4 = h4 + e
    h5 = h5 + f
    h6 = h64_to_u32(h6.to_int64() + g.to_int64())
    h7 = h64_to_u32(h7.to_int64() + h_reg.to_int64())
  }

  let out : Array[Byte] = []
  push_u32_be(out, h0)
  push_u32_be(out, h1)
  push_u32_be(out, h2)
  push_u32_be(out, h3)
  push_u32_be(out, h4)
  push_u32_be(out, h5)
  push_u32_be(out, h6)
  push_u32_be(out, h7)
  Bytes::from_array(out)
}

///|
fn rotr32(x : UInt, r : Int) -> UInt {
  (x >> r) | (x << (32 - r))
}

///|
fn h64_to_u32(x : Int64) -> UInt {
  (x & 0xFFFFFFFFL)
  .reinterpret_as_uint64()
  .reinterpret_as_int64()
  .to_int()
  .reinterpret_as_uint()
}

///|
fn read_u32_be(b : Bytes, offset : Int) -> UInt {
  let b0 = b[offset].to_int().reinterpret_as_uint()
  let b1 = b[offset + 1].to_int().reinterpret_as_uint()
  let b2 = b[offset + 2].to_int().reinterpret_as_uint()
  let b3 = b[offset + 3].to_int().reinterpret_as_uint()
  (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
}

///|
fn push_u32_be(out : Array[Byte], v : UInt) -> Unit {
  let vi = v.reinterpret_as_int()
  out.push(((vi >> 24) & 0xFF).to_byte())
  out.push(((vi >> 16) & 0xFF).to_byte())
  out.push(((vi >> 8) & 0xFF).to_byte())
  out.push((vi & 0xFF).to_byte())
}

///|
/// Convert SHA-256 digest to hex string.
pub fn sha256_hex(bytes : Bytes) -> String {
  @codec.to_hex(sha256(bytes))
}

///|
/// HMAC-SHA256 message authentication code.
pub fn hmac_sha256(key : Bytes, message : Bytes) -> Bytes {
  let block_size = 64
  let actual_key = if key.length() > block_size {
    sha256(key)
  } else if key.length() < block_size {
    let padded : Array[Byte] = []
    for i = 0; i < key.length(); i = i + 1 {
      padded.push(key[i])
    }
    for i = key.length(); i < block_size; i = i + 1 {
      padded.push(b'\x00')
    }
    Bytes::from_array(padded)
  } else {
    key
  }

  let i_pad : Array[Byte] = []
  let o_pad : Array[Byte] = []
  for i = 0; i < block_size; i = i + 1 {
    i_pad.push((actual_key[i].to_int() ^ 0x36).to_byte())
    o_pad.push((actual_key[i].to_int() ^ 0x5C).to_byte())
  }

  let inner_msg : Array[Byte] = []
  for i = 0; i < block_size; i = i + 1 {
    inner_msg.push(i_pad[i])
  }
  for i = 0; i < message.length(); i = i + 1 {
    inner_msg.push(message[i])
  }
  let inner_hash = sha256(Bytes::from_array(inner_msg))

  let outer_msg : Array[Byte] = []
  for i = 0; i < block_size; i = i + 1 {
    outer_msg.push(o_pad[i])
  }
  for i = 0; i < inner_hash.length(); i = i + 1 {
    outer_msg.push(inner_hash[i])
  }
  sha256(Bytes::from_array(outer_msg))
}

///|
pub fn hmac_sha256_hex(key : Bytes, message : Bytes) -> String {
  @codec.to_hex(hmac_sha256(key, message))
}
