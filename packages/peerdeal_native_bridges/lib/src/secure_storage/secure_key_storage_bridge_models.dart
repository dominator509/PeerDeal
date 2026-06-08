class SecureKeyRecord {
  const SecureKeyRecord({
    required this.keyId,
    required this.purpose,
    required this.algorithm,
    required this.secret,
    required this.active,
  });

  final String keyId;
  final String purpose;
  final String algorithm;
  final String secret;
  final bool active;

  bool get isUsable =>
      keyId.trim().isNotEmpty &&
      !keyId.contains(':') &&
      purpose.trim().isNotEmpty &&
      algorithm.trim().isNotEmpty &&
      secret.trim().isNotEmpty;
}

class SecureKeyStorageSnapshot {
  const SecureKeyStorageSnapshot({
    required this.available,
    required this.keys,
    this.warning,
  });

  const SecureKeyStorageSnapshot.unavailable({this.warning})
    : available = false,
      keys = const <SecureKeyRecord>[];

  final bool available;
  final List<SecureKeyRecord> keys;
  final String? warning;
}

class SecureKeyStorageMutationResult {
  const SecureKeyStorageMutationResult({required this.isSuccess, this.warning});

  const SecureKeyStorageMutationResult.failure({required this.warning})
    : isSuccess = false;

  final bool isSuccess;
  final String? warning;
}
