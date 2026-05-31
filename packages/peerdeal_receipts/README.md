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
- Export artifacts minimize metadata and do not expose table identity.
- `ReceiptCipher` and `ReceiptSigner` contracts can wrap opaque export payloads
  without moving cryptography into app shells.
- `HmacSha256ReceiptSigner` and `StaticReceiptSigningKeyProvider` provide a
  deterministic signing adapter with explicit active and rotated key lookup.
- `OpaqueExportDecoder` verifies signed export artifacts before import-side
  inspection and fails closed on malformed, unsigned, tampered, undecryptable,
  or privacy-leaking payloads.

## Starter status
This scaffold is aligned to the locked PeerDeal receipt, retention, and privacy direction and is intended
as the first package drop for Sprint 11. It has deterministic cipher/signer seams, a concrete HMAC
signing adapter, and signed artifact inspection; production encryption and secure key storage adapters
still need implementation.
