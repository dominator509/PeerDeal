# PeerDeal Package Map

/apps
  peerdeal_mobile
  peerdeal_desktop

/packages
  peerdeal_protocol
  peerdeal_core
  peerdeal_variants
  peerdeal_modes
  peerdeal_crypto
  peerdeal_network
  peerdeal_sync
  peerdeal_replay
  peerdeal_receipts
  peerdeal_capture
  peerdeal_privacy
  peerdeal_wizard
  peerdeal_ui_kit
  peerdeal_native_bridges
  peerdeal_testkit

## Dependency law
- apps -> package public APIs only
- peerdeal_core -> peerdeal_protocol only
- peerdeal_variants -> peerdeal_protocol, peerdeal_core
- peerdeal_modes -> peerdeal_protocol, peerdeal_core
- no package may import another package's src/

## Boundary check coverage
`melos run boundary-check` verifies that:
- the root workspace list, actual package folders, and this package map match
- PeerDeal package imports are declared in the importing package's pubspec
- `peerdeal_core`, `peerdeal_variants`, and `peerdeal_modes` stay within the
  dependency law above
- package imports do not reach into another package's `src/` internals
