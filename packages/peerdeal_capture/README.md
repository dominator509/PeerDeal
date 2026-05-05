# peerdeal_capture

Capture policy boundary for PeerDeal.

## Purpose
This package owns policy decisions for sensitive screen-capture and recording
surfaces.

## Must not own
- native OS capture hooks
- Flutter app lifecycle orchestration
- receipt data models
- privacy retention rules
- reducer or protocol truth

## Related ownership
- `peerdeal_native_bridges` owns platform hooks.
- app shells own when lifecycle events call into capture policy.
- `peerdeal_privacy` owns retention and minimization policy.
