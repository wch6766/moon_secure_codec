///|
/// A dependency record used to audit an SBOM-like manifest.
pub(all) struct Dependency {
  name : String
  version : String
  license : String
  source : String
  digest : String
}

///|
/// License and provenance policy for release dependency audits.
pub(all) struct LicensePolicy {
  allowed_licenses : Array[String]
  require_source : Bool
  require_digest : Bool
  allow_unknown_version : Bool
}

///|
/// A dependency audit result with actionable findings.
pub(all) struct DependencyAudit {
  dependencies_checked : Int
  findings : Array[AuditFinding]
}

///|
/// Construct a strict policy suitable for a published package.
pub fn LicensePolicy::strict(allowed_licenses : Array[String]) -> LicensePolicy {
  {
    allowed_licenses,
    require_source: true,
    require_digest: true,
    allow_unknown_version: false,
  }
}

///|
/// Construct a permissive policy for local development while retaining warnings.
pub fn LicensePolicy::development() -> LicensePolicy {
  {
    allowed_licenses: [],
    require_source: false,
    require_digest: false,
    allow_unknown_version: true,
  }
}

///|
/// Audit dependency metadata independently from file integrity.
pub fn audit_dependencies(
  dependencies : Array[Dependency],
  policy : LicensePolicy,
) -> DependencyAudit {
  let findings : Array[AuditFinding] = []
  let seen_names : Array[String] = []
  for dependency in dependencies {
    audit_dependency_name(dependency, seen_names, findings)
    audit_dependency_version(dependency, policy, findings)
    audit_dependency_license(dependency, policy, findings)
    audit_dependency_provenance(dependency, policy, findings)
    seen_names.push(dependency.name)
  }
  { dependencies_checked: dependencies.length(), findings }
}

///|
/// Return whether the dependency audit has a blocking finding.
pub fn DependencyAudit::has_errors(self : DependencyAudit) -> Bool {
  for finding in self.findings {
    if finding.severity == AuditSeverity::Error {
      return true
    }
  }
  false
}

///|
/// Count dependency findings by severity.
pub fn DependencyAudit::count(
  self : DependencyAudit,
  severity : AuditSeverity,
) -> Int {
  let mut count = 0
  for finding in self.findings {
    if finding.severity == severity {
      count = count + 1
    }
  }
  count
}

///|
fn audit_dependency_name(
  dependency : Dependency,
  seen : Array[String],
  findings : Array[AuditFinding],
) -> Unit {
  if dependency.name.length() == 0 {
    findings.push({
      code: "DEPENDENCY_NAME_EMPTY",
      severity: AuditSeverity::Error,
      path: "<dependency>",
      message: "dependency name is empty",
      remediation: "use the canonical package or module identifier",
    })
  }
  for old_name in seen {
    if old_name == dependency.name {
      findings.push({
        code: "DEPENDENCY_DUPLICATE",
        severity: AuditSeverity::Warning,
        path: dependency.name,
        message: "dependency appears more than once",
        remediation: "merge records and keep one reviewed version",
      })
      return
    }
  }
}

///|
fn audit_dependency_version(
  dependency : Dependency,
  policy : LicensePolicy,
  findings : Array[AuditFinding],
) -> Unit {
  if dependency.version.length() == 0 {
    let severity = if policy.allow_unknown_version {
      AuditSeverity::Warning
    } else {
      AuditSeverity::Error
    }
    findings.push({
      code: "DEPENDENCY_VERSION_UNKNOWN",
      severity,
      path: dependency.name,
      message: "dependency version is missing",
      remediation: "pin an immutable release or commit identifier",
    })
  }
}

///|
fn audit_dependency_license(
  dependency : Dependency,
  policy : LicensePolicy,
  findings : Array[AuditFinding],
) -> Unit {
  if dependency.license.length() == 0 {
    findings.push({
      code: "LICENSE_UNKNOWN",
      severity: AuditSeverity::Error,
      path: dependency.name,
      message: "dependency license is not declared",
      remediation: "verify the upstream license and record it in the SBOM",
    })
    return
  }
  if policy.allowed_licenses.length() > 0 &&
    !contains_string(policy.allowed_licenses, dependency.license) {
    findings.push({
      code: "LICENSE_NOT_ALLOWED",
      severity: AuditSeverity::Error,
      path: dependency.name,
      message: "dependency license is outside the configured allow-list",
      remediation: "obtain legal review or replace the dependency",
    })
  }
}

///|
fn audit_dependency_provenance(
  dependency : Dependency,
  policy : LicensePolicy,
  findings : Array[AuditFinding],
) -> Unit {
  if policy.require_source && dependency.source.length() == 0 {
    findings.push({
      code: "SOURCE_MISSING",
      severity: AuditSeverity::Error,
      path: dependency.name,
      message: "dependency source location is missing",
      remediation: "record the authoritative upstream repository or registry URL",
    })
  }
  if policy.require_digest && !is_lower_hex(dependency.digest) {
    findings.push({
      code: "DEPENDENCY_DIGEST_MISSING",
      severity: AuditSeverity::Error,
      path: dependency.name,
      message: "dependency digest is missing or not lowercase hexadecimal",
      remediation: "record a content digest for reproducible dependency resolution",
    })
  }
}

///|
fn contains_string(values : Array[String], target : String) -> Bool {
  for value in values {
    if value == target {
      return true
    }
  }
  false
}
