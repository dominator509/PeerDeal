import 'dart:io';

import 'package:peerdeal_privacy/peerdeal_privacy.dart';
import 'package:test/test.dart';

import 'fixture_loader.dart';

void main() {
  test('loads every retention policy fixture through the typed decoder', () {
    final fixtureFiles = Directory('test/fixtures')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('_policy.json'))
        .toList(growable: false);

    expect(fixtureFiles, hasLength(2));
    for (final file in fixtureFiles) {
      final policy = loadRetentionPolicyFixture(file.uri.pathSegments.last);
      expect(policy.wipeSchedule.mode, isNotEmpty, reason: file.path);
    }
  });

  test('fixture retention modes preserve restore and wipe decisions', () {
    const engine = DefaultRetentionPolicyEngine();
    final strict = loadRetentionPolicyFixture('strict_ephemeral_policy.json');
    final timed = loadRetentionPolicyFixture('timed_sandbox_policy.json');

    final strictSchedule = engine.deriveWipeSchedule(strict);
    expect(engine.canRestore(strict), isFalse);
    expect(strictSchedule.ephemeralExportOnly, isTrue);
    expect(strictSchedule.durableExportAllowed, isFalse);

    expect(engine.canRestore(timed), isTrue);
    expect(timed.wipeSchedule.timedWipeSeconds, 86400);
    final closedAt = DateTime.utc(2026, 4, 25);
    expect(
      engine.isWipeDue(
        policy: timed,
        sessionClosedAt: closedAt,
        now: closedAt.add(const Duration(seconds: 86400)),
      ),
      isTrue,
    );
  });
}
