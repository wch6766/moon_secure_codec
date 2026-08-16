///|
/// Aggregate release statistics derived from a manifest.
pub(all) struct ManifestStatistics {
  file_count : Int
  total_bytes : Int64
  largest_path : String
  largest_bytes : Int64
  sha256_count : Int
  generated_count : Int
}

///|
/// Calculate deterministic statistics without reading the original files again.
pub fn Manifest::statistics(self : Manifest) -> ManifestStatistics {
  let mut total_bytes : Int64 = 0L
  let mut largest_path = ""
  let mut largest_bytes : Int64 = -1L
  let mut sha256_count = 0
  let mut generated_count = 0
  for file in self.files {
    total_bytes = total_bytes + file.size
    if file.size > largest_bytes {
      largest_bytes = file.size
      largest_path = file.path
    }
    if file.hash_sha256.length() == 64 {
      sha256_count = sha256_count + 1
    }
    if report_has_suffix(file.path) {
      generated_count = generated_count + 1
    }
  }
  {
    file_count: self.files.length(),
    total_bytes,
    largest_path,
    largest_bytes,
    sha256_count,
    generated_count,
  }
}

///|
/// Return a stable human-readable summary for release notes and CI artifacts.
pub fn Manifest::summary(self : Manifest) -> String {
  let stats = self.statistics()
  let out = StringBuilder::new()
  out.write_string("name=" + self.name + "\n")
  out.write_string("version=" + self.version + "\n")
  out.write_string("created_at=" + self.created_at + "\n")
  out.write_string("merkle_root=" + self.merkle_root + "\n")
  out.write_string("files=" + stats.file_count.to_string() + "\n")
  out.write_string("bytes=" + stats.total_bytes.to_string() + "\n")
  out.write_string("largest=" + stats.largest_path + "\n")
  out.write_string("largest_bytes=" + stats.largest_bytes.to_string() + "\n")
  out.write_string("sha256_records=" + stats.sha256_count.to_string() + "\n")
  out.write_string(
    "generated_records=" + stats.generated_count.to_string() + "\n",
  )
  out.to_string()
}

///|
/// Find a snapshot by exact repository-relative path.
pub fn Manifest::find(self : Manifest, path : String) -> FileSnapshot? {
  for file in self.files {
    if file.path == path {
      return Some(file)
    }
  }
  None
}

///|
/// Return all snapshots whose path begins with a normalized directory prefix.
pub fn Manifest::files_under(
  self : Manifest,
  directory : String,
) -> Array[FileSnapshot] {
  let prefix = if ends_with_report(directory, "/") {
    directory
  } else {
    directory + "/"
  }
  let result : Array[FileSnapshot] = []
  for file in self.files {
    if starts_with_report(file.path, prefix) {
      result.push(file)
    }
  }
  result
}

///|
/// Return a copy containing only files under the requested directory.
pub fn Manifest::submanifest(self : Manifest, directory : String) -> Manifest {
  let files = self.files_under(directory)
  Manifest::new(self.name, self.version, self.created_at, files)
}

///|
/// Format a diff in a stable form suitable for a change review.
pub fn ManifestDiff::summary(self : ManifestDiff) -> String {
  let out = StringBuilder::new()
  out.write_string("added=" + self.added.length().to_string() + "\n")
  for file in self.added {
    out.write_string("+ " + file.path + "\n")
  }
  out.write_string("modified=" + self.modified.length().to_string() + "\n")
  for file in self.modified {
    out.write_string("~ " + file.path + "\n")
  }
  out.write_string("removed=" + self.removed.length().to_string() + "\n")
  for file in self.removed {
    out.write_string("- " + file.path + "\n")
  }
  out.to_string()
}

///|
/// Return true if two manifests differ in any file content or path.
pub fn ManifestDiff::has_changes(self : ManifestDiff) -> Bool {
  self.added.length() > 0 ||
  self.removed.length() > 0 ||
  self.modified.length() > 0
}

///|
fn report_has_suffix(path : String) -> Bool {
  ends_with_report(path, ".wasm") ||
  ends_with_report(path, ".map") ||
  ends_with_report(path, ".mbti") ||
  starts_with_report(path, "_build/") ||
  starts_with_report(path, "target/")
}

///|
fn starts_with_report(value : String, prefix : String) -> Bool {
  if value.length() < prefix.length() {
    return false
  }
  for i = 0; i < prefix.length(); i = i + 1 {
    if value[i] != prefix[i] {
      return false
    }
  }
  true
}

///|
fn ends_with_report(value : String, suffix : String) -> Bool {
  if value.length() < suffix.length() {
    return false
  }
  let offset = value.length() - suffix.length()
  for i = 0; i < suffix.length(); i = i + 1 {
    if value[offset + i] != suffix[i] {
      return false
    }
  }
  true
}
