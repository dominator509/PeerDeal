import 'dart:io';

import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:test/test.dart';

import 'fixture_loader.dart';

void main() {
  test('loads every root core event fixture through the typed decoder', () {
    final fixtureFiles = _coreFixtureDirectory()
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList(growable: false);

    expect(fixtureFiles, hasLength(1));
    for (final file in fixtureFiles) {
      final fixture = loadCoreEventSequenceFixture(file.uri.pathSegments.last);
      expect(fixture.events, isNotEmpty, reason: file.path);
    }
  });

  test('core event fixture replays through the default reducer', () {
    final fixture = loadCoreEventSequenceFixture(
      'open_table_open_sequence.json',
    );
    var state = TableState.initial();
    const reducer = CoreReducer();
    for (final event in fixture.events) {
      state = reducer.apply(state, event);
    }

    expect(state.tableId, 'tbl_001');
    expect(state.sessionId, 'sess_001');
    expect(state.phase, TablePhase.openReady);
    expect(state.eventSequence, 2);
    expect(state.playersConnected, 1);
    expect(state.metadata['last_event_hash'], fixture.events.last.eventHash);
  });
}

Directory _coreFixtureDirectory() {
  final packageLocal = Directory('fixtures');
  if (packageLocal.existsSync()) return packageLocal;
  return Directory('packages/peerdeal_core/fixtures');
}
