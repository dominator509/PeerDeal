import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';

import 'native_transport_frame_adapter.dart';

class NativeTransportSessionFactory {
  NativeTransportSessionFactory({
    NativeTransportBridge? bridge,
    int maxPayloadBytes = 64 * 1024,
    TransportFrameValidator? validator,
  }) : _bridge = bridge,
       _maxPayloadBytes = maxPayloadBytes,
       _validator =
           validator ??
           BasicTransportFrameValidator(maxPayloadBytes: maxPayloadBytes);

  final NativeTransportBridge? _bridge;
  final int _maxPayloadBytes;
  final TransportFrameValidator _validator;

  Future<NativeTransportSessionLoadResult> loadSession({
    required TransportFrameHandler handler,
  }) async {
    if (_maxPayloadBytes < 1) {
      return const NativeTransportSessionLoadResult.unavailable(
        warnings: <String>['App transport payload limit is invalid.'],
      );
    }

    final bridge = _resolvedBridge;
    final NativeTransportCapability capability;
    try {
      capability = await bridge.getCapability();
    } on Object {
      return const NativeTransportSessionLoadResult.unavailable(
        warnings: <String>['Native transport capability could not be loaded.'],
      );
    }

    if (!capability.available ||
        !capability.sendSupported ||
        !capability.receiveSupported) {
      return NativeTransportSessionLoadResult.unavailable(
        warnings: <String>[
          _safeNativeWarning(
            capability.warning,
            fallback: 'Native transport session unavailable.',
          ),
        ],
      );
    }
    if (capability.maxPayloadBytes < 1) {
      return const NativeTransportSessionLoadResult.unavailable(
        warnings: <String>['Native transport payload limit is invalid.'],
      );
    }
    if (capability.maxPayloadBytes > _maxPayloadBytes) {
      return const NativeTransportSessionLoadResult.unavailable(
        warnings: <String>[
          'Native transport payload limit exceeds app validator limit.',
        ],
      );
    }

    return NativeTransportSessionLoadResult.available(
      session: NativeTransportSession(
        sender: _createSender(bridge),
        drain: _createDrain(bridge: bridge, handler: handler),
        maxPayloadBytes: capability.maxPayloadBytes,
        nativeNotes: _safeNativeNotes(capability.notes),
      ),
      warnings: capability.warning == null
          ? const <String>[]
          : <String>[
              _safeNativeWarning(
                capability.warning,
                fallback: 'Native transport session warning.',
              ),
            ],
    );
  }

  TransportFrameSender createSender() {
    return _createSender(_resolvedBridge);
  }

  NativeTransportFrameDrain createDrain({
    required TransportFrameHandler handler,
  }) {
    return _createDrain(bridge: _resolvedBridge, handler: handler);
  }

  TransportFrameSender _createSender(NativeTransportBridge bridge) {
    if (_maxPayloadBytes < 1) {
      return const _UnavailableTransportFrameSender(
        warnings: <String>['App transport payload limit is invalid.'],
      );
    }
    return ValidatingTransportFrameSender(
      sink: NativeTransportFrameSink(bridge: bridge),
      validator: _validator,
    );
  }

  NativeTransportFrameDrain _createDrain({
    required NativeTransportBridge bridge,
    required TransportFrameHandler handler,
  }) {
    if (_maxPayloadBytes < 1) {
      return const NativeTransportFrameDrain.unavailable(
        warnings: <String>['App transport payload limit is invalid.'],
      );
    }
    return NativeTransportFrameDrain(
      bridge: bridge,
      receiver: ValidatingTransportFrameReceiver(
        handler: handler,
        validator: _validator,
      ),
    );
  }

  NativeTransportBridge get _resolvedBridge {
    return _bridge ?? MethodChannelNativeTransportBridge();
  }

  static String _safeNativeWarning(
    String? warning, {
    required String fallback,
  }) {
    if (warning == null || warning.trim().isEmpty) {
      return fallback;
    }
    return 'Native transport reported a platform warning.';
  }

  static String _safeNativeNotes(String notes) {
    final normalized = notes
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return 'unavailable';
    }
    const maxLength = 96;
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return normalized.substring(0, maxLength);
  }
}

class _UnavailableTransportFrameSender implements TransportFrameSender {
  const _UnavailableTransportFrameSender({required this.warnings});

  final List<String> warnings;

  @override
  Future<TransportFrameSendResult> send(TransportFrame frame) async {
    return TransportFrameSendResult.rejected(
      reasonCode: 'ERR_TRANSPORT_UNAVAILABLE',
      warnings: warnings,
    );
  }
}

class NativeTransportSession {
  const NativeTransportSession({
    required this.sender,
    required this.drain,
    required this.maxPayloadBytes,
    required this.nativeNotes,
  });

  final TransportFrameSender sender;
  final NativeTransportFrameDrain drain;
  final int maxPayloadBytes;
  final String nativeNotes;
}

class NativeTransportSessionLoadResult {
  const NativeTransportSessionLoadResult({
    required this.available,
    required this.session,
    this.warnings = const <String>[],
  });

  const NativeTransportSessionLoadResult.available({
    required NativeTransportSession session,
    List<String> warnings = const <String>[],
  }) : this(available: true, session: session, warnings: warnings);

  const NativeTransportSessionLoadResult.unavailable({
    List<String> warnings = const <String>[],
  }) : this(available: false, session: null, warnings: warnings);

  final bool available;
  final NativeTransportSession? session;
  final List<String> warnings;
}
