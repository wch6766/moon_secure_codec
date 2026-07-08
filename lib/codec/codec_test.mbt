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
