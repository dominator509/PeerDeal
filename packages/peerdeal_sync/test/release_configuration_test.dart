import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

void main() {
  test('rejects invalid configured limits at runtime', () {
    expect(
      () => const BasicConflictDetector(maxEvents: 0).detect(
        RecoveryRequest(
          tableId: 'table_1',
          sessionId: 'session_1',
          protocolVersion: '1.0.0',
          mode: RecoveryMode.reconnect,
          events: const [],
        ),
      ),
      throwsArgumentError,
    );
  });
}
