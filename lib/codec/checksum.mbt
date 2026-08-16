///|
/// Compute CRC-32/ISO-HDLC for transport checksums and fixture validation.
/// CRC-32 is not a cryptographic integrity mechanism.
pub fn crc32(data : Bytes, seed? : UInt = 0xFFFFFFFF) -> UInt {
  let mut crc = seed
  let mut i = 0
  while i < data.length() {
    crc = crc ^ data[i].to_int().reinterpret_as_uint()
    let mut bit = 0
    while bit < 8 {
      let mask : UInt = 0 - (crc & 1)
      crc = (crc >> 1) ^ (0xEDB88320 & mask)
      bit = bit + 1
    }
    i = i + 1
  }
  crc ^ 0xFFFFFFFF
}

///|
/// Encode a payload with a four-byte big-endian CRC-32 trailer.
pub fn append_crc32(data : Bytes) -> Bytes {
  let checksum = crc32(data)
  let result : Array[Byte] = []
  for byte in data {
    result.push(byte)
  }
  result.push(((checksum >> 24) & 0xFF).reinterpret_as_int().to_byte())
  result.push(((checksum >> 16) & 0xFF).reinterpret_as_int().to_byte())
  result.push(((checksum >> 8) & 0xFF).reinterpret_as_int().to_byte())
  result.push((checksum & 0xFF).reinterpret_as_int().to_byte())
  Bytes::from_array(result)
}

///|
/// Verify and remove a four-byte big-endian CRC-32 trailer.
pub fn verify_crc32(frame : Bytes) -> Result[Bytes, String] {
  if frame.length() < 4 {
    return Err("CRC frame is shorter than its trailer")
  }
  let payload = frame[:frame.length() - 4].to_owned()
  let offset = frame.length() - 4
  let expected = (frame[offset].to_int().reinterpret_as_uint() << 24) |
    (frame[offset + 1].to_int().reinterpret_as_uint() << 16) |
    (frame[offset + 2].to_int().reinterpret_as_uint() << 8) |
    frame[offset + 3].to_int().reinterpret_as_uint()
  if crc32(payload) != expected {
    return Err("CRC-32 mismatch")
  }
  Ok(payload)
}

///|
/// Convert a UInt checksum into a fixed-width lowercase hexadecimal value.
pub fn crc32_hex(data : Bytes) -> String {
  let value = crc32(data)
  let bytes : Array[Byte] = [
    ((value >> 24) & 0xFF).reinterpret_as_int().to_byte(),
    ((value >> 16) & 0xFF).reinterpret_as_int().to_byte(),
    ((value >> 8) & 0xFF).reinterpret_as_int().to_byte(),
    (value & 0xFF).reinterpret_as_int().to_byte(),
  ]
  to_hex(Bytes::from_array(bytes))
}
