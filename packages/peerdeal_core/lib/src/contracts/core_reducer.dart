import '../models/command_application_result.dart';
import '../models/core_event.dart';
import '../models/reducer_context.dart';
import '../models/table_state.dart';

abstract interface class CoreReducer {
  TableState applyEvent({
    required TableState state,
    required CoreEvent event,
    required ReducerContext context,
  });

  CommandApplicationResult applyEvents({
    required TableState initialState,
    required List<CoreEvent> events,
    required ReducerContext context,
  });
}
