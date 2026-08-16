///|
/// Approval metadata attached to a release review.
pub(all) struct ApprovalRecord {
  reviewer : String
  ticket : String
  reviewed_root : String
  approved_at : String
  notes : String
}

///|
/// Validate that an approval refers to the exact manifest root under review.
pub fn ApprovalRecord::matches(
  self : ApprovalRecord,
  manifest : Manifest,
) -> Bool {
  self.reviewer.length() > 0 &&
  self.ticket.length() > 0 &&
  self.approved_at.length() > 0 &&
  self.reviewed_root == manifest.merkle_root
}

///|
/// Return a stable serialized approval line for audit logs.
pub fn ApprovalRecord::to_text(self : ApprovalRecord) -> String {
  "reviewer=" +
  self.reviewer +
  " ticket=" +
  self.ticket +
  " reviewed_root=" +
  self.reviewed_root +
  " approved_at=" +
  self.approved_at +
  " notes=" +
  self.notes
}

///|
/// A release gate that requires both technical and human approval.
pub(all) struct ApprovalGate {
  policy : ReleasePolicy
  require_clean_report : Bool
}

///|
/// Construct a strict gate for a public package release.
pub fn ApprovalGate::strict() -> ApprovalGate {
  { policy: ReleasePolicy::source_package(), require_clean_report: true }
}

///|
/// Check policy and approval evidence together.
pub fn ApprovalGate::evaluate(
  self : ApprovalGate,
  manifest : Manifest,
  approval : ApprovalRecord?,
) -> Bool {
  let report = manifest.release_check(self.policy)
  if report.has_errors() {
    return false
  }
  if self.require_clean_report && !report.is_clean() {
    return false
  }
  match approval {
    Some(record) => record.matches(manifest)
    None => false
  }
}

///|
/// Return the exact root that an external signer should approve.
pub fn Manifest::approval_payload(self : Manifest) -> String {
  "manifest=" +
  self.name +
  " version=" +
  self.version +
  " root=" +
  self.merkle_root +
  " files=" +
  self.files.length().to_string()
}

///|
/// Return a finding when approval metadata is missing or stale.
pub fn Manifest::approval_finding(
  self : Manifest,
  approval : ApprovalRecord?,
) -> AuditFinding? {
  match approval {
    Some(record) =>
      if record.matches(self) {
        None
      } else {
        Some({
          code: "APPROVAL_ROOT_MISMATCH",
          severity: AuditSeverity::Error,
          path: "<approval>",
          message: "approval does not bind to the current manifest root",
          remediation: "re-run the review and approve the exact published root",
        })
      }
    None =>
      Some({
        code: "APPROVAL_MISSING",
        severity: AuditSeverity::Error,
        path: "<approval>",
        message: "release has no reviewer approval record",
        remediation: "attach a review ticket and the exact Merkle root",
      })
  }
}
