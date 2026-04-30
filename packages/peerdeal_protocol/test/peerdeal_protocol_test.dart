import 'dart:convert';
import 'dart:io';

import 'package:peerdeal_protocol/peerdeal_protocol.dart';
import 'package:test/test.dart';

void main() {
  test('canonical json encoding is stable for map key order', () {
    final a = canonicalJsonEncode({
      'b': 2,
      'a': 1,
      'nested': {'z': true, 'x': false},
    });

    final b = canonicalJsonEncode({
      'nested': {'x': false, 'z': true},
      'a': 1,
      'b': 2,
    });

    expect(a, equals(b));
  });

  test('game file fixture validates', () {
    final file = File('fixtures/gamefiles/open_table_valid_v1.json');
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    final errors = GameFileSchema().validate(decoded);
    expect(errors, isEmpty);
  });

  test('invite payload fixture validates', () {
    final file = File('fixtures/invites/open_table_player_invite_v1.json');
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    final errors = InvitePayloadSchema().validate(decoded);
    expect(errors, isEmpty);
  });

  test('event hash helper returns non-empty sha256', () {
    final hash = computeCanonicalHash({
      'event_type': 'OpenTableSessionOpened',
      'payload': {'config_id': 'cfg_open_table_001'},
    });
    expect(hash.length, equals(64));
  });
}
