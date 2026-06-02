import 'secure_key_storage_bridge_models.dart';

abstract interface class SecureKeyStorageBridge {
  Future<SecureKeyStorageSnapshot> loadKeyRing({required String namespace});
}
