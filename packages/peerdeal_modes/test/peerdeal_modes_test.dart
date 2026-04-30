import 'package:peerdeal_modes/peerdeal_modes.dart';
import 'package:test/test.dart';

void main() {
  test('open table baseline supports live join', () {
    const adapter = OpenTableModeAdapter();
    expect(adapter.supportsLiveJoin, isTrue);
  });

  test('tournament baseline starts with live join disabled', () {
    const adapter = TournamentModeAdapter();
    expect(adapter.supportsLiveJoin, isFalse);
  });
}
