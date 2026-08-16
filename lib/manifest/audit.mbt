///|
/// Severity assigned to a manifest audit finding.
pub(all) enum AuditSeverity {
  Info
  Warning
  Error
} derive(Debug, Eq)

///|
/// A deterministic, machine-readable audit finding.
pub(all) struct AuditFinding {
  code : String
  severity : AuditSeverity
  path : String
  message : String
  remediation : String
}

///|
/// Result of validating a manifest against structural and supply-chain rules.
pub(all) struct AuditReport {
  findings : Array[AuditFinding]
  files_checked : Int
  total_bytes : Int64
}

///|
/// Return true when the report contains a blocking finding.
pub fn AuditReport::has_errors(self : AuditReport) -> Bool {
  for finding in self.findings {
    if finding.severity == AuditSeverity::Error {
      return true
    }
  }
  false
}

///|
/// Count findings at a given severity.
pub fn AuditReport::count(self : AuditReport, severity : AuditSeverity) -> Int {
  let mut result = 0
  for finding in self.findings {
    if finding.severity == severity {
      result = result + 1
    }
  }
  result
}

///|
/// Format the report as stable text suitable for CI logs.
pub fn AuditReport::to_text(self : AuditReport) -> String {
  let out = StringBuilder::new()
  out.write_string("files_checked=" + self.files_checked.to_string() + "\n")
  out.write_string("total_bytes=" + self.total_bytes.to_string() + "\n")
  out.write_string(
    "errors=" + self.count(AuditSeverity::Error).to_string() + "\n",
  )
  out.write_string(
    "warnings=" + self.count(AuditSeverity::Warning).to_string() + "\n",
  )
  for finding in self.findings {
    out.write_string(
      "[" +
      severity_name(finding.severity) +
      "] " +
      finding.code +
      " " +
      finding.path +
      ": " +
      finding.message +
      " -> " +
      finding.remediation +
      "\n",
    )
  }
  out.to_string()
}

///|
/// Return the findings in insertion order for integrations that need structured data.
pub fn AuditReport::findings(self : AuditReport) -> Array[AuditFinding] {
  self.findings
}

///|
fn severity_name(severity : AuditSeverity) -> String {
  match severity {
    AuditSeverity::Info => "INFO"
    AuditSeverity::Warning => "WARNING"
    AuditSeverity::Error => "ERROR"
  }
}

///|
/// Validate a manifest using the default conservative supply-chain policy.
///
/// The policy rejects ambiguous paths, duplicate paths, malformed hashes, and
/// a stale Merkle root. It also warns about empty manifests and suspicious
/// generated/build files that should normally be excluded from a release.
pub fn Manifest::audit(self : Manifest) -> AuditReport {
  let findings : Array[AuditFinding] = []
  let mut total_bytes : Int64 = 0L
  let seen : Array[String] = []
  if self.files.length() == 0 {
    findings.push({
      code: "MANIFEST_EMPTY",
      severity: AuditSeverity::Warning,
      path: "<manifest>",
      message: "manifest contains no file snapshots",
      remediation: "include the release files that must be verified",
    })
  }
  for file in self.files {
    total_bytes = total_bytes + file.size
    audit_path(file, seen, findings)
    audit_hashes(file, findings)
    if has_generated_suffix(file.path) {
      findings.push({
        code: "GENERATED_ARTIFACT",
        severity: AuditSeverity::Warning,
        path: file.path,
        message: "path looks like a generated or build artifact",
        remediation: "record source inputs or exclude the artifact from the policy",
      })
    }
    seen.push(file.path)
  }
  if !self.verify_integrity() {
    findings.push({
      code: "MERKLE_ROOT_MISMATCH",
      severity: AuditSeverity::Error,
      path: "<manifest>",
      message: "stored Merkle root does not match the current file snapshots",
      remediation: "recompute the root after reviewing every changed snapshot",
    })
  }
  { findings, files_checked: self.files.length(), total_bytes }
}

///|
/// Apply a project-specific allow-list to file extensions and paths.
pub fn Manifest::audit_with_policy(
  self : Manifest,
  allowed_extensions : Array[String],
  max_file_size : Int64,
) -> AuditReport {
  let report = self.audit()
  let findings = report.findings
  for file in self.files {
    if file.size > max_file_size {
      findings.push({
        code: "FILE_TOO_LARGE",
        severity: AuditSeverity::Error,
        path: file.path,
        message: "file exceeds the configured size limit of " +
        max_file_size.to_string(),
        remediation: "split the artifact or raise the limit with an explicit review",
      })
    }
    if !extension_allowed(file.path, allowed_extensions) {
      findings.push({
        code: "EXTENSION_DENIED",
        severity: AuditSeverity::Warning,
        path: file.path,
        message: "file extension is outside the configured release policy",
        remediation: "review the file or add its extension to the allow-list",
      })
    }
  }
  {
    findings,
    files_checked: report.files_checked,
    total_bytes: report.total_bytes,
  }
}

///|
fn audit_path(
  file : FileSnapshot,
  seen : Array[String],
  findings : Array[AuditFinding],
) -> Unit {
  if file.path.length() == 0 {
    findings.push({
      code: "PATH_EMPTY",
      severity: AuditSeverity::Error,
      path: "<empty>",
      message: "snapshot path is empty",
      remediation: "provide a normalized repository-relative path",
    })
  }
  if is_absolute_path(file.path) || contains_parent_segment(file.path) {
    findings.push({
      code: "PATH_TRAVERSAL",
      severity: AuditSeverity::Error,
      path: file.path,
      message: "snapshot path is absolute or escapes the repository root",
      remediation: "use a normalized relative path without '..' segments",
    })
  }
  if contains_backslash(file.path) {
    findings.push({
      code: "PATH_NOT_PORTABLE",
      severity: AuditSeverity::Warning,
      path: file.path,
      message: "backslash makes the manifest platform-dependent",
      remediation: "store paths with '/' regardless of the host operating system",
    })
  }
  for old_path in seen {
    if old_path == file.path {
      findings.push({
        code: "PATH_DUPLICATE",
        severity: AuditSeverity::Error,
        path: file.path,
        message: "more than one snapshot uses the same path",
        remediation: "deduplicate the manifest before publishing it",
      })
      return
    }
  }
}

///|
fn audit_hashes(file : FileSnapshot, findings : Array[AuditFinding]) -> Unit {
  if file.size < 0L {
    findings.push({
      code: "SIZE_NEGATIVE",
      severity: AuditSeverity::Error,
      path: file.path,
      message: "snapshot size cannot be negative",
      remediation: "recreate the snapshot from the original bytes",
    })
  }
  if file.hash_sha256.length() != 64 || !is_lower_hex(file.hash_sha256) {
    findings.push({
      code: "SHA256_MALFORMED",
      severity: AuditSeverity::Error,
      path: file.path,
      message: "SHA-256 must be exactly 64 lowercase hexadecimal characters",
      remediation: "recompute the SHA-256 digest using the canonical encoder",
    })
  }
}

///|
fn is_absolute_path(path : String) -> Bool {
  if path.length() == 0 {
    false
  } else {
    path[0] == '/'.to_int().to_uint16() ||
    path[0] == '\\'.to_int().to_uint16() ||
    (path.length() > 1 && path[1] == ':'.to_int().to_uint16())
  }
}

///|
fn contains_backslash(path : String) -> Bool {
  for c in path {
    if c == '\\' {
      return true
    }
  }
  false
}

///|
fn contains_parent_segment(path : String) -> Bool {
  let normalized = replace_backslash(path)
  if normalized == ".." ||
    starts_with(normalized, "../") ||
    ends_with(normalized, "/..") {
    return true
  }
  for i = 0; i + 3 < normalized.length(); i = i + 1 {
    if normalized[i] == '/'.to_int().to_uint16() &&
      normalized[i + 1] == '.'.to_int().to_uint16() &&
      normalized[i + 2] == '.'.to_int().to_uint16() &&
      normalized[i + 3] == '/'.to_int().to_uint16() {
      return true
    }
  }
  false
}

///|
fn replace_backslash(path : String) -> String {
  let out = StringBuilder::new()
  for c in path {
    if c == '\\' {
      out.write_char('/')
    } else {
      out.write_char(c)
    }
  }
  out.to_string()
}

///|
fn starts_with(value : String, prefix : String) -> Bool {
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
fn ends_with(value : String, suffix : String) -> Bool {
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

///|
fn is_lower_hex(value : String) -> Bool {
  for c in value {
    if !((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')) {
      return false
    }
  }
  true
}

///|
fn has_generated_suffix(path : String) -> Bool {
  ends_with(path, ".wasm") ||
  ends_with(path, ".map") ||
  ends_with(path, ".mbti") ||
  starts_with(path, "_build/") ||
  starts_with(path, "target/")
}

///|
fn extension_allowed(path : String, allowed : Array[String]) -> Bool {
  for extension in allowed {
    if ends_with(path, extension) {
      return true
    }
  }
  allowed.length() == 0
}
