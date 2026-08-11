import 'secure_key_storage_bridge_models.dart';

class SecureKeyStorageChannelContract {
  const SecureKeyStorageChannelContract._();

  static const channelName = 'peerdeal/native_bridges/secure_key_storage';
  static const loadKeyRingMethod = 'loadKeyRing';
  static const saveKeyMethod = 'saveKey';
  static const deleteKeyMethod = 'deleteKey';
  static const saveKeyIfRevisionMethod = 'saveKeyIfRevision';
  static const deleteKeyIfRevisionMethod = 'deleteKeyIfRevision';

  static SecureKeyStorageSnapshot decodeSnapshot(
    Map<String, Object?>? payload,
  ) {
    if (payload == null) {
      return const SecureKeyStorageSnapshot.unavailable(
        warning: 'Secure key storage snapshot is unavailable.',
      );
    }

    final available = _boolValue(payload['available']);
    final revision = _revisionValue(payload['revision']);
    final keyPayloads = payload['keys'];
    if (!available || keyPayloads is! List<dynamic> || revision == null) {
      return SecureKeyStorageSnapshot.unavailable(
        warning:
            _stringValue(payload['warning']) ??
            'Secure key storage snapshot is unavailable.',
        revision: revision ?? 0,
      );
    }

    final keys = <SecureKeyRecord>[];
    for (final keyPayload in keyPayloads) {
      final key = _decodeKey(keyPayload);
      if (key != null && key.isUsable) {
        keys.add(key);
      }
    }

    return SecureKeyStorageSnapshot(
      available: true,
      keys: List<SecureKeyRecord>.unmodifiable(keys),
      revision: revision,
      warning: _stringValue(payload['warning']),
    );
  }

  static SecureKeyRecord? _decodeKey(Object? payload) {
    if (payload is! Map<Object?, Object?>) return null;

    final keyId = payload['keyId'];
    final purpose = payload['purpose'];
    final algorithm = payload['algorithm'];
    final secret = payload['secret'];
    final active = payload['active'];

    if (keyId is! String ||
        purpose is! String ||
        algorithm is! String ||
        secret is! String) {
      return null;
    }

    return SecureKeyRecord(
      keyId: keyId,
      purpose: purpose,
      algorithm: algorithm,
      secret: secret,
      active: _boolValue(active),
    );
  }

  static Map<String, Object?> encodeKey(SecureKeyRecord key) {
    return <String, Object?>{
      'keyId': key.keyId,
      'purpose': key.purpose,
      'algorithm': key.algorithm,
      'secret': key.secret,
      'active': key.active,
    };
  }

  static SecureKeyStorageMutationResult decodeMutationResult(
    Map<String, Object?>? payload,
  ) {
    if (payload == null) {
      return const SecureKeyStorageMutationResult.failure(
        warning: 'Secure key storage mutation result is unavailable.',
      );
    }

    final success = _boolValue(payload['success']);
    final revision = _revisionValue(payload['revision']);
    final isConflict = _boolValue(payload['conflict']);
    if (!success) {
      return SecureKeyStorageMutationResult.failure(
        warning:
            _stringValue(payload['warning']) ??
            'Secure key storage mutation failed.',
        revision: revision,
        isConflict: isConflict,
      );
    }

    return SecureKeyStorageMutationResult(
      isSuccess: true,
      warning: _stringValue(payload['warning']),
      revision: revision,
    );
  }

  static bool _boolValue(Object? value) => value is bool ? value : false;

  static String? _stringValue(Object? value) => value is String ? value : null;

  static int? _revisionValue(Object? value) {
    if (value == null) return 0;
    if (value is! int || value < 0) return null;
    return value;
  }
}
