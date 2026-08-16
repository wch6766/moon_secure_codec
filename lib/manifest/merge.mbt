///|
/// Merge two manifests while keeping the newer snapshot for duplicate paths.
/// The operation is deterministic: the left manifest's order is retained and
/// new paths from the right manifest are appended in their original order.
pub fn Manifest::merge(self : Manifest, other : Manifest) -> Manifest {
  let merged : Array[FileSnapshot] = []
  for file in self.files {
    merged.push(file)
  }
  for incoming in other.files {
    let mut replaced = false
    for i = 0; i < merged.length(); i = i + 1 {
      if merged[i].path == incoming.path {
        merged[i] = incoming
        replaced = true
        break
      }
    }
    if !replaced {
      merged.push(incoming)
    }
  }
  Manifest::new(self.name, other.version, other.created_at, merged)
}

///|
/// Return a manifest containing only changed files from a diff.
pub fn ManifestDiff::changed_files(self : ManifestDiff) -> Array[FileSnapshot] {
  let result : Array[FileSnapshot] = []
  for file in self.added {
    result.push(file)
  }
  for file in self.modified {
    result.push(file)
  }
  result
}

///|
/// Return true when two snapshots have identical cryptographic content.
pub fn snapshots_equal(left : FileSnapshot, right : FileSnapshot) -> Bool {
  left.size == right.size && left.hash_sha256 == right.hash_sha256
}

///|
/// Return true when every file in the manifest has a valid SHA-256 record.
pub fn Manifest::has_complete_digests(self : Manifest) -> Bool {
  for file in self.files {
    if file.hash_sha256.length() != 64 {
      return false
    }
  }
  true
}

///|
/// Return all paths in a diff that were removed from the newer release.
pub fn ManifestDiff::removed_paths(self : ManifestDiff) -> Array[String] {
  let result : Array[String] = []
  for file in self.removed {
    result.push(file.path)
  }
  result
}

///|
/// Validate that all snapshot paths are unique without creating a full report.
pub fn Manifest::has_unique_paths(self : Manifest) -> Bool {
  for i = 0; i < self.files.length(); i = i + 1 {
    for j = i + 1; j < self.files.length(); j = j + 1 {
      if self.files[i].path == self.files[j].path {
        return false
      }
    }
  }
  true
}
