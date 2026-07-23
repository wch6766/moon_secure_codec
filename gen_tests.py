import hashlib
import base64
import os

def generate_codec_tests():
    out = []
    out.append("///|")
    
    # Generate Hex tests
    for i in range(250):
        data = os.urandom(64)
        hex_str = data.hex()
        moon_bytes = "b\"" + "".join([f"\\x{b:02x}" for b in data]) + "\""
        out.append(f"test \"hex_fuzz_{i}\" {{")
        out.append(f"  let input = {moon_bytes}")
        out.append(f"  let expected = \"{hex_str}\"")
        out.append(f"  assert_eq!(to_hex(input), expected)")
        out.append(f"  assert_eq!(from_hex(expected).unwrap(), input)")
        out.append(f"}}")
        out.append("///|")

    # Generate Base64 tests
    for i in range(250):
        data = os.urandom(64)
        b64_str = base64.b64encode(data).decode('utf-8')
        moon_bytes = "b\"" + "".join([f"\\x{b:02x}" for b in data]) + "\""
        out.append(f"test \"base64_fuzz_{i}\" {{")
        out.append(f"  let input = {moon_bytes}")
        out.append(f"  let expected = \"{b64_str}\"")
        out.append(f"  assert_eq!(to_base64(input), expected)")
        out.append(f"  assert_eq!(from_base64(expected).unwrap(), input)")
        out.append(f"}}")
        out.append("///|")

    # Generate Base32 tests
    for i in range(250):
        data = os.urandom(64)
        b32_str = base64.b32encode(data).decode('utf-8')
        moon_bytes = "b\"" + "".join([f"\\x{b:02x}" for b in data]) + "\""
        out.append(f"test \"base32_fuzz_{i}\" {{")
        out.append(f"  let input = {moon_bytes}")
        out.append(f"  let expected = \"{b32_str}\"")
        out.append(f"  assert_eq!(to_base32(input), expected)")
        out.append(f"  assert_eq!(from_base32(expected).unwrap(), input)")
        out.append(f"}}")
        out.append("///|")

    with open("c:/Users/33046/Desktop/moobit/嫂子/lib/codec/codec_fuzz_test.mbt", "w", encoding='utf-8') as f:
        f.write("\n".join(out))

def generate_digest_tests():
    out = []
    out.append("///|")
    
    # Generate SHA-256 tests
    for i in range(250):
        data = os.urandom(128)
        sha256_hex = hashlib.sha256(data).hexdigest()
        moon_bytes = "b\"" + "".join([f"\\x{b:02x}" for b in data]) + "\""
        out.append(f"test \"sha256_fuzz_{i}\" {{")
        out.append(f"  let input = {moon_bytes}")
        out.append(f"  let expected = \"{sha256_hex}\"")
        out.append(f"  assert_eq!(sha256_hex(input), expected)")
        out.append(f"}}")
        out.append("///|")
        
    with open("c:/Users/33046/Desktop/moobit/嫂子/lib/digest/digest_fuzz_test.mbt", "w", encoding='utf-8') as f:
        f.write("\n".join(out))

if __name__ == "__main__":
    generate_codec_tests()
    generate_digest_tests()
