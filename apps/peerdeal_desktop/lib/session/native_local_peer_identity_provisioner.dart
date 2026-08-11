import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

import 'native_local_peer_identity_loader.dart';
import 'native_local_peer_identity_writer.dart';

typedef AppLocalPeerIdentityFactory = String Function();

class AppLocalPeerIdentityProvisionResult {
  const AppLocalPeerIdentityProvisionResult({
    this.identity,
    this.warnings = const <String>[],
    this.created = false,
  });

  final AppLocalPeerIdentity? identity;
  final List<String> warnings;
  final bool created;

  bool get isSuccess => identity != null && warnings.isEmpty;
}

class NativeLocalPeerIdentityProvisioner {
  NativeLocalPeerIdentityProvisioner({
    required NativeLocalPeerIdentityLoader loader,
    required NativeLocalPeerIdentityWriter writer,
    AppLocalPeerIdentityFactory? identityFactory,
  }) : _loader = loader,
       _writer = writer,
       _identityFactory = identityFactory ?? _securePeerId;

  factory NativeLocalPeerIdentityProvisioner.methodChannel({
    String namespace = NativeLocalPeerIdentityLoader.defaultNamespace,
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
    );
  }

  final NativeLocalPeerIdentityLoader _loader;
  final NativeLocalPeerIdentityWriter _writer;
  final AppLocalPeerIdentityFactory _identityFactory;
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
    final loaded = await _loader.load(cancellation: cancellation);
    if (loaded.warnings.isNotEmpty) {
      return AppLocalPeerIdentityProvisionResult(warnings: loaded.warnings);
    }
    if (loaded.identity != null) {
      return AppLocalPeerIdentityProvisionResult(identity: loaded.identity);
    }

    final String peerId;
    try {
      peerId = _identityFactory();
    } on Object {
      return const AppLocalPeerIdentityProvisionResult(
        warnings: <String>['Local peer identity generation failed.'],
      );
    }

    final identity = AppLocalPeerIdentity(peerId: peerId);
    final saved = await _writer.save(
      identity,
      expectedRevision: loaded.revision,
      cancellation: cancellation,
    );
    if (!saved.isSuccess) {
      if (saved.isConflict) {
        final competing = await _loader.load(cancellation: cancellation);
        if (competing.isAvailable) {
          return AppLocalPeerIdentityProvisionResult(
            identity: competing.identity,
          );
        }
      }
      return AppLocalPeerIdentityProvisionResult(
        warnings: <String>[
          saved.warning ?? 'Local peer identity save failed.',
        ],
      );
    }
    final verified = await _loader.load(cancellation: cancellation);
    if (verified.warnings.isNotEmpty ||
        verified.identity?.peerId != identity.peerId) {
      return const AppLocalPeerIdentityProvisionResult(
        warnings: <String>[
          'Local peer identity persistence could not be verified.',
        ],
      );
    }
    return AppLocalPeerIdentityProvisionResult(
      identity: identity,
      created: true,
    );
  }

  static String _securePeerId() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return 'peer_${base64UrlEncode(bytes).replaceAll('=', '')}';
  }
}
