# MoonSecureCodec

MoonSecureCodec is a MoonBit toolkit for software supply chain verification. It combines:

- multi-base encoding and decoding
- fast content fingerprinting
- SHA-256 and Merkle proof verification
- SBOM-style manifest snapshots and diff auditing

The project is organized as a small MoonBit workspace with one CLI demo and four reusable libraries.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `lib/codec` | Hex, Base32, Base64, Base58 codecs |
| `lib/digest` | XXHash64, Murmur3, SHA-256, HMAC-SHA256 |
| `lib/merkle` | RFC 6962-style Merkle tree and inclusion proofs |
| `lib/manifest` | File snapshots, Merkle-rooted manifests, diff reports |
| `cmd/cli` | Interactive demonstration executable |

## Quick Start

```bash
moon version
moon check --deny-warn
moon test --deny-warn
moon run cmd/cli
```

## CI

The repository includes a GitHub Actions workflow that runs the same quality gates used for release review:

- `moon check --deny-warn`
- `moon fmt --check`
- `moon info`
- `moon test --deny-warn`

## Self-Check

These are the current submission checks for this repository:

- default branch: `main`
- license: `Apache-2.0`
- MoonBit source files: `13`
- test suite: `1018` passing tests
- local verification: `moon check --deny-warn`, `moon fmt --check`, and `moon test --deny-warn` pass

## License

Licensed under the [Apache License, Version 2.0](LICENSE).
