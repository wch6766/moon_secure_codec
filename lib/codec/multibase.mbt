///|
/// Multibase prefixes supported by common content-addressed systems.
pub(all) enum Multibase {
  Base16
  Base32
  Base64
  Base64Url
  Base58
} derive(Debug, Eq)

///|
/// Encode bytes with an explicit multibase prefix.
pub fn encode_multibase(data : Bytes, base : Multibase) -> String {
  match base {
    Multibase::Base16 => "f" + to_hex(data)
    Multibase::Base32 => "b" + to_base32(data).to_lower()
    Multibase::Base64 => "m" + to_base64(data)
    Multibase::Base64Url => "u" + to_base64(data, url_safe=true)
    Multibase::Base58 => "z" + to_base58(data)
  }
}

///|
/// Decode a multibase string and return its detected base and payload.
pub fn decode_multibase(value : String) -> Result[(Multibase, Bytes), String] {
  if value.length() < 1 {
    return Err("Multibase value must contain a prefix")
  }
  let payload = value[1:].to_owned()
  match value[0] {
    'f' => from_hex(payload).map(fn(data) { (Multibase::Base16, data) })
    'b' => from_base32(payload).map(fn(data) { (Multibase::Base32, data) })
    'm' => from_base64(payload).map(fn(data) { (Multibase::Base64, data) })
    'u' => from_base64(payload).map(fn(data) { (Multibase::Base64Url, data) })
    'z' => from_base58(payload).map(fn(data) { (Multibase::Base58, data) })
    _ => Err("Unsupported multibase prefix: " + value[0].to_string())
  }
}

///|
/// Check whether a string is a valid lowercase hexadecimal content identifier.
pub fn is_lower_hex(value : String) -> Bool {
  if value.length() == 0 {
    return false
  }
  for c in value {
    if !((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')) {
      return false
    }
  }
  true
}

///|
/// Decode a hexadecimal identifier and enforce an exact digest length.
pub fn decode_digest_hex(
  value : String,
  expected_bytes : Int,
) -> Result[Bytes, String] {
  if value.length() != expected_bytes * 2 {
    return Err("Digest has unexpected length")
  }
  if !is_lower_hex(value) {
    return Err("Digest must be lowercase hexadecimal")
  }
  from_hex(value)
}
