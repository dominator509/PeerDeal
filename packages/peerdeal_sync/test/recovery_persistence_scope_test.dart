import 'package:peerdeal_sync/peerdeal_sync.dart';
import 'package:test/test.dart';

void main() {
  test('rejects C1 control characters in storage identities', () {
    final scope = RecoveryPersistenceScope(
      tableId: 'table_1',
      sessionId: 'session_\u0085',
      protocolVersion: '1.0.0',
    );

    expect(scope.hasValidStorageIdentity, isFalse);
  });

  test('rejects identities that cannot round-trip through UTF-8', () {
    final scope = RecoveryPersistenceScope(
      tableId: 'table_1',
      sessionId: String.fromCharCode(0xd800),
      protocolVersion: '1.0.0',
    );

    expect(scope.hasValidStorageIdentity, isFalse);
  });

  test('retains valid storage identity format and bounded key', () {
    final scope = RecoveryPersistenceScope(
      tableId: 'table_1',
      sessionId: 'session_1',
      protocolVersion: '1.0.0',
    );

    expect(scope.hasValidStorageIdentity, isTrue);
    expect(scope.storageKey, '1.0.0::table_1::session_1');
  });
}
