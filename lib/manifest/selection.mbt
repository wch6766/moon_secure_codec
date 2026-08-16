///|
/// A deterministic selection of manifest entries for incremental verification.
pub(all) struct ManifestSelection {
  files : Array[FileSnapshot]
  total_bytes : Int64
  source_manifest_root : String
}

///|
/// Select files below a repository-relative directory.
pub fn Manifest::select_directory(
  self : Manifest,
  directory : String,
) -> ManifestSelection {
  let selected = self.files_under(directory)
  selection_from_files(selected, self.merkle_root)
}

///|
/// Select files whose paths end in one of the supplied suffixes.
pub fn Manifest::select_suffixes(
  self : Manifest,
  suffixes : Array[String],
) -> ManifestSelection {
  let selected : Array[FileSnapshot] = []
  for file in self.files {
    if has_any_suffix(file.path, suffixes) {
      selected.push(file)
    }
  }
  selection_from_files(selected, self.merkle_root)
}

///|
/// Select a bounded batch for parallel or resumable verification.
pub fn Manifest::select_batch(
  self : Manifest,
  start : Int,
  limit : Int,
) -> Result[ManifestSelection, String] {
  if start < 0 || limit < 0 {
    return Err("Selection range cannot be negative")
  }
  if start > self.files.length() {
    return Err("Selection start is out of bounds")
  }
  let end = if start + limit > self.files.length() {
    self.files.length()
  } else {
    start + limit
  }
  let selected : Array[FileSnapshot] = []
  for i = start; i < end; i = i + 1 {
    selected.push(self.files[i])
  }
  Ok(selection_from_files(selected, self.merkle_root))
}

///|
/// Return true if a selection is empty.
pub fn ManifestSelection::is_empty(self : ManifestSelection) -> Bool {
  self.files.length() == 0
}

///|
/// Return the number of selected files.
pub fn ManifestSelection::file_count(self : ManifestSelection) -> Int {
  self.files.length()
}

///|
/// Return selected paths in stable manifest order.
pub fn ManifestSelection::paths(self : ManifestSelection) -> Array[String] {
  let paths : Array[String] = []
  for file in self.files {
    paths.push(file.path)
  }
  paths
}

///|
/// Compute a Merkle root over selected canonical file snapshots.
pub fn ManifestSelection::merkle_root(self : ManifestSelection) -> String {
  let leaves : Array[Bytes] = []
  for file in self.files {
    leaves.push(file.canonical_bytes())
  }
  @merkle.MerkleTree::new(leaves).root_hex()
}

///|
/// Verify that the selection still corresponds to the source manifest root.
pub fn ManifestSelection::source_is(
  self : ManifestSelection,
  manifest : Manifest,
) -> Bool {
  self.source_manifest_root == manifest.merkle_root
}

///|
/// Return a stable summary suitable for an incremental build log.
pub fn ManifestSelection::to_text(self : ManifestSelection) -> String {
  "files=" +
  self.file_count().to_string() +
  " bytes=" +
  self.total_bytes.to_string() +
  " root=" +
  self.merkle_root() +
  " source_root=" +
  self.source_manifest_root
}

///|
/// Find selected files by their exact SHA-256 digest.
pub fn ManifestSelection::with_sha256(
  self : ManifestSelection,
  digest : String,
) -> Array[FileSnapshot] {
  let result : Array[FileSnapshot] = []
  for file in self.files {
    if file.hash_sha256 == digest {
      result.push(file)
    }
  }
  result
}

///|
/// Return the largest selected file, if any.
pub fn ManifestSelection::largest(self : ManifestSelection) -> FileSnapshot? {
  if self.files.length() == 0 {
    return None
  }
  let mut largest = self.files[0]
  for i = 1; i < self.files.length(); i = i + 1 {
    if self.files[i].size > largest.size {
      largest = self.files[i]
    }
  }
  Some(largest)
}

///|
/// Return true when all selected snapshots have canonical digest records.
pub fn ManifestSelection::has_complete_digests(
  self : ManifestSelection,
) -> Bool {
  for file in self.files {
    if file.hash_sha256.length() != 64 {
      return false
    }
  }
  true
}

///|
/// Return a bounded sub-selection while preserving source-root provenance.
pub fn ManifestSelection::slice(
  self : ManifestSelection,
  start : Int,
  limit : Int,
) -> Result[ManifestSelection, String] {
  if start < 0 || limit < 0 || start > self.files.length() {
    return Err("Selection slice is out of bounds")
  }
  let end = if start + limit > self.files.length() {
    self.files.length()
  } else {
    start + limit
  }
  let selected : Array[FileSnapshot] = []
  for i = start; i < end; i = i + 1 {
    selected.push(self.files[i])
  }
  Ok(selection_from_files(selected, self.source_manifest_root))
}

///|
/// Select files at least as large as a configured threshold.
pub fn Manifest::select_large_files(
  self : Manifest,
  minimum_bytes : Int64,
) -> ManifestSelection {
  let selected : Array[FileSnapshot] = []
  for file in self.files {
    if file.size >= minimum_bytes {
      selected.push(file)
    }
  }
  selection_from_files(selected, self.merkle_root)
}

///|
/// Return whether a selection contains an exact path.
pub fn ManifestSelection::contains_path(
  self : ManifestSelection,
  path : String,
) -> Bool {
  for file in self.files {
    if file.path == path {
      return true
    }
  }
  false
}

///|
/// Return a selection containing only files with non-negative sizes.
pub fn ManifestSelection::valid_sizes(
  self : ManifestSelection,
) -> ManifestSelection {
  let selected : Array[FileSnapshot] = []
  for file in self.files {
    if file.size >= 0L {
      selected.push(file)
    }
  }
  selection_from_files(selected, self.source_manifest_root)
}

///|
/// Return the selected snapshot at an index without exposing the backing array.
pub fn ManifestSelection::at(
  self : ManifestSelection,
  index : Int,
) -> FileSnapshot? {
  if index < 0 || index >= self.files.length() {
    None
  } else {
    Some(self.files[index])
  }
}

///|
/// Return whether every selected path is unique.
pub fn ManifestSelection::has_unique_paths(self : ManifestSelection) -> Bool {
  for i = 0; i < self.files.length(); i = i + 1 {
    for j = i + 1; j < self.files.length(); j = j + 1 {
      if self.files[i].path == self.files[j].path {
        return false
      }
    }
  }
  true
}

///|
/// Return the inclusive total size range of selected files.
pub fn ManifestSelection::min_max_bytes(
  self : ManifestSelection,
) -> (Int64, Int64)? {
  if self.files.length() == 0 {
    return None
  }
  let mut minimum = self.files[0].size
  let mut maximum = self.files[0].size
  for i = 1; i < self.files.length(); i = i + 1 {
    if self.files[i].size < minimum {
      minimum = self.files[i].size
    }
    if self.files[i].size > maximum {
      maximum = self.files[i].size
    }
  }
  Some((minimum, maximum))
}

///|
/// Return whether the selection's byte total is zero.
pub fn ManifestSelection::is_zero_bytes(self : ManifestSelection) -> Bool {
  self.total_bytes == 0L
}

///|
fn selection_from_files(
  files : Array[FileSnapshot],
  source_manifest_root : String,
) -> ManifestSelection {
  let mut total_bytes : Int64 = 0L
  for file in files {
    total_bytes = total_bytes + file.size
  }
  { files, total_bytes, source_manifest_root }
}

///|
fn has_any_suffix(path : String, suffixes : Array[String]) -> Bool {
  for suffix in suffixes {
    if path.length() >= suffix.length() {
      let offset = path.length() - suffix.length()
      let mut matches = true
      for i = 0; i < suffix.length(); i = i + 1 {
        if path[offset + i] != suffix[i] {
          matches = false
          break
        }
      }
      if matches {
        return true
      }
    }
  }
  false
}
