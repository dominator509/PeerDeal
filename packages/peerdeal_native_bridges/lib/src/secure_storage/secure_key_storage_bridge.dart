import 'secure_key_storage_bridge_models.dart';

abstract interface class SecureKeyStorageBridge {
  Future<SecureKeyStorageSnapshot> loadKeyRing({required String namespace});
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
