import '../models/replay_request.dart';
import '../models/replay_result.dart';

abstract interface class ReplayEngine<TState> {
  ReplayResult<TState> replay(ReplayRequest request);
}
