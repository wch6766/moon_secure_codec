///|
/// Convert byte array to lowercase Hex (Base16) string.
pub fn to_hex(bytes : Bytes) -> String {
  let hex_chars = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f',
  ]
  let buf = StringBuilder::new(size_hint=bytes.length() * 2)
  for i = 0; i < bytes.length(); i = i + 1 {
    let b = bytes[i].to_int()
    buf.write_char(hex_chars[b >> 4])
    buf.write_char(hex_chars[b & 0x0F])
  }
  buf.to_string()
}

///|
/// Decode Hex string (supporting both lowercase and uppercase) to byte array.
pub fn from_hex(s : String) -> Result[Bytes, String] {
  let len = s.length()
  if len % 2 != 0 {
    return Err("Hex string must have an even length")
  }
  let out_len = len / 2
  let out : Array[Byte] = []
  for i = 0; i < out_len; i = i + 1 {
    let c1 = s[i * 2]
    let c2 = s[i * 2 + 1]
    match (hex_val(c1), hex_val(c2)) {
      (Some(v1), Some(v2)) => out.push(((v1 << 4) | v2).to_byte())
      _ => return Err("Invalid hex character at index " + (i * 2).to_string())
    }
  }
  Ok(Bytes::from_array(out))
}

///|
fn hex_val(c : UInt16) -> Int? {
  let ci = c.to_int()
  if ci >= '0'.to_int() && ci <= '9'.to_int() {
    Some(ci - '0'.to_int())
  } else if ci >= 'a'.to_int() && ci <= 'f'.to_int() {
    Some(ci - 'a'.to_int() + 10)
  } else if ci >= 'A'.to_int() && ci <= 'F'.to_int() {
    Some(ci - 'A'.to_int() + 10)
  } else {
    None
  }
}

///|
/// Convert byte array to RFC 4648 Base32 uppercase string.
pub fn to_base32(bytes : Bytes) -> String {
  let alphabet = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '2', '3', '4', '5', '6', '7',
  ]
  let buf = StringBuilder::new()
  let mut buffer = 0
  let mut bits_left = 0
  for i = 0; i < bytes.length(); i = i + 1 {
    buffer = (buffer << 8) | bytes[i].to_int()
    bits_left = bits_left + 8
    while bits_left >= 5 {
      bits_left = bits_left - 5
      let idx = (buffer >> bits_left) & 0x1F
      buf.write_char(alphabet[idx])
    }
  }
  if bits_left > 0 {
    let idx = (buffer << (5 - bits_left)) & 0x1F
    buf.write_char(alphabet[idx])
  }
  let pad_count = match bytes.length() * 8 % 40 {
    8 => 6
    16 => 4
    24 => 3
    32 => 1
    _ => 0
  }
  for i = 0; i < pad_count; i = i + 1 {
    buf.write_char('=')
  }
  buf.to_string()
}

///|
/// Decode RFC 4648 Base32 string to byte array.
pub fn from_base32(s : String) -> Result[Bytes, String] {
  let mut buffer = 0
  let mut bits_left = 0
  let out_list : Array[Byte] = []
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i]
    if c.to_int() == '='.to_int() {
      break
    }
    match base32_val(c) {
      Some(v) => {
        buffer = (buffer << 5) | v
        bits_left = bits_left + 5
        if bits_left >= 8 {
          bits_left = bits_left - 8
          out_list.push(((buffer >> bits_left) & 0xFF).to_byte())
        }
      }
      None => return Err("Invalid Base32 character: " + c.to_string())
    }
  }
  Ok(Bytes::from_array(out_list))
}

///|
fn base32_val(c : UInt16) -> Int? {
  let ci = c.to_int()
  if ci >= 'A'.to_int() && ci <= 'Z'.to_int() {
    Some(ci - 'A'.to_int())
  } else if ci >= 'a'.to_int() && ci <= 'z'.to_int() {
    Some(ci - 'a'.to_int())
  } else if ci >= '2'.to_int() && ci <= '7'.to_int() {
    Some(ci - '2'.to_int() + 26)
  } else {
    None
  }
}

///|
/// Convert byte array to Base64 (or Base64URL when url_safe=true) string.
pub fn to_base64(bytes : Bytes, url_safe? : Bool = false) -> String {
  let std_alphabet = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
    'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/',
  ]
  let url_alphabet = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
    'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '-', '_',
  ]
  let alpha = if url_safe { url_alphabet } else { std_alphabet }
  let buf = StringBuilder::new()
  let len = bytes.length()
  let mut i = 0
  while i < len {
    let b1 = bytes[i].to_int()
    let b2 = if i + 1 < len { bytes[i + 1].to_int() } else { 0 }
    let b3 = if i + 2 < len { bytes[i + 2].to_int() } else { 0 }
    let triple = (b1 << 16) | (b2 << 8) | b3
    buf.write_char(alpha[(triple >> 18) & 0x3F])
    buf.write_char(alpha[(triple >> 12) & 0x3F])
    if i + 1 < len {
      buf.write_char(alpha[(triple >> 6) & 0x3F])
    } else if !url_safe {
      buf.write_char('=')
    }
    if i + 2 < len {
      buf.write_char(alpha[triple & 0x3F])
    } else if !url_safe {
      buf.write_char('=')
    }
    i = i + 3
  }
  buf.to_string()
}

///|
/// Decode Base64 or Base64URL string to byte array.
pub fn from_base64(s : String) -> Result[Bytes, String] {
  let mut buffer = 0
  let mut bits_left = 0
  let out_list : Array[Byte] = []
  for i = 0; i < s.length(); i = i + 1 {
    let ci = s[i].to_int()
    if ci == '='.to_int() ||
      ci == ' '.to_int() ||
      ci == '\n'.to_int() ||
      ci == '\r'.to_int() {
      continue
    }
    match base64_val(s[i]) {
      Some(v) => {
        buffer = (buffer << 6) | v
        bits_left = bits_left + 6
        if bits_left >= 8 {
          bits_left = bits_left - 8
          out_list.push(((buffer >> bits_left) & 0xFF).to_byte())
        }
      }
      None => return Err("Invalid Base64 character at index " + i.to_string())
    }
  }
  Ok(Bytes::from_array(out_list))
}

///|
fn base64_val(c : UInt16) -> Int? {
  let ci = c.to_int()
  if ci >= 'A'.to_int() && ci <= 'Z'.to_int() {
    Some(ci - 'A'.to_int())
  } else if ci >= 'a'.to_int() && ci <= 'z'.to_int() {
    Some(ci - 'a'.to_int() + 26)
  } else if ci >= '0'.to_int() && ci <= '9'.to_int() {
    Some(ci - '0'.to_int() + 52)
  } else if ci == '+'.to_int() || ci == '-'.to_int() {
    Some(62)
  } else if ci == '/'.to_int() || ci == '_'.to_int() {
    Some(63)
  } else {
    None
  }
}

///|
/// Convert byte array to Bitcoin Base58 string.
pub fn to_base58(bytes : Bytes) -> String {
  let alphabet = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G',
    'H', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y',
    'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'm', 'n', 'o', 'p',
    'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
  ]
  let mut zeros = 0
  while zeros < bytes.length() && bytes[zeros] == b'\x00' {
    zeros = zeros + 1
  }
  let digits : Array[Int] = []
  for i = zeros; i < bytes.length(); i = i + 1 {
    let mut carry = bytes[i].to_int()
    for j = 0; j < digits.length(); j = j + 1 {
      carry = carry + digits[j] * 256
      digits[j] = carry % 58
      carry = carry / 58
    }
    while carry > 0 {
      digits.push(carry % 58)
      carry = carry / 58
    }
  }
  let buf = StringBuilder::new()
  for i = 0; i < zeros; i = i + 1 {
    buf.write_char('1')
  }
  let mut idx = digits.length() - 1
  while idx >= 0 {
    buf.write_char(alphabet[digits[idx]])
    idx = idx - 1
  }
  buf.to_string()
}

///|
/// Decode Bitcoin Base58 string to byte array.
pub fn from_base58(s : String) -> Result[Bytes, String] {
  let mut zeros = 0
  while zeros < s.length() && s[zeros].to_int() == '1'.to_int() {
    zeros = zeros + 1
  }
  let digits : Array[Int] = []
  for i = zeros; i < s.length(); i = i + 1 {
    let c = s[i]
    match base58_val(c) {
      Some(v) => {
        let mut carry = v
        for j = 0; j < digits.length(); j = j + 1 {
          carry = carry + digits[j] * 58
          digits[j] = carry % 256
          carry = carry / 256
        }
        while carry > 0 {
          digits.push(carry % 256)
          carry = carry / 256
        }
      }
      None => return Err("Invalid Base58 character at index " + i.to_string())
    }
  }
  let out : Array[Byte] = []
  for i = 0; i < zeros; i = i + 1 {
    out.push(b'\x00')
  }
  let mut idx = digits.length() - 1
  while idx >= 0 {
    out.push(digits[idx].to_byte())
    idx = idx - 1
  }
  Ok(Bytes::from_array(out))
}

///|
fn base58_val(c : UInt16) -> Int? {
  let chars = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  for i = 0; i < chars.length(); i = i + 1 {
    if chars[i] == c {
      return Some(i)
    }
  }
  None
}
