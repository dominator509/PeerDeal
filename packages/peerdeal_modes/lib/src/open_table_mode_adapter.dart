import 'mode_adapter.dart';

class OpenTableModeAdapter implements ModeAdapter {
  const OpenTableModeAdapter();

  @override
  String get modeId => 'open_table';

  @override
  bool get supportsLiveJoin => true;

  @override
  bool get supportsReceipts => true;

  @override
  Map<String, Object?> getCapabilities() => const {
        'supports_live_join': true,
        'supports_reload_policy': true,
        'supports_personal_ledger': true,
      };
}
