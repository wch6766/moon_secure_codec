///|
/// Represents a snapshot of a file or software dependency in the supply chain.
pub(all) struct FileSnapshot {
  path : String
  size : Int64
  hash_xx64 : UInt64
  hash_sha256 : String
}

///|
/// A Software Supply Chain Manifest (SBOM / Snapshot) with embedded Merkle root.
pub(all) struct Manifest {
  name : String
  version : String
  created_at : String
  files : Array[FileSnapshot]
  mut merkle_root : String
}

///|
/// Represents differences discovered between two supply chain manifests.
pub(all) struct ManifestDiff {
  added : Array[FileSnapshot]
  removed : Array[FileSnapshot]
  modified : Array[FileSnapshot]
}

///|
/// Construct a FileSnapshot by inspecting raw file contents.
pub fn FileSnapshot::from_bytes(path : String, data : Bytes) -> FileSnapshot {
  let size = data.length().to_int64()
  let hash_xx64 = @digest.xxhash64(data)
  let hash_sha256 = @digest.sha256_hex(data)
  { path, size, hash_xx64, hash_sha256 }
}

///|
/// Serialize a FileSnapshot to a canonical byte representation for Merkle tree hashing.
pub fn FileSnapshot::canonical_bytes(self : FileSnapshot) -> Bytes {
  let s = self.path + ":" + self.size.to_string() + ":" + self.hash_xx64.to_string() + ":" + self.hash_sha256
  let buf : Array[Byte] = []
  for i = 0; i < s.length(); i = i + 1 {
    buf.push(s[i].to_int().to_byte())
  }
  Bytes::from_array(buf)
}

///|
/// Construct a new supply chain Manifest and automatically compute its Merkle root.
pub fn Manifest::new(
  name : String,
  version : String,
  created_at : String,
  files : Array[FileSnapshot]
) -> Manifest {
  let manifest = { name, version, created_at, files, merkle_root: "" }
  manifest.refresh_merkle_root()
  manifest
}

///|
/// Compute the Merkle tree for all files in this manifest.
pub fn Manifest::compute_merkle_tree(self : Manifest) -> @merkle.MerkleTree {
  let leaves : Array[Bytes] = []
  for i = 0; i < self.files.length(); i = i + 1 {
    leaves.push(self.files[i].canonical_bytes())
  }
  @merkle.MerkleTree::new(leaves)
}

///|
/// Recalculate and update the merkle_root property of the manifest.
pub fn Manifest::refresh_merkle_root(self : Manifest) -> Unit {
  let tree = self.compute_merkle_tree()
  self.merkle_root = tree.root_hex()
}

///|
/// Verify whether the files currently in the manifest match the stored Merkle root.
pub fn Manifest::verify_integrity(self : Manifest) -> Bool {
  let tree = self.compute_merkle_tree()
  tree.root_hex() == self.merkle_root
}

///|
/// Serialize the Manifest into a human and machine readable JSON string.
pub fn Manifest::to_json_string(self : Manifest) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")
  buf.write_string("  \"name\": \"" + escape_json(self.name) + "\",\n")
  buf.write_string("  \"version\": \"" + escape_json(self.version) + "\",\n")
  buf.write_string("  \"created_at\": \"" + escape_json(self.created_at) + "\",\n")
  buf.write_string("  \"merkle_root\": \"" + escape_json(self.merkle_root) + "\",\n")
  buf.write_string("  \"files\": [\n")
  for i = 0; i < self.files.length(); i = i + 1 {
    let f = self.files[i]
    buf.write_string("    {\n")
    buf.write_string("      \"path\": \"" + escape_json(f.path) + "\",\n")
    buf.write_string("      \"size\": " + f.size.to_string() + ",\n")
    buf.write_string("      \"hash_xx64\": " + f.hash_xx64.to_string() + ",\n")
    buf.write_string("      \"hash_sha256\": \"" + escape_json(f.hash_sha256) + "\"\n")
    if i + 1 < self.files.length() {
      buf.write_string("    },\n")
    } else {
      buf.write_string("    }\n")
    }
  }
  buf.write_string("  ]\n")
  buf.write_string("}")
  buf.to_string()
}

///|
fn escape_json(s : String) -> String {
  let buf = StringBuilder::new()
  for i = 0; i < s.length(); i = i + 1 {
    let ci = s[i].to_int()
    if ci == '"'.to_int() {
      buf.write_string("\\\"")
    } else if ci == '\\'.to_int() {
      buf.write_string("\\\\")
    } else {
      buf.write_char(ci.unsafe_to_char())
    }
  }
  buf.to_string()
}

///|
/// Compare two manifests (`self` as old/baseline, `other` as new) to find added, removed, and modified files.
pub fn Manifest::diff(self : Manifest, other : Manifest) -> ManifestDiff {
  let added : Array[FileSnapshot] = []
  let removed : Array[FileSnapshot] = []
  let modified : Array[FileSnapshot] = []

  for i = 0; i < self.files.length(); i = i + 1 {
    let f_old = self.files[i]
    match find_file_by_path(other.files, f_old.path) {
      Some(f_new) => {
        if f_old.hash_sha256 != f_new.hash_sha256 || f_old.size != f_new.size {
          modified.push(f_new)
        }
      }
      None => removed.push(f_old)
    }
  }

  for i = 0; i < other.files.length(); i = i + 1 {
    let f_new = other.files[i]
    match find_file_by_path(self.files, f_new.path) {
      Some(_) => ()
      None => added.push(f_new)
    }
  }

  { added, removed, modified }
}

///|
fn find_file_by_path(files : Array[FileSnapshot], path : String) -> FileSnapshot? {
  for i = 0; i < files.length(); i = i + 1 {
    if files[i].path == path {
      return Some(files[i])
    }
  }
  None
}
