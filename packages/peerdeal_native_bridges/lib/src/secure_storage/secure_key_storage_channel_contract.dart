import '../native_bridge_payload_limits.dart';
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
    if (!available ||
        keyPayloads is! List<dynamic> ||
        keyPayloads.length > NativeBridgePayloadLimits.maxSecureKeyRecords ||
        revision == null) {
      return SecureKeyStorageSnapshot.unavailable(
        warning:
            _boundedStringValue(
              payload['warning'],
              NativeBridgePayloadLimits.maxDiagnosticBytes,
            ) ??
            'Secure key storage snapshot is unavailable.',
        revision: revision ?? 0,
      );
    }

    final keys = <SecureKeyRecord>[];
    final keyIds = <String>{};
    for (final keyPayload in keyPayloads) {
      final key = _decodeKey(keyPayload);
      if (key == null || !key.isUsable || !keyIds.add(key.keyId)) {
        return const SecureKeyStorageSnapshot.unavailable(
          warning: 'Secure key storage snapshot is invalid.',
        );
      }
      keys.add(key);
    }

    return SecureKeyStorageSnapshot(
      available: true,
      keys: List<SecureKeyRecord>.unmodifiable(keys),
      revision: revision,
      warning: _boundedStringValue(
        payload['warning'],
        NativeBridgePayloadLimits.maxDiagnosticBytes,
      ),
    );
  }

  static SecureKeyRecord? _decodeKey(Object? payload) {
    if (payload is! Map<Object?, Object?>) return null;

    final keyId = _boundedStringValue(
      payload['keyId'],
      NativeBridgePayloadLimits.maxSecureKeyIdBytes,
    );
    final purpose = _boundedStringValue(
      payload['purpose'],
      NativeBridgePayloadLimits.maxSecureKeyPurposeBytes,
    );
    final algorithm = _boundedStringValue(
      payload['algorithm'],
      NativeBridgePayloadLimits.maxSecureKeyAlgorithmBytes,
    );
    final secret = _boundedStringValue(
      payload['secret'],
      NativeBridgePayloadLimits.maxSecureKeySecretBytes,
    );
    final active = payload['active'];

    if (keyId is! String ||
        purpose is! String ||
        algorithm is! String ||
        secret is! String ||
        active is! bool) {
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
    if (success && isConflict) {
      return const SecureKeyStorageMutationResult.failure(
        warning: 'Secure key storage mutation result is invalid.',
      );
    }
    if (success && payload.containsKey('revision') && revision == null) {
      return const SecureKeyStorageMutationResult.failure(
        warning: 'Secure key storage mutation result is invalid.',
      );
    }
    if (!success) {
      return SecureKeyStorageMutationResult.failure(
        warning:
            _boundedStringValue(
              payload['warning'],
              NativeBridgePayloadLimits.maxDiagnosticBytes,
            ) ??
            'Secure key storage mutation failed.',
        revision: revision,
        isConflict: isConflict,
      );
    }

    return SecureKeyStorageMutationResult(
      isSuccess: true,
      warning: _boundedStringValue(
        payload['warning'],
        NativeBridgePayloadLimits.maxDiagnosticBytes,
      ),
      revision: revision,
    );
  }

  static bool _boolValue(Object? value) => value is bool ? value : false;

  static String? _boundedStringValue(Object? value, int maxBytes) {
    if (value is! String ||
        !NativeBridgePayloadLimits.isWithinUtf8Limit(value, maxBytes)) {
      return null;
    }
    return value;
  }

  static int? _revisionValue(Object? value) {
    if (value == null) return 0;
    if (value is! int ||
        value < 0 ||
        value > NativeBridgePayloadLimits.maxSecureKeyRevision) {
      return null;
    }
    return value;
  }
}
