import 'mode_adapter.dart';

class TournamentModeAdapter implements ModeAdapter {
  const TournamentModeAdapter();

  @override
  String get modeId => 'tournament';

  @override
  bool get supportsLiveJoin => false;

  @override
  bool get supportsReceipts => true;

  @override
  Map<String, Object?> getCapabilities() => const {
        'supports_live_join': false,
        'supports_late_registration': false,
        'supports_tournament_schedule': true,
      };
}
