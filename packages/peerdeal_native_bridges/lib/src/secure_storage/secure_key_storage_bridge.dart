import 'secure_key_storage_bridge_models.dart';

abstract interface class SecureKeyStorageBridge {
  Future<SecureKeyStorageSnapshot> loadKeyRing({required String namespace});
}

/// Optional cancellation capability for callers that own a route lifecycle.
///
/// The base bridge remains synchronous in shape for existing integrations;
/// callers can detect this capability before passing cancellation through.
abstract interface class CancellableSecureKeyStorageBridge {
  Future<SecureKeyStorageSnapshot> loadKeyRing({
    required String namespace,
    Future<void>? cancellation,
  });
}

abstract interface class SecureKeyStorageMutationBridge
    implements SecureKeyStorageBridge {
  Future<SecureKeyStorageMutationResult> saveKey({
    required String namespace,
    required SecureKeyRecord key,
  });

  Future<SecureKeyStorageMutationResult> deleteKey({
    required String namespace,
    required String keyId,
  });
}

abstract interface class CancellableSecureKeyStorageMutationBridge
    implements CancellableSecureKeyStorageBridge {
  Future<SecureKeyStorageMutationResult> saveKey({
    required String namespace,
    required SecureKeyRecord key,
    Future<void>? cancellation,
  });

  Future<SecureKeyStorageMutationResult> deleteKey({
    required String namespace,
    required String keyId,
    Future<void>? cancellation,
  });
}
