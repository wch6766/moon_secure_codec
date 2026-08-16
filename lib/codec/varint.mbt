///|
/// Encode an unsigned 64-bit integer using canonical LEB128 bytes.
/// The representation is useful for compact manifest indexes and transport frames.
pub fn encode_u64_varint(value : UInt64) -> Bytes {
  let mut current = value
  let output : Array[Byte] = []
  while current >= 0x80UL {
    output.push((current & 0x7FUL).to_int().to_byte() | b'\x80')
    current = current >> 7
  }
  output.push(current.to_int().to_byte())
  Bytes::from_array(output)
}

///|
/// Decode one canonical unsigned LEB128 integer from a byte array.
/// The returned integer is paired with the number of consumed bytes.
pub fn decode_u64_varint(data : Bytes) -> Result[(UInt64, Int), String] {
  let mut value = 0UL
  let mut shift = 0
  let mut index = 0
  while index < data.length() {
    if index >= 10 {
      return Err("Varint exceeds UInt64 width")
    }
    let byte = data[index].to_int().to_uint64()
    let payload = byte & 0x7FUL
    if shift == 63 && payload > 1UL {
      return Err("Varint overflows UInt64")
    }
    value = value | (payload << shift)
    index = index + 1
    if (byte & 0x80UL) == 0UL {
      if index > 1 && payload == 0UL {
        return Err("Varint is not minimally encoded")
      }
      return Ok((value, index))
    }
    shift = shift + 7
  }
  Err("Incomplete varint")
}

///|
/// Encode a sequence of unsigned integers with no framing ambiguity.
pub fn encode_u64_varints(values : Array[UInt64]) -> Bytes {
  let output : Array[Byte] = []
  for value in values {
    let encoded = encode_u64_varint(value)
    for byte in encoded {
      output.push(byte)
    }
  }
  Bytes::from_array(output)
}

///|
/// Decode exactly `count` consecutive unsigned LEB128 values.
pub fn decode_u64_varints(
  data : Bytes,
  count : Int,
) -> Result[Array[UInt64], String] {
  if count < 0 {
    return Err("Varint count cannot be negative")
  }
  let values : Array[UInt64] = []
  let mut offset = 0
  for _ in 0..<count {
    if offset >= data.length() {
      return Err("Not enough varint values")
    }
    let rest = data[offset:].to_owned()
    match decode_u64_varint(rest) {
      Ok((value, consumed)) => {
        values.push(value)
        offset = offset + consumed
      }
      Err(message) => return Err(message)
    }
  }
  if offset != data.length() {
    return Err("Trailing bytes after varint sequence")
  }
  Ok(values)
}

///|
/// Return the canonical byte width of an unsigned integer's varint encoding.
pub fn u64_varint_size(value : UInt64) -> Int {
  let mut current = value
  let mut size = 1
  while current >= 0x80UL {
    current = current >> 7
    size = size + 1
  }
  size
}

///|
/// Check that a byte sequence is exactly one canonical varint.
pub fn is_canonical_u64_varint(data : Bytes) -> Bool {
  match decode_u64_varint(data) {
    Ok((value, consumed)) =>
      consumed == data.length() && consumed == u64_varint_size(value)
    Err(_) => false
  }
}
