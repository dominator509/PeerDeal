import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

const _maximumWarningCount = 4;
const _maximumWarningLength = 160;

class AppLocalPeerIdentity {
  const AppLocalPeerIdentity({required this.peerId});

  final String peerId;
}

class AppLocalPeerIdentityLoadResult {
  AppLocalPeerIdentityLoadResult({
    this.identity,
    this.revision = 0,
    List<String> warnings = const <String>[],
  }) : warnings = _safeLocalIdentityWarnings(warnings);

  final AppLocalPeerIdentity? identity;
  final int revision;
  final List<String> warnings;

  bool get isAvailable => identity != null && warnings.isEmpty;
  bool get isMissing => identity == null && warnings.isEmpty;
}

List<String> _safeLocalIdentityWarnings(List<String> warnings) {
  final truncated = warnings.length > _maximumWarningCount;
  final valueLimit = truncated
      ? _maximumWarningCount - 1
      : _maximumWarningCount;
  final safe = <String>[];
  for (final warning in warnings) {
    if (safe.length == valueLimit) break;
    final trimmed = warning.trim();
    safe.add(
      trimmed.isEmpty ||
              trimmed != warning ||
              warning.length > _maximumWarningLength ||
              !NativeBridgePayloadLimits.isWithinUtf8Limit(warning, 512) ||
              warning.codeUnits.any(
                (unit) => unit < 0x20 || (unit >= 0x7f && unit <= 0x9f),
              )
          ? 'Local peer identity warning unavailable.'
          : warning,
    );
  }
  if (truncated) {
    safe.add('Local peer identity warnings truncated.');
  }
  return List<String>.unmodifiable(safe);
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
      return AppLocalPeerIdentityLoadResult(
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
      return AppLocalPeerIdentityLoadResult(
        warnings: <String>['Local peer identity storage could not be loaded.'],
      );
    }

    if (!snapshot.available) {
      return AppLocalPeerIdentityLoadResult(
        warnings: <String>['Local peer identity storage is unavailable.'],
      );
    }
    if (snapshot.revision < 0 ||
        snapshot.revision > NativeBridgePayloadLimits.maxSecureKeyRevision) {
      return AppLocalPeerIdentityLoadResult(
        warnings: <String>['Local peer identity storage revision is invalid.'],
      );
    }
    if (snapshot.keys.length > NativeBridgePayloadLimits.maxSecureKeyRecords) {
      return AppLocalPeerIdentityLoadResult(
        warnings: <String>['Local peer identity record limit reached.'],
      );
    }
    final keyIds = <String>{};
    if (snapshot.keys.any((record) => !keyIds.add(record.keyId))) {
      return AppLocalPeerIdentityLoadResult(
        warnings: <String>[
          'Local peer identity storage contains duplicate key IDs.',
        ],
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
      if (snapshot.keys.any((record) => !record.isUsable)) {
        return AppLocalPeerIdentityLoadResult(
          warnings: <String>['Local peer identity records are invalid.'],
        );
      }
      return AppLocalPeerIdentityLoadResult(revision: snapshot.revision);
    }
    if (matches.length != 1 || !matches.single.active) {
      return AppLocalPeerIdentityLoadResult(
        warnings: <String>['Local peer identity records are ambiguous.'],
      );
    }

    final peerId = matches.single.secret;
    if (!_isValidPeerId(peerId)) {
      return AppLocalPeerIdentityLoadResult(
        warnings: <String>['Persisted local peer identity is invalid.'],
      );
    }
    if (snapshot.keys.any((record) => !record.isUsable)) {
      return AppLocalPeerIdentityLoadResult(
        warnings: <String>['Local peer identity records are invalid.'],
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
      !value.codeUnits.any(
        (unit) => unit < 0x20 || (unit >= 0x7f && unit <= 0x9f),
      );
}
