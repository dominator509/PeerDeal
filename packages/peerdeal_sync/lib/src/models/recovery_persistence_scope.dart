import 'package:meta/meta.dart';

@immutable
class RecoveryPersistenceScope {
  const RecoveryPersistenceScope({
    required this.tableId,
    required this.sessionId,
    required this.protocolVersion,
  });

  final String tableId;
  final String sessionId;
  final String protocolVersion;

  String get storageKey => '$protocolVersion::$tableId::$sessionId';
}
