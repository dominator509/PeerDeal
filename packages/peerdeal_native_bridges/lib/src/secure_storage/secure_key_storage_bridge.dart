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

/// Optional compare-and-swap capability for mutations based on a previously
/// loaded namespace revision.
///
/// The base mutation bridge remains unchanged for older platform hosts and
/// test doubles. Production hosts that persist revisions implement this seam
/// so a read-then-write cannot silently overwrite another process's update.
abstract interface class ConditionalSecureKeyStorageMutationBridge {
  Future<SecureKeyStorageMutationResult> saveKeyIfRevision({
    required String namespace,
    required SecureKeyRecord key,
    required int expectedRevision,
  });

  Future<SecureKeyStorageMutationResult> deleteKeyIfRevision({
    required String namespace,
    required String keyId,
    required int expectedRevision,
  });
}

/// Cancellable form of [ConditionalSecureKeyStorageMutationBridge].
abstract interface class CancellableConditionalSecureKeyStorageMutationBridge
    implements ConditionalSecureKeyStorageMutationBridge {
  @override
  Future<SecureKeyStorageMutationResult> saveKeyIfRevision({
    required String namespace,
    required SecureKeyRecord key,
    required int expectedRevision,
    Future<void>? cancellation,
  });

  @override
  Future<SecureKeyStorageMutationResult> deleteKeyIfRevision({
    required String namespace,
    required String keyId,
    required int expectedRevision,
    Future<void>? cancellation,
  });
}
