# peerdeal_ui_kit

Shared Flutter UI primitives for PeerDeal app shells.

## Purpose
This package owns reusable presentation components that are safe for mobile and
desktop apps to share.

## Must not own
- protocol schemas
- reducer or table truth
- mode, variant, network, receipt, privacy, or capture policy
- app navigation or session orchestration

## Public entrypoint
Use `lib/peerdeal_ui_kit.dart`.
