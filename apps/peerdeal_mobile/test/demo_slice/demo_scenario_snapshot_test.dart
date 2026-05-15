import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_mobile/demo_slice/models/demo_scenario_snapshot.dart';
import 'package:peerdeal_mobile/demo_slice/scenarios/demo_scenario_catalog.dart';
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
