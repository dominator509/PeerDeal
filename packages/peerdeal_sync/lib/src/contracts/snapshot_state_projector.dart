import 'package:peerdeal_protocol/peerdeal_protocol.dart';

abstract interface class SnapshotStateProjector<TState> {
  TState createBaseState({
    required String tableId,
    required String sessionId,
    required String protocolVersion,
  });

  TState applySnapshot({
    required TState state,
    required SnapshotEnvelope snapshot,
  });

  TState applyEvent({
    required TState state,
    required EventEnvelope event,
  });
}
