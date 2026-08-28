import '../models/transport_frame.dart';
import '../models/transport_frame_replay_result.dart';

/// Checks transport frame sequence reuse before a frame reaches a session
/// handler and records it only after the handler accepts the frame.
///
/// Implementations must keep their state bounded. Callers must serialize the
/// check/handler/record lifecycle for one frame scope.
abstract interface class TransportFrameReplayGuard {
  TransportFrameReplayResult check(TransportFrame frame);

  void record(TransportFrame frame);
}
