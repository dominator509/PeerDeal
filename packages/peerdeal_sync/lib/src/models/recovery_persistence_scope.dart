import 'dart:convert';

import 'package:meta/meta.dart';

import 'recovery_persistence_limits.dart';

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

  bool get hasValidStorageIdentity {
    final key = storageKey;
    return _isValidStoragePart(protocolVersion) &&
        _isValidStoragePart(tableId) &&
        _isValidStoragePart(sessionId) &&
        utf8.encode(key).length <=
            RecoveryPersistenceLimits.defaultMaxStorageKeyBytes;
  }

  static bool _isValidStoragePart(String value) {
    if (value.isEmpty || value.trim() != value) return false;
    if (value.contains('::')) return false;
    return value.runes.every((rune) => rune > 0x1f && rune != 0x7f);
  }
}
