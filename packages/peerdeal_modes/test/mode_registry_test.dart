import 'package:peerdeal_modes/peerdeal_modes.dart';
import 'package:test/test.dart';

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
      const config = ModeConfig(
        modeType: 'open_table',
        reloadPolicy: 'approval_required',
      );
      expect(adapter.validateConfig(config).isValid, isTrue);
      expect(adapter.getLedgerPolicy(config).ledgerEnabled, isTrue);
      expect(
        adapter.getLedgerPolicy(config).summaryLabel,
        'open_table_private_ledger',
      );
      expect(adapter.getReloadPolicy(config).allowed, isTrue);
      expect(adapter.getReloadPolicy(config).policyType, 'approval_required');
    });

    test('Open Table rejects unknown reload policies fail closed', () {
      const adapter = OpenTableModeAdapter();
      const config = ModeConfig(
        modeType: 'open_table',
        reloadPolicy: 'unlimited',
      );

      final validation = adapter.validateConfig(config);

      expect(validation.isValid, isFalse);
      expect(adapter.getReloadPolicy(config).allowed, isFalse);
      expect(
        validation.errors,
        contains(
          'Open Table Mode requires reloadPolicy=disabled or approval_required.',
        ),
      );
    });

    test('Tournament rejects unlimited reloads', () {
      const adapter = TournamentModeAdapter();
      const config = ModeConfig(
        modeType: 'tournament',
        reloadPolicy: 'unlimited',
      );
      expect(adapter.validateConfig(config).isValid, isFalse);
    });

    test('Tournament uses reentry policy without private ledger', () {
      const adapter = TournamentModeAdapter();
      const config = ModeConfig(modeType: 'tournament', reentryEnabled: true);

      expect(adapter.validateConfig(config).isValid, isTrue);
      expect(adapter.getLedgerPolicy(config).ledgerEnabled, isFalse);
      expect(
        adapter.getLedgerPolicy(config).summaryLabel,
        'tournament_results_summary',
      );
      expect(adapter.getReloadPolicy(config).allowed, isTrue);
      expect(adapter.getReloadPolicy(config).policyType, 'reentry');
    });

    test('Tournament rejects direct reload policy configuration', () {
      const adapter = TournamentModeAdapter();
      const config = ModeConfig(
        modeType: 'tournament',
        reloadPolicy: 'approval_required',
      );

      final validation = adapter.validateConfig(config);

      expect(validation.isValid, isFalse);
      expect(adapter.getReloadPolicy(config).allowed, isFalse);
      expect(
        validation.errors,
        contains(
          'Tournament Mode uses reentryEnabled instead of reloadPolicy.',
        ),
      );
    });
  });
}
