import '../contracts/mode_adapter.dart';
import 'open_table_mode_adapter.dart';
import 'tournament_mode_adapter.dart';

class ModeRegistry {
  ModeRegistry({
    ModeAdapter? openTableModeAdapter,
    ModeAdapter? tournamentModeAdapter,
  }) : _entries = <String, ModeAdapter>{
          'open_table': openTableModeAdapter ?? const OpenTableModeAdapter(),
          'tournament': tournamentModeAdapter ?? const TournamentModeAdapter(),
        };

  final Map<String, ModeAdapter> _entries;

  ModeAdapter? byModeId(String modeId) => _entries[modeId];

  Iterable<ModeAdapter> all() => _entries.values;
}
