///|
/// The kind of evidence attached to a release review.
pub(all) enum EvidenceKind {
  Source
  Dependency
  Build
  Test
  Review
} derive(Debug, Eq)

///|
/// A single, content-addressed release evidence record.
pub(all) struct EvidenceRecord {
  id : String
  kind : EvidenceKind
  subject : String
  digest : String
  observed_at : String
  note : String
}

///|
/// A deterministic evidence bundle bound to one manifest root.
pub(all) struct EvidenceBundle {
  name : String
  version : String
  manifest_root : String
  records : Array[EvidenceRecord]
  mut bundle_digest : String
}

///|
/// Construct one evidence record. `digest` should be a lowercase SHA-256 hex
/// digest of the referenced artifact, log, or review material.
pub fn EvidenceRecord::new(
  id : String,
  kind : EvidenceKind,
  subject : String,
  digest : String,
  observed_at : String,
  note : String,
) -> EvidenceRecord {
  { id, kind, subject, digest, observed_at, note }
}

///|
/// Return the stable wire name used for an evidence kind.
pub fn EvidenceKind::to_text(self : EvidenceKind) -> String {
  match self {
    EvidenceKind::Source => "source"
    EvidenceKind::Dependency => "dependency"
    EvidenceKind::Build => "build"
    EvidenceKind::Test => "test"
    EvidenceKind::Review => "review"
  }
}

///|
/// Validate fields before an evidence record is included in a bundle.
pub fn EvidenceRecord::is_valid(self : EvidenceRecord) -> Bool {
  self.id.length() > 0 &&
  self.subject.length() > 0 &&
  self.observed_at.length() > 0 &&
  valid_evidence_text(self.id) &&
  valid_evidence_text(self.subject) &&
  valid_evidence_text(self.observed_at) &&
  valid_evidence_text(self.note) &&
  valid_evidence_digest(self.digest)
}

///|
/// Serialize a record without a trailing newline for deterministic hashing.
pub fn EvidenceRecord::canonical_text(self : EvidenceRecord) -> String {
  self.id +
  "|" +
  self.kind.to_text() +
  "|" +
  self.subject +
  "|" +
  self.digest +
  "|" +
  self.observed_at +
  "|" +
  self.note
}

///|
/// Construct a bundle and calculate its digest immediately.
pub fn EvidenceBundle::new(
  name : String,
  version : String,
  manifest_root : String,
  records : Array[EvidenceRecord],
) -> EvidenceBundle {
  let bundle = { name, version, manifest_root, records, bundle_digest: "" }
  bundle.refresh_digest()
  bundle
}

///|
/// Construct evidence metadata directly from the manifest under review.
pub fn Manifest::evidence_bundle(
  self : Manifest,
  records : Array[EvidenceRecord],
) -> EvidenceBundle {
  EvidenceBundle::new(self.name, self.version, self.merkle_root, records)
}

///|
/// Return the records in insertion order for audit integrations.
pub fn EvidenceBundle::records(self : EvidenceBundle) -> Array[EvidenceRecord] {
  self.records
}

///|
/// Return the number of evidence records in the bundle.
pub fn EvidenceBundle::record_count(self : EvidenceBundle) -> Int {
  self.records.length()
}

///|
/// Append one record and refresh the bundle digest.
pub fn EvidenceBundle::add(
  self : EvidenceBundle,
  record : EvidenceRecord,
) -> Unit {
  self.records.push(record)
  self.refresh_digest()
}

///|
/// Find an evidence record by its stable identifier.
pub fn EvidenceBundle::find(
  self : EvidenceBundle,
  id : String,
) -> EvidenceRecord? {
  for record in self.records {
    if record.id == id {
      return Some(record)
    }
  }
  None
}

///|
/// Return true when at least one record of the requested kind is present.
pub fn EvidenceBundle::has_kind(
  self : EvidenceBundle,
  kind : EvidenceKind,
) -> Bool {
  for record in self.records {
    if record.kind == kind {
      return true
    }
  }
  false
}

///|
/// Count records belonging to one evidence kind.
pub fn EvidenceBundle::count_kind(
  self : EvidenceBundle,
  kind : EvidenceKind,
) -> Int {
  let mut count = 0
  for record in self.records {
    if record.kind == kind {
      count = count + 1
    }
  }
  count
}

///|
/// Return which required evidence kinds are absent.
pub fn EvidenceBundle::missing_kinds(
  self : EvidenceBundle,
  required : Array[EvidenceKind],
) -> Array[EvidenceKind] {
  let missing : Array[EvidenceKind] = []
  for kind in required {
    if !self.has_kind(kind) {
      missing.push(kind)
    }
  }
  missing
}

///|
/// The conservative evidence set expected for a public release.
pub fn release_evidence_kinds() -> Array[EvidenceKind] {
  [
    EvidenceKind::Source,
    EvidenceKind::Dependency,
    EvidenceKind::Build,
    EvidenceKind::Test,
    EvidenceKind::Review,
  ]
}

///|
/// Return true only when all standard release evidence is present.
pub fn EvidenceBundle::is_complete(self : EvidenceBundle) -> Bool {
  self.missing_kinds(release_evidence_kinds()).length() == 0
}

///|
/// Return true when the bundle names the exact manifest being reviewed.
pub fn EvidenceBundle::binds_to(
  self : EvidenceBundle,
  manifest : Manifest,
) -> Bool {
  self.name == manifest.name &&
  self.version == manifest.version &&
  self.manifest_root == manifest.merkle_root
}

///|
/// Return the canonical header and record lines used for hashing.
pub fn EvidenceBundle::canonical_text(self : EvidenceBundle) -> String {
  let out = StringBuilder::new()
  out.write_string("name=" + self.name + "\n")
  out.write_string("version=" + self.version + "\n")
  out.write_string("manifest_root=" + self.manifest_root + "\n")
  for record in self.records {
    out.write_string("record=" + record.canonical_text() + "\n")
  }
  out.to_string()
}

///|
/// Recompute and store the SHA-256 digest of the canonical evidence text.
pub fn EvidenceBundle::refresh_digest(self : EvidenceBundle) -> Unit {
  self.bundle_digest = @digest.sha256_hex(
    evidence_string_bytes(self.canonical_text()),
  )
}

///|
/// Return the stored digest of the evidence bundle.
pub fn EvidenceBundle::digest(self : EvidenceBundle) -> String {
  self.bundle_digest
}

///|
/// Verify digest, record validity, duplicate IDs, and manifest binding data.
pub fn EvidenceBundle::verify(self : EvidenceBundle) -> Bool {
  let duplicate_ids = self.duplicate_ids()
  if duplicate_ids.length() > 0 {
    return false
  }
  for record in self.records {
    if !record.is_valid() {
      return false
    }
  }
  valid_evidence_digest(self.manifest_root) &&
  self.bundle_digest ==
  @digest.sha256_hex(evidence_string_bytes(self.canonical_text()))
}

///|
/// Return duplicate record identifiers in first-seen order.
pub fn EvidenceBundle::duplicate_ids(self : EvidenceBundle) -> Array[String] {
  let seen : Array[String] = []
  let duplicates : Array[String] = []
  for record in self.records {
    if array_contains_string(seen, record.id) {
      if !array_contains_string(duplicates, record.id) {
        duplicates.push(record.id)
      }
    } else {
      seen.push(record.id)
    }
  }
  duplicates
}

///|
/// Format a compact audit summary suitable for a CI artifact.
pub fn EvidenceBundle::to_text(self : EvidenceBundle) -> String {
  let out = StringBuilder::new()
  out.write_string("name=" + self.name + "\n")
  out.write_string("version=" + self.version + "\n")
  out.write_string("manifest_root=" + self.manifest_root + "\n")
  out.write_string("records=" + self.records.length().to_string() + "\n")
  out.write_string("complete=" + self.is_complete().to_string() + "\n")
  out.write_string("valid=" + self.verify().to_string() + "\n")
  out.write_string("bundle_digest=" + self.bundle_digest + "\n")
  out.to_string()
}

///|
fn evidence_string_bytes(value : String) -> Bytes {
  let bytes : Array[Byte] = []
  for i = 0; i < value.length(); i = i + 1 {
    bytes.push(value[i].to_int().to_byte())
  }
  Bytes::from_array(bytes)
}

///|
fn valid_evidence_text(value : String) -> Bool {
  for i = 0; i < value.length(); i = i + 1 {
    if value[i] == '|' || value[i] == '\n' || value[i] == '\r' {
      return false
    }
  }
  true
}

///|
fn valid_evidence_digest(value : String) -> Bool {
  if value.length() != 64 {
    return false
  }
  for i = 0; i < value.length(); i = i + 1 {
    let c = value[i]
    if !((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')) {
      return false
    }
  }
  true
}

///|
fn array_contains_string(values : Array[String], target : String) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}
