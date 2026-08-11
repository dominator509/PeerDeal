import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

import 'native_local_peer_identity_loader.dart';

class AppLocalPeerIdentityWriteResult {
  const AppLocalPeerIdentityWriteResult({
    required this.isSuccess,
    this.warning,
  });

  const AppLocalPeerIdentityWriteResult.success()
    : isSuccess = true,
      warning = null;

  const AppLocalPeerIdentityWriteResult.failure({required this.warning})
    : isSuccess = false;

  final bool isSuccess;
  final String? warning;
}

class NativeLocalPeerIdentityWriter {
  const NativeLocalPeerIdentityWriter({
    required SecureKeyStorageMutationBridge bridge,
    this.namespace = NativeLocalPeerIdentityLoader.defaultNamespace,
    this.keyId = NativeLocalPeerIdentityLoader.defaultKeyId,
    this.purpose = NativeLocalPeerIdentityLoader.defaultPurpose,
    this.algorithm = NativeLocalPeerIdentityLoader.defaultAlgorithm,
    this.maxPeerIdLength = 256,
  }) : _bridge = bridge;

  final SecureKeyStorageMutationBridge _bridge;
  final String namespace;
  final String keyId;
  final String purpose;
  final String algorithm;
  final int maxPeerIdLength;

  Future<AppLocalPeerIdentityWriteResult> save(
    AppLocalPeerIdentity identity, {
    Future<void>? cancellation,
  }) async {
    if (!_isValidNamespace(namespace) ||
        !_isValidKeyId(keyId) ||
        !_isValidLabel(purpose) ||
        !_isValidLabel(algorithm) ||
        !_isValidPeerId(identity.peerId)) {
      return const AppLocalPeerIdentityWriteResult.failure(
        warning: 'Local peer identity save request is invalid.',
      );
    }

    final SecureKeyStorageMutationResult result;
    try {
      final bridge = _bridge;
      final key = SecureKeyRecord(
        keyId: keyId,
        purpose: purpose,
        algorithm: algorithm,
        secret: identity.peerId,
        active: true,
      );
      if (bridge is CancellableSecureKeyStorageMutationBridge) {
        result = await (bridge as CancellableSecureKeyStorageMutationBridge)
            .saveKey(
              namespace: namespace,
              key: key,
              cancellation: cancellation,
            );
      } else {
        result = await bridge.saveKey(namespace: namespace, key: key);
      }
    } on Object {
      return const AppLocalPeerIdentityWriteResult.failure(
        warning: 'Local peer identity save failed.',
      );
    }

    if (result.isSuccess) {
      return const AppLocalPeerIdentityWriteResult.success();
    }
    return const AppLocalPeerIdentityWriteResult.failure(
      warning: 'Local peer identity save failed.',
    );
  }

  bool _isValidPeerId(String value) =>
      maxPeerIdLength > 0 &&
      value.length <= maxPeerIdLength &&
      value.trim().isNotEmpty &&
      value.trim() == value &&
      !value.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f);

  static bool _isValidNamespace(String value) =>
      _isValidLabel(value) && !value.contains('::');

  static bool _isValidKeyId(String value) =>
      _isValidLabel(value) && !value.contains(':');

  static bool _isValidLabel(String value) =>
      value.trim().isNotEmpty &&
      value.trim() == value &&
      !value.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f);
}
