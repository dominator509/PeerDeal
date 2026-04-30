import 'package:test/test.dart';
import 'package:peerdeal_modes/peerdeal_modes.dart';

void main() {
  group('ModeRegistry', () {
    test('returns Open Table adapter by id', () {
      final registry = ModeRegistry();
      final adapter = registry.byModeId('open_table');
      expect(adapter, isNotNull);
      expect(adapter!.getIdentity().displayName, 'Open Table Mode');
    });

    test('returns Tournament adapter by id', () {
      final registry = ModeRegistry();
      final adapter = registry.byModeId('tournament');
      expect(adapter, isNotNull);
      expect(adapter!.getIdentity().displayName, 'Tournament Mode');
    });
  });

  group('Adapters', () {
    test('Open Table allows simulated reloads and private ledger', () {
      const adapter = OpenTableModeAdapter();
      const config = ModeConfig(modeType: 'open_table', reloadPolicy: 'approval_required');
      expect(adapter.validateConfig(config).isValid, isTrue);
      expect(adapter.getLedgerPolicy(config).ledgerEnabled, isTrue);
      expect(adapter.getReloadPolicy(config).allowed, isTrue);
    });

    test('Tournament rejects unlimited reloads', () {
      const adapter = TournamentModeAdapter();
      const config = ModeConfig(modeType: 'tournament', reloadPolicy: 'unlimited');
      expect(adapter.validateConfig(config).isValid, isFalse);
    });
  });
}
