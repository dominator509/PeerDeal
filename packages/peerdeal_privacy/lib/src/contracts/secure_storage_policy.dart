abstract interface class SecureStoragePolicy {
  String storageClassFor(String artifactKind);

  bool requiresEncryptionAtRest(String artifactKind);
}
