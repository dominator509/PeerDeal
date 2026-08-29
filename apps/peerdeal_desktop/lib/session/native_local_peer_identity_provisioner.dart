import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

import 'native_local_peer_identity_loader.dart';
import 'native_local_peer_identity_writer.dart';

const _maximumWarningCount = 4;
const _maximumWarningLength = 160;

typedef AppLocalPeerIdentityFactory = String Function();

class AppLocalPeerIdentityProvisionResult {
  AppLocalPeerIdentityProvisionResult({
    this.identity,
    List<String> warnings = const <String>[],
    this.created = false,
  }) : warnings = _safeLocalIdentityProvisionWarnings(warnings);

  final AppLocalPeerIdentity? identity;
  final List<String> warnings;
  final bool created;

  bool get isSuccess => identity != null && warnings.isEmpty;
}

List<String> _safeLocalIdentityProvisionWarnings(List<String> warnings) {
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
          ? 'Local peer identity provisioning warning unavailable.'
          : warning,
    );
  }
  if (truncated) {
    safe.add('Local peer identity provisioning warnings truncated.');
  }
  return List<String>.unmodifiable(safe);
}

class NativeLocalPeerIdentityProvisioner {
  NativeLocalPeerIdentityProvisioner({
    required NativeLocalPeerIdentityLoader loader,
    required NativeLocalPeerIdentityWriter writer,
    AppLocalPeerIdentityFactory? identityFactory,
    LocalNetworkPeerAnnouncer? networkAnnouncer,
    int announcedPort = LocalNetworkChannelContract.defaultAdvertisedPort,
  }) : _loader = loader,
       _writer = writer,
       _identityFactory = identityFactory ?? _securePeerId,
       _networkAnnouncer = networkAnnouncer,
       _announcedPort = _validateAnnouncedPort(announcedPort);

  factory NativeLocalPeerIdentityProvisioner.methodChannel({
    String namespace = NativeLocalPeerIdentityLoader.defaultNamespace,
    LocalNetworkPeerAnnouncer? networkAnnouncer,
    int announcedPort = LocalNetworkChannelContract.defaultAdvertisedPort,
  }) {
    final bridge = MethodChannelSecureKeyStorageBridge();
    return NativeLocalPeerIdentityProvisioner(
      loader: NativeLocalPeerIdentityLoader(
        bridge: bridge,
        namespace: namespace,
      ),
      writer: NativeLocalPeerIdentityWriter(
        bridge: bridge,
        namespace: namespace,
      ),
      networkAnnouncer: networkAnnouncer ?? MethodChannelLocalNetworkBridge(),
      announcedPort: announcedPort,
    );
  }

  final NativeLocalPeerIdentityLoader _loader;
  final NativeLocalPeerIdentityWriter _writer;
  final AppLocalPeerIdentityFactory _identityFactory;
  final LocalNetworkPeerAnnouncer? _networkAnnouncer;
  final int _announcedPort;
  Future<AppLocalPeerIdentityProvisionResult>? _inFlight;

  Future<AppLocalPeerIdentityProvisionResult> ensureIdentity({
    Future<void>? cancellation,
  }) {
    final inFlight = _inFlight;
    if (inFlight != null && cancellation == null) return inFlight;

    final operation = _ensureIdentity(cancellation: cancellation);
    if (cancellation == null) {
      _inFlight = operation;
      unawaited(
        operation.then<void>(
          (_) => _clearInFlight(operation),
          onError: (Object _, StackTrace _) => _clearInFlight(operation),
        ),
      );
    }
    return operation;
  }

  void _clearInFlight(Future<AppLocalPeerIdentityProvisionResult> operation) {
    if (identical(_inFlight, operation)) {
      _inFlight = null;
    }
  }

  Future<AppLocalPeerIdentityProvisionResult> _ensureIdentity({
    Future<void>? cancellation,
  }) async {
    if (await _isCancellationRequested(cancellation)) {
      return _cancelledProvisionResult();
    }
    final loaded = await _loader.load(cancellation: cancellation);
    if (await _isCancellationRequested(cancellation)) {
      return _cancelledProvisionResult();
    }
    if (loaded.warnings.isNotEmpty) {
      return AppLocalPeerIdentityProvisionResult(warnings: loaded.warnings);
    }
    if (loaded.identity != null) {
      return _withAnnouncement(
        identity: loaded.identity!,
        cancellation: cancellation,
      );
    }

    final String peerId;
    try {
      peerId = _identityFactory();
    } on Object {
      return AppLocalPeerIdentityProvisionResult(
        warnings: <String>['Local peer identity generation failed.'],
      );
    }

    if (await _isCancellationRequested(cancellation)) {
      return _cancelledProvisionResult();
    }

    final identity = AppLocalPeerIdentity(peerId: peerId);
    final saved = await _writer.save(
      identity,
      expectedRevision: loaded.revision,
      cancellation: cancellation,
    );
    if (await _isCancellationRequested(cancellation)) {
      return _cancelledProvisionResult();
    }
    if (!saved.isSuccess) {
      if (saved.isConflict) {
        final competing = await _loader.load(cancellation: cancellation);
        if (await _isCancellationRequested(cancellation)) {
          return _cancelledProvisionResult();
        }
        if (competing.isAvailable) {
          return _withAnnouncement(
            identity: competing.identity!,
            cancellation: cancellation,
          );
        }
      }
      return AppLocalPeerIdentityProvisionResult(
        warnings: <String>[saved.warning ?? 'Local peer identity save failed.'],
      );
    }
    final verified = await _loader.load(cancellation: cancellation);
    if (await _isCancellationRequested(cancellation)) {
      return _cancelledProvisionResult();
    }
    if (verified.warnings.isNotEmpty ||
        verified.identity?.peerId != identity.peerId) {
      return AppLocalPeerIdentityProvisionResult(
        warnings: <String>[
          'Local peer identity persistence could not be verified.',
        ],
      );
    }
    if (await _isCancellationRequested(cancellation)) {
      return _cancelledProvisionResult();
    }
    return _withAnnouncement(
      identity: identity,
      created: true,
      cancellation: cancellation,
    );
  }

  Future<AppLocalPeerIdentityProvisionResult> _withAnnouncement({
    required AppLocalPeerIdentity identity,
    required Future<void>? cancellation,
    bool created = false,
  }) async {
    await _announce(identity.peerId, cancellation: cancellation);
    if (await _isCancellationRequested(cancellation)) {
      return _cancelledProvisionResult();
    }
    return AppLocalPeerIdentityProvisionResult(
      identity: identity,
      created: created,
    );
  }

  Future<void> _announce(
    String peerId, {
    required Future<void>? cancellation,
  }) async {
    final announcer = _networkAnnouncer;
    if (announcer == null || await _isCancellationRequested(cancellation)) {
      return;
    }
    try {
      if (announcer is CancellableLocalNetworkPeerAnnouncer) {
        final cancellableAnnouncer =
            announcer as CancellableLocalNetworkPeerAnnouncer;
        await cancellableAnnouncer.announcePeer(
          peerId: peerId,
          port: _announcedPort,
          cancellation: cancellation,
        );
      } else {
        await announcer.announcePeer(peerId: peerId, port: _announcedPort);
      }
    } on Object {
      // Local discovery is optional; the verified identity remains usable.
    }
  }

  AppLocalPeerIdentityProvisionResult _cancelledProvisionResult() {
    return AppLocalPeerIdentityProvisionResult(
      warnings: <String>['Local peer identity provisioning cancelled.'],
    );
  }

  static String _securePeerId() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return 'peer_${base64UrlEncode(bytes).replaceAll('=', '')}';
  }

  static int _validateAnnouncedPort(int port) {
    if (port < 1 || port > 65535) {
      throw ArgumentError.value(port, 'announcedPort', 'must be a valid port');
    }
    return port;
  }
}

Future<bool> _isCancellationRequested(Future<void>? cancellation) async {
  if (cancellation == null) return false;
  var requested = false;
  cancellation.then<void>(
    (_) => requested = true,
    onError: (Object _, StackTrace _) => requested = true,
  );
  await Future<void>.value();
  return requested;
}
