///|
/// Release decision with counts that can be exported to CI or a dashboard.
pub(all) struct ReleaseDecision {
  ready : Bool
  risk_score : Int
  errors : Int
  warnings : Int
  checked_files : Int
  checked_bytes : Int64
}

///|
/// Convert a manifest audit report into an explicit release decision.
pub fn AuditReport::decision(self : AuditReport) -> ReleaseDecision {
  let errors = self.count(AuditSeverity::Error)
  let warnings = self.count(AuditSeverity::Warning)
  let risk_score = errors * 100 + warnings * 10
  {
    ready: errors == 0,
    risk_score,
    errors,
    warnings,
    checked_files: self.files_checked,
    checked_bytes: self.total_bytes,
  }
}

///|
/// Convert a policy check directly into a release decision.
pub fn Manifest::release_decision(
  self : Manifest,
  policy : ReleasePolicy,
) -> ReleaseDecision {
  self.release_check(policy).decision()
}

///|
/// Return true only when no warnings or errors remain.
pub fn ReleaseDecision::is_clean(self : ReleaseDecision) -> Bool {
  self.errors == 0 && self.warnings == 0
}

///|
/// Return an exit code suitable for a CI shell wrapper.
pub fn ReleaseDecision::exit_code(self : ReleaseDecision) -> Int {
  if self.errors > 0 {
    2
  } else if self.warnings > 0 {
    1
  } else {
    0
  }
}

///|
/// Return a compact stable line for a build summary.
pub fn ReleaseDecision::to_text(self : ReleaseDecision) -> String {
  "ready=" +
  self.ready.to_string() +
  " risk_score=" +
  self.risk_score.to_string() +
  " errors=" +
  self.errors.to_string() +
  " warnings=" +
  self.warnings.to_string() +
  " files=" +
  self.checked_files.to_string() +
  " bytes=" +
  self.checked_bytes.to_string()
}

///|
/// Return all error codes in insertion order.
pub fn AuditReport::error_codes(self : AuditReport) -> Array[String] {
  let result : Array[String] = []
  for finding in self.findings {
    if finding.severity == AuditSeverity::Error {
      result.push(finding.code)
    }
  }
  result
}

///|
/// Return true only when the report has no findings at all.
pub fn AuditReport::is_clean(self : AuditReport) -> Bool {
  self.findings.length() == 0
}

///|
/// Format dependency audit counts for release evidence.
pub fn DependencyAudit::summary(self : DependencyAudit) -> String {
  "dependencies=" +
  self.dependencies_checked.to_string() +
  " errors=" +
  self.count(AuditSeverity::Error).to_string() +
  " warnings=" +
  self.count(AuditSeverity::Warning).to_string()
}

///|
/// Return the names of dependencies whose metadata contains blocking errors.
pub fn DependencyAudit::error_dependencies(
  self : DependencyAudit,
) -> Array[String] {
  let result : Array[String] = []
  for finding in self.findings {
    if finding.severity == AuditSeverity::Error {
      result.push(finding.path)
    }
  }
  result
}
