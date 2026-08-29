import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';

import 'native_local_peer_identity_loader.dart';

class AppLocalPeerIdentityWriteResult {
  const AppLocalPeerIdentityWriteResult({
    required this.isSuccess,
    this.warning,
    this.revision,
    this.isConflict = false,
  });

  const AppLocalPeerIdentityWriteResult.success({this.revision})
    : isSuccess = true,
      warning = null,
      isConflict = false;

  const AppLocalPeerIdentityWriteResult.failure({
    required this.warning,
    this.revision,
    this.isConflict = false,
  }) : isSuccess = false;

  final bool isSuccess;
  final String? warning;
  final int? revision;
  final bool isConflict;
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
    int? expectedRevision,
    Future<void>? cancellation,
  }) async {
    if (!_isValidNamespace(namespace) ||
        !_isValidKeyId(keyId) ||
        !_isValidLabel(purpose) ||
        !_isValidLabel(algorithm) ||
        !_isValidPeerId(identity.peerId) ||
        !_isValidRevision(expectedRevision)) {
      return const AppLocalPeerIdentityWriteResult.failure(
        warning: 'Local peer identity save request is invalid.',
      );
    }

    final usesConditionalMutation =
        expectedRevision != null &&
        _bridge is ConditionalSecureKeyStorageMutationBridge;
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
      if (expectedRevision != null &&
          bridge is CancellableConditionalSecureKeyStorageMutationBridge) {
        result =
            await (bridge
                    as CancellableConditionalSecureKeyStorageMutationBridge)
                .saveKeyIfRevision(
                  namespace: namespace,
                  key: key,
                  expectedRevision: expectedRevision,
                  cancellation: cancellation,
                );
      } else if (expectedRevision != null &&
          bridge is ConditionalSecureKeyStorageMutationBridge) {
        result = await (bridge as ConditionalSecureKeyStorageMutationBridge)
            .saveKeyIfRevision(
              namespace: namespace,
              key: key,
              expectedRevision: expectedRevision,
            );
      } else if (bridge is CancellableSecureKeyStorageMutationBridge) {
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

    if (!_isValidRevision(result.revision) ||
        (usesConditionalMutation &&
            _isRevisionBeforeExpected(result.revision, expectedRevision))) {
      return const AppLocalPeerIdentityWriteResult.failure(
        warning: 'Local peer identity save failed.',
      );
    }
    if (result.isSuccess) {
      return AppLocalPeerIdentityWriteResult.success(revision: result.revision);
    }
    return AppLocalPeerIdentityWriteResult.failure(
      warning: 'Local peer identity save failed.',
      revision: result.revision,
      isConflict: result.isConflict,
    );
  }

  bool _isValidPeerId(String value) =>
      maxPeerIdLength > 0 &&
      value.length <= maxPeerIdLength &&
      NetworkInputLimits.isOperationalPeerIdentity(value);

  bool _isValidRevision(int? value) =>
      value == null ||
      (value >= 0 &&
          value <= NativeBridgePayloadLimits.maxSecureKeyRevision);

  bool _isRevisionBeforeExpected(int? revision, int? expectedRevision) {
    return revision != null &&
        expectedRevision != null &&
        revision < expectedRevision;
  }

  static bool _isValidNamespace(String value) =>
      _isValidLabel(value) && !value.contains('::');

  static bool _isValidKeyId(String value) =>
      _isValidLabel(value) && !value.contains(':');

  static bool _isValidLabel(String value) =>
      value.trim().isNotEmpty &&
      value.trim() == value &&
      !value.codeUnits.any(
        (unit) => unit < 0x20 || (unit >= 0x7f && unit <= 0x9f),
      );
}
