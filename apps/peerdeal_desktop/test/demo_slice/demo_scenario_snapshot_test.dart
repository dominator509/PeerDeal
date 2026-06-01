import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_desktop/demo_slice/models/demo_scenario_snapshot.dart';
import 'package:peerdeal_desktop/demo_slice/scenarios/demo_scenario_catalog.dart';
import 'package:peerdeal_desktop/demo_slice/scenarios/demo_scenario_snapshots.dart';
import 'package:test/test.dart';

void main() {
  test('demo fixture manifest matches the app catalog', () {
    final manifest = _fixtureJson('manifest.json');
    final manifestIds = (manifest['scenario_ids'] as List<Object?>)
        .cast<String>()
        .toList(growable: false);
    final catalogIds = DemoScenarioCatalog.scenarios
        .map((scenario) => scenario.id)
        .toList(growable: false);

    expect(manifest['version'], 1);
    expect(manifestIds, catalogIds);
  });

  test('all demo fixtures parse into app view models', () {
    for (final scenario in DemoScenarioCatalog.scenarios) {
      final snapshot = DemoScenarioSnapshot.fromJson(
        _fixtureJson(_fixtureName(scenario.fixturePath)),
      );

      expect(snapshot.scenarioId, scenario.id);
      expect(_isCleanDisplayText(scenario.title), isTrue);
      expect(_isCleanDisplayText(scenario.description), isTrue);
      expect(snapshot.mode, isNotEmpty);
      expect(snapshot.variant, 'holdem_nlhe');
      expect(_isCleanDisplayText(snapshot.statusBanner.label), isTrue);
      expect(snapshot.statusBanner.severity, isNotEmpty);
      expect(snapshot.chat.unreadCount, greaterThanOrEqualTo(0));
      expect(snapshot.receipt.verificationState, isNotEmpty);
    }
  });

  test('runtime demo snapshot catalog matches fixture snapshots', () {
    final catalogIds = DemoScenarioCatalog.scenarios
        .map((scenario) => scenario.id)
        .toList(growable: false);

    expect(DemoScenarioSnapshots.snapshots.keys, catalogIds);

    for (final scenario in DemoScenarioCatalog.scenarios) {
      final fixture = DemoScenarioSnapshot.fromJson(
        _fixtureJson(_fixtureName(scenario.fixturePath)),
      );
      final runtime = DemoScenarioSnapshots.byId(scenario.id);

      expect(runtime.scenarioId, fixture.scenarioId);
      expect(runtime.mode, fixture.mode);
      expect(runtime.variant, fixture.variant);
      expect(runtime.networkConfidence, fixture.networkConfidence);
      expect(runtime.statusBanner.label, fixture.statusBanner.label);
      expect(runtime.statusBanner.severity, fixture.statusBanner.severity);
      expect(runtime.statusBanner.visible, fixture.statusBanner.visible);
      expect(runtime.chat.unreadCount, fixture.chat.unreadCount);
      expect(
        runtime.chat.disappearingEnabled,
        fixture.chat.disappearingEnabled,
      );
      expect(
        runtime.receipt.verificationState,
        fixture.receipt.verificationState,
      );
      expect(runtime.receipt.retentionMode, fixture.receipt.retentionMode);
      expect(runtime.receipt.bindingMode, fixture.receipt.bindingMode);
    }
  });

  test('runtime demo snapshot lookup has non-throwing fallback seam', () {
    expect(
      DemoScenarioSnapshots.tryById('open_table_live_turn')?.scenarioId,
      'open_table_live_turn',
    );
    expect(DemoScenarioSnapshots.tryById('missing_scenario'), isNull);
  });

  test('demo fixture parser fails fast on malformed shape', () {
    expect(
      () => DemoScenarioSnapshot.fromJson({
        'scenario_id': 'broken',
        'mode': 'open_table',
        'variant': 'holdem_nlhe',
        'network_confidence': 'stable',
        'status_banner': {'visible': 'nope', 'label': '', 'severity': 'none'},
        'chat': {'unread_count': 0, 'disappearing_enabled': false},
        'receipt': {
          'verification_state': 'verified',
          'retention_mode': 'standard',
          'binding_mode': 'session_bound',
        },
      }),
      throwsFormatException,
    );
  });
}

Map<String, Object?> _fixtureJson(String fixtureName) {
  final workspaceLocal = File('tools/demo_slice_fixtures/$fixtureName');
  final appLocal = File('../../tools/demo_slice_fixtures/$fixtureName');
  final file = workspaceLocal.existsSync() ? workspaceLocal : appLocal;
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

String _fixtureName(String fixturePath) {
  return fixturePath.split('/').last;
}

bool _isCleanDisplayText(String value) {
  const invalidDisplayCodeUnits = <int>{0x00C2, 0xFFFD};
  return value.runes.every(
    (codeUnit) => !invalidDisplayCodeUnits.contains(codeUnit),
  );
}
