///|
/// Release policy for CI and package publication gates.
pub(all) struct ReleasePolicy {
  max_files : Int
  max_total_bytes : Int64
  required_paths : Array[String]
  allowed_extensions : Array[String]
  max_file_bytes : Int64
  reject_generated : Bool
}

///|
/// Construct a conservative release policy for source packages.
pub fn ReleasePolicy::source_package() -> ReleasePolicy {
  {
    max_files: 10000,
    max_total_bytes: 100_000_000L,
    required_paths: ["README.md", "LICENSE", "moon.mod"],
    allowed_extensions: [
      ".mbt", ".mbti", ".md", ".toml", ".json", ".yml", ".yaml", "LICENSE", "moon.mod",
    ],
    max_file_bytes: 10_000_000L,
    reject_generated: true,
  }
}

///|
/// Validate a manifest against a release policy and append policy findings.
pub fn Manifest::release_check(
  self : Manifest,
  policy : ReleasePolicy,
) -> AuditReport {
  let base = self.audit_with_policy(
    policy.allowed_extensions,
    policy.max_file_bytes,
  )
  let findings = base.findings
  let stats = self.statistics()
  if self.files.length() > policy.max_files {
    findings.push({
      code: "RELEASE_FILE_COUNT",
      severity: AuditSeverity::Error,
      path: "<manifest>",
      message: "release contains more files than the configured limit",
      remediation: "remove accidental artifacts or update the reviewed policy",
    })
  }
  if stats.total_bytes > policy.max_total_bytes {
    findings.push({
      code: "RELEASE_TOTAL_SIZE",
      severity: AuditSeverity::Error,
      path: "<manifest>",
      message: "release exceeds the configured total size limit",
      remediation: "exclude build caches and large unrelated assets",
    })
  }
  for required in policy.required_paths {
    if self.find(required) is None {
      findings.push({
        code: "REQUIRED_FILE_MISSING",
        severity: AuditSeverity::Error,
        path: required,
        message: "required release file is missing",
        remediation: "add the file before creating a release manifest",
      })
    }
  }
  if policy.reject_generated {
    for file in self.files {
      if is_release_generated(file.path) {
        findings.push({
          code: "GENERATED_FILE_REJECTED",
          severity: AuditSeverity::Error,
          path: file.path,
          message: "generated or build output is not permitted by this release policy",
          remediation: "publish source inputs or explicitly document the generated artifact",
        })
      }
    }
  }
  { findings, files_checked: base.files_checked, total_bytes: base.total_bytes }
}

///|
/// Return a compact policy result suitable for a CI exit decision.
pub fn Manifest::is_release_ready(
  self : Manifest,
  policy : ReleasePolicy,
) -> Bool {
  !self.release_check(policy).has_errors()
}

///|
/// Validate a manifest against the default source-package policy.
pub fn Manifest::is_source_release_ready(self : Manifest) -> Bool {
  self.is_release_ready(ReleasePolicy::source_package())
}

///|
/// Return paths that are missing from a required-path list.
pub fn Manifest::missing_paths(
  self : Manifest,
  required : Array[String],
) -> Array[String] {
  let missing : Array[String] = []
  for path in required {
    if self.find(path) is None {
      missing.push(path)
    }
  }
  missing
}

///|
/// Return true when a manifest contains no files rejected by a policy.
pub fn Manifest::contains_only_extensions(
  self : Manifest,
  allowed : Array[String],
) -> Bool {
  for file in self.files {
    if !release_extension_allowed(file.path, allowed) {
      return false
    }
  }
  true
}

///|
fn is_release_generated(path : String) -> Bool {
  release_ends_with(path, ".wasm") ||
  release_ends_with(path, ".map") ||
  release_ends_with(path, ".mbti") ||
  release_starts_with(path, "_build/") ||
  release_starts_with(path, "target/")
}

///|
fn release_extension_allowed(path : String, allowed : Array[String]) -> Bool {
  for extension in allowed {
    if release_ends_with(path, extension) {
      return true
    }
  }
  allowed.length() == 0
}

///|
fn release_starts_with(value : String, prefix : String) -> Bool {
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
fn release_ends_with(value : String, suffix : String) -> Bool {
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
