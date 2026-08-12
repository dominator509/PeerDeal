import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

class AppLocalPeerIdentity {
  const AppLocalPeerIdentity({required this.peerId});

  final String peerId;
}

class AppLocalPeerIdentityLoadResult {
  const AppLocalPeerIdentityLoadResult({
    this.identity,
    this.revision = 0,
    this.warnings = const <String>[],
  });

  final AppLocalPeerIdentity? identity;
  final int revision;
  final List<String> warnings;

  bool get isAvailable => identity != null && warnings.isEmpty;
  bool get isMissing => identity == null && warnings.isEmpty;
}

/// Maps one generic secure-key record into the app-owned local peer identity.
class NativeLocalPeerIdentityLoader {
  static const defaultNamespace = 'peerdeal.identity';
  static const defaultKeyId = 'local_peer_id';
  static const defaultPurpose = 'peer_identity';
  static const defaultAlgorithm = 'opaque-peer-id';

  const NativeLocalPeerIdentityLoader({
    required SecureKeyStorageBridge bridge,
    this.namespace = defaultNamespace,
    this.keyId = defaultKeyId,
    this.purpose = defaultPurpose,
    this.algorithm = defaultAlgorithm,
    this.maxPeerIdLength = 256,
  }) : _bridge = bridge;

  final SecureKeyStorageBridge _bridge;
  final String namespace;
  final String keyId;
  final String purpose;
  final String algorithm;
  final int maxPeerIdLength;

  Future<AppLocalPeerIdentityLoadResult> load({
    Future<void>? cancellation,
  }) async {
    if (!_isValidNamespace(namespace) ||
        !_isValidKeyId(keyId) ||
        !_isValidLabel(purpose) ||
        !_isValidLabel(algorithm) ||
        maxPeerIdLength < 1) {
      return const AppLocalPeerIdentityLoadResult(
        warnings: <String>['Local peer identity configuration is invalid.'],
      );
    }

    final SecureKeyStorageSnapshot snapshot;
    try {
      final bridge = _bridge;
      if (bridge is CancellableSecureKeyStorageBridge) {
        snapshot = await (bridge as CancellableSecureKeyStorageBridge)
            .loadKeyRing(namespace: namespace, cancellation: cancellation);
      } else {
        snapshot = await bridge.loadKeyRing(namespace: namespace);
      }
    } on Object {
      return const AppLocalPeerIdentityLoadResult(
        warnings: <String>['Local peer identity storage could not be loaded.'],
      );
    }

    if (!snapshot.available) {
      return const AppLocalPeerIdentityLoadResult(
        warnings: <String>['Local peer identity storage is unavailable.'],
      );
    }

    final matches = snapshot.keys
        .where(
          (record) =>
              record.keyId == keyId &&
              record.purpose == purpose &&
              record.algorithm == algorithm,
        )
        .toList(growable: false);
    if (matches.isEmpty) {
      return AppLocalPeerIdentityLoadResult(revision: snapshot.revision);
    }
    if (matches.length != 1 || !matches.single.active) {
      return const AppLocalPeerIdentityLoadResult(
        warnings: <String>['Local peer identity records are ambiguous.'],
      );
    }

    final peerId = matches.single.secret;
    if (!_isValidPeerId(peerId)) {
      return const AppLocalPeerIdentityLoadResult(
        warnings: <String>['Persisted local peer identity is invalid.'],
      );
    }

    return AppLocalPeerIdentityLoadResult(
      identity: AppLocalPeerIdentity(peerId: peerId),
      revision: snapshot.revision,
    );
  }

  bool _isValidPeerId(String value) =>
      value.length <= maxPeerIdLength &&
      NativeBridgePayloadLimits.isSafeUtf8Text(
        value,
        NativeBridgePayloadLimits.maxTransportIdentityBytes,
      );

  static bool _isValidNamespace(String value) =>
      _isValidLabel(value) && !value.contains('::');

  bool _isValidKeyId(String value) =>
      _isValidLabel(value) && !value.contains(':');

  static bool _isValidLabel(String value) =>
      value.trim().isNotEmpty &&
      value.trim() == value &&
      !value.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f);
}
