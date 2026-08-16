# Development History

## Project lineage

The current project is MoonSecureCodec, a MoonBit supply-chain integrity toolkit. Its implementation history is separated into two phases:

1. The repository was initially created from an unrelated MoonBit Datalog/RBAC prototype. Those early commits are retained as historical Git objects for traceability, but they are not part of the current product scope or public API.
2. The MoonSecureCodec project was introduced from the `badd5f5` initialization commit onward. The substantive implementation work includes codec, digest, Merkle, Manifest, dependency-policy, audit, CLI, tests, CI, documentation, and release-readiness changes.

## Current scope boundary

The current default branch contains no active Datalog/RBAC package, import, build target, or user-facing documentation. The `_backup_moon_datalog/` directory is ignored and is not part of the submitted repository. The current module name, package imports, README, CLI, and tests all refer to `Wchch/MoonSecureCodec`.

## Development milestones

- 2026-07-08: established the MoonSecureCodec module and core codec, digest, Merkle, Manifest, and CLI implementation;
- 2026-07-08 to 2026-07-23: added CI, documentation, test expansion, and MoonBit 0.10.3 quality gates;
- 2026-08-12 onward: added Manifest audit and dependency-policy APIs, Multibase and CRC32 utilities, release-policy and approval gates, and boundary tests;
- 2026-08-16: corrected XXHash64 operation order and replaced the non-standard odd-leaf Merkle construction with RFC 6962 tree hashing and proof generation.

This file explains the retained history; it does not claim that the unrelated prototype was part of MoonSecureCodec. The source and tests in the current tree are the evidence for the submitted project scope.
