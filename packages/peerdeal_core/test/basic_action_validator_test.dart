import 'package:peerdeal_core/peerdeal_core.dart';
import 'package:test/test.dart';

void main() {
  group('BasicActionValidator', () {
    const validator = BasicActionValidator();

    test('rejects starting a hand without two seated players', () {
      final state = TableState.initial(tableId: 't1', sessionId: 's1').copyWith(
        phase: TablePhase.openReady,
        playersConnected: 2,
        playersSeated: 1,
      );
      const command = CoreCommand(
        commandId: 'cmd_1',
        commandType: 'StartHand',
        actorRef: 'host_1',
        payload: <String, Object?>{},
      );

      final result = validator.validate(state: state, command: command);

      expect(result.isAccepted, isFalse);
      expect(result.resultCode, 'ERR_NEED_TWO_SEATED_PLAYERS');
    });

    test('accepts opening from draft state', () {
      final state = TableState.initial(tableId: 't1', sessionId: 's1');
      const command = CoreCommand(
        commandId: 'cmd_2',
        commandType: 'OpenTableSession',
        actorRef: 'host_1',
        payload: <String, Object?>{},
      );

      final result = validator.validate(state: state, command: command);

      expect(result.isAccepted, isTrue);
    });
  });
}
