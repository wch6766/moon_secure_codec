///|
test "hex_codec_roundtrip" {
  let original = b"Hello, MoonBit Supply Chain Security!"
  let encoded = to_hex(original)
  let decoded = from_hex(encoded).unwrap()
  assert_eq(decoded, original)
  assert_eq(from_hex("48656C6C6F").unwrap(), b"Hello")
}

///|
test "base32_codec_roundtrip" {
  let original = b"RFC4648 Base32 Encoding Test"
  let encoded = to_base32(original)
  let decoded = from_base32(encoded).unwrap()
  assert_eq(decoded, original)
}

///|
test "base64_codec_roundtrip" {
  let original = b"Supply Chain Fingerprinting & Tamper Evidence"
  let encoded_std = to_base64(original, url_safe=false)
  let decoded_std = from_base64(encoded_std).unwrap()
  assert_eq(decoded_std, original)

  let encoded_url = to_base64(original, url_safe=true)
  let decoded_url = from_base64(encoded_url).unwrap()
  assert_eq(decoded_url, original)
}

///|
test "base58_codec_roundtrip" {
  let original = b"\x00\x00Bitcoin Base58 Check Test"
  let encoded = to_base58(original)
  let decoded = from_base58(encoded).unwrap()
  assert_eq(decoded, original)
}

///|
test "codec_error_handling" {
  match from_hex("123") {
    Err(_) => ()
    Ok(_) => panic()
  }
  match from_base64("???invalid") {
    Err(_) => ()
    Ok(_) => panic()
  }
}

///|
test "multibase_roundtrips_and_digest_validation" {
  let original = b"content-addressed release artifact"
  let bases = [
    Multibase::Base16,
    Multibase::Base32,
    Multibase::Base64,
    Multibase::Base64Url,
    Multibase::Base58,
  ]
  for base in bases {
    let encoded = encode_multibase(original, base)
    let decoded = decode_multibase(encoded).unwrap()
    assert_eq(decoded.1, original)
  }
  assert_true(is_lower_hex("0123456789abcdef"))
  assert_false(is_lower_hex("ABCDEF"))
  assert_eq(decode_digest_hex("00010203", 4).unwrap(), b"\x00\x01\x02\x03")
  match decode_multibase("xunknown") {
    Err(_) => ()
    Ok(_) => panic()
  }
}

///|
test "crc32_transport_frame_roundtrip_and_tamper_detection" {
  let payload = b"release transport frame"
  assert_eq(crc32_hex(payload), "ca3bd31c")
  let frame = append_crc32(payload)
  assert_eq(verify_crc32(frame).unwrap(), payload)
  let tampered : Array[Byte] = []
  for byte in frame {
    tampered.push(byte)
  }
  tampered[0] = tampered[0] ^ 1
  match verify_crc32(Bytes::from_array(tampered)) {
    Err(_) => ()
    Ok(_) => panic()
  }
}

///|
test "canonical_varint_roundtrip_and_boundary_rejection" {
  let values : Array[UInt64] = [
    0UL, 1UL, 127UL, 128UL, 16_384UL, 0xFFFFFFFFFFFFFFFFUL,
  ]
  let encoded = encode_u64_varints(values)
  assert_eq(decode_u64_varints(encoded, values.length()).unwrap(), values)
  match decode_u64_varint(b"\x80\x00") {
    Err(_) => ()
    Ok(_) => panic()
  }
  match decode_u64_varints(encoded, values.length() + 1) {
    Err(_) => ()
    Ok(_) => panic()
  }
  assert_eq(u64_varint_size(127UL), 1)
  assert_eq(u64_varint_size(128UL), 2)
  assert_true(is_canonical_u64_varint(encode_u64_varint(16_384UL)))
}
