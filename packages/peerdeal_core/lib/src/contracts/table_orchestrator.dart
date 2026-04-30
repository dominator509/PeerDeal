import '../models/core_command.dart';
import '../models/core_event.dart';
import '../models/table_state.dart';

abstract interface class TableOrchestrator {
  List<CoreEvent> plan({
    required TableState state,
    required CoreCommand command,
  });
}
