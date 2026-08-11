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

  Future<AppLocalPeerIdentityProvisionResult> ensureIdentity() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final operation = _ensureIdentity();
    _inFlight = operation;
    return operation;
  }

  Future<AppLocalPeerIdentityProvisionResult> _ensureIdentity() async {
    try {
      final loaded = await _loader.load();
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
      final saved = await _writer.save(identity);
      if (!saved.isSuccess) {
        return AppLocalPeerIdentityProvisionResult(
          warnings: <String>[
            saved.warning ?? 'Local peer identity save failed.',
          ],
        );
      }
      return AppLocalPeerIdentityProvisionResult(
        identity: identity,
        created: true,
      );
    } finally {
      _inFlight = null;
    }
  }

  static String _securePeerId() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return 'peer_${base64UrlEncode(bytes).replaceAll('=', '')}';
  }
}
