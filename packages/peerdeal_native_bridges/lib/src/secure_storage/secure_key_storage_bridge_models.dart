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
      keyId.trim() == keyId &&
      !keyId.contains(':') &&
      purpose.trim().isNotEmpty &&
      purpose.trim() == purpose &&
      algorithm.trim().isNotEmpty &&
      algorithm.trim() == algorithm &&
      secret.trim().isNotEmpty &&
      secret.trim() == secret;
}

class SecureKeyStorageSnapshot {
  const SecureKeyStorageSnapshot({
    required this.available,
    required this.keys,
    this.revision = 0,
    this.warning,
  });

  const SecureKeyStorageSnapshot.unavailable({this.warning, this.revision = 0})
    : available = false,
      keys = const <SecureKeyRecord>[];

  final bool available;
  final List<SecureKeyRecord> keys;
  final int revision;
  final String? warning;
}

class SecureKeyStorageMutationResult {
  const SecureKeyStorageMutationResult({
    required this.isSuccess,
    this.warning,
    this.revision,
    this.isConflict = false,
  });

  const SecureKeyStorageMutationResult.failure({
    required this.warning,
    this.revision,
    this.isConflict = false,
  }) : isSuccess = false;

  final bool isSuccess;
  final String? warning;
  final int? revision;
  final bool isConflict;
}
