# peerdeal_receipts

Starter scaffold for PeerDeal receipt packaging, authorization, and wipe-aware resolution.

## Owns
- PeerDeal Receipt envelope and artifact models
- binding-mode and wipe-state models
- restore vs view authorization boundary
- signature / cipher contracts
- export opacity helpers
- receipt service orchestration
- receipt fixtures and package-local tests

## Must not own
- poker truth or ledger calculation truth
- transport bootstrap logic
- capture-engine behavior
- UI rendering
- money/value semantics

## Hardened scaffold coverage
- Receipt exports reject malformed or wiped receipts.
- Receipt exports require an explicit caller authorization request and fail
  closed when authorization is absent, denied, or unavailable.
- Receipt authorization rejects blank, padded, oversized, or control-bearing
  caller identity/session fields before binding checks.
- Receipt envelope validation applies the same bounded, strict UTF-8 and
  control-free text rules before scan or authorization policy runs.
- Direct authorization calls fail closed when a caller-owned authorizer throws.
- Export artifacts minimize metadata and do not expose table identity.
- `ReceiptCipher` and `ReceiptSigner` contracts can wrap opaque export payloads
  without moving cryptography into app shells.
- `HmacSha256ReceiptSigner` and `StaticReceiptSigningKeyProvider` provide a
  deterministic signing adapter with explicit active and rotated key lookup.
- `HmacSha256ReceiptCipher` provides an authenticated receipt-owned encryption
  adapter backed by loaded encryption keys, with retained-key decryption and
  tamper rejection.
- `ReceiptKeyRingSnapshot` exposes loaded signing and encryption keys through
  receipt-owned provider contracts, so app shells do not interpret key rotation
  rules directly.
- Receipt-owned key-ring providers bound retained verification and decryption
  collections to 128 entries by default and fail closed before oversized
  traversal.
- Receipt scan, export, inspection, and key-ring models defensively copy and
  freeze caller-owned maps/lists at construction, including nested JSON-like
  payload values.
- `OpaqueExportDecoder` verifies signed export artifacts before import-side
  inspection and fails closed on malformed, unsigned, tampered, undecryptable,
  privacy-leaking payloads, or verifier adapter failures.
- Receipt artifact and payload JSON decoding also applies bounded canonical
  structure validation before shape inspection.
- `DefaultReceiptService.exportReceipt` fails closed to an unavailable artifact
  when export signing or encryption adapters throw.
- `OpaqueExportEncoder` also fails closed for direct callers when signer or
  cipher adapters throw.
- `HmacSha256ReceiptSigner.verify` fails closed when verification key lookup
  throws.
- Receipt and authorization fixtures are decoded through typed test-only
  loaders; the fixture suite covers matching access, wrong-user restore, and
  wiped-receipt rejection through the existing authorizer boundary.

## Starter status
This scaffold is aligned to the locked PeerDeal receipt, retention, and privacy direction and is intended
as the first package drop for Sprint 11. It has deterministic cipher/signer seams, concrete HMAC-backed
signing and authenticated encryption adapters, signed artifact inspection, and receipt-owned key-ring
lookup contracts. Platform-secure storage still needs implementation behind these seams.

## Remaining environment gaps
The current ChatGPT project environment can harden Dart contracts and tests, but
cannot complete platform-secure storage or native OS keychain/keystore
implementations. Those must be implemented in platform code behind the locked
`peerdeal_native_bridges` method-channel contracts.
