import 'secure_key_storage_bridge_models.dart';

class SecureKeyStorageChannelContract {
  const SecureKeyStorageChannelContract._();

  static const channelName = 'peerdeal/native_bridges/secure_key_storage';
  static const loadKeyRingMethod = 'loadKeyRing';

  static SecureKeyStorageSnapshot decodeSnapshot(
    Map<String, Object?>? payload,
  ) {
    if (payload == null) {
      return const SecureKeyStorageSnapshot.unavailable(
        warning: 'Secure key storage snapshot is unavailable.',
      );
    }

    final available = _boolValue(payload['available']);
    final keyPayloads = payload['keys'];
    if (!available || keyPayloads is! List<dynamic>) {
      return SecureKeyStorageSnapshot.unavailable(
        warning:
            _stringValue(payload['warning']) ??
            'Secure key storage snapshot is unavailable.',
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

  static bool _boolValue(Object? value) => value is bool ? value : false;

  static String? _stringValue(Object? value) => value is String ? value : null;
}
