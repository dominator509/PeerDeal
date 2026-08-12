import 'package:peerdeal_protocol/peerdeal_protocol.dart';

abstract interface class ReplayStateProjector<TState> {
  TState createBaseState({
    required String tableId,
    required String sessionId,
    required String protocolVersion,
  });

  TState applyEvent({required TState state, required EventEnvelope event});
}

/// Optional extension for replay projectors that can hydrate a verified
/// snapshot before applying its ordered event suffix.
///
/// A snapshot is an acceleration artifact, not a second source of truth. The
/// replay engine validates its canonical payload hash first, then delegates
/// typed payload interpretation to this product-owned projector boundary.
abstract interface class ReplaySnapshotStateProjector<TState> {
  TState createStateFromSnapshot({required SnapshotEnvelope snapshot});
}
