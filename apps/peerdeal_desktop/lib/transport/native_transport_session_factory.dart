import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_network/peerdeal_network.dart';

import 'app_table_session_transport_source.dart';
import 'native_transport_frame_adapter.dart';

const _maximumWarningCount = 4;
const _maximumWarningLength = 160;

class NativeTransportSessionFactory {
  NativeTransportSessionFactory({
    NativeTransportBridge? bridge,
    int maxPayloadBytes = 64 * 1024,
    TransportFrameValidator? validator,
    Future<void>? cancellation,
  }) : _bridge = bridge,
       _maxPayloadBytes = maxPayloadBytes,
       _cancellation = cancellation,
       _validator =
           validator ??
           BasicTransportFrameValidator(maxPayloadBytes: maxPayloadBytes);

  final NativeTransportBridge? _bridge;
  final int _maxPayloadBytes;
  final Future<void>? _cancellation;
  final TransportFrameValidator _validator;

  Future<NativeTransportSessionLoadResult> loadSession({
    required TransportFrameHandler handler,
  }) async {
    if (_maxPayloadBytes < 1) {
      return NativeTransportSessionLoadResult.unavailable(
        warnings: <String>['App transport payload limit is invalid.'],
      );
    }

    final bridge = _resolvedBridge;
    final NativeTransportCapability capability;
    try {
      capability = await bridge.getCapability();
    } on Object {
      return NativeTransportSessionLoadResult.unavailable(
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
      return NativeTransportSessionLoadResult.unavailable(
        warnings: <String>['Native transport payload limit is invalid.'],
      );
    }
    if (capability.maxPayloadBytes > _maxPayloadBytes) {
      return NativeTransportSessionLoadResult.unavailable(
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
        cancellation: _cancellation,
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
      return _UnavailableTransportFrameSender(
        warnings: <String>['App transport payload limit is invalid.'],
      );
    }
    return ValidatingTransportFrameSender(
      sink: NativeTransportFrameSink(bridge: bridge, validator: _validator),
      validator: _validator,
    );
  }

  NativeTransportFrameDrain _createDrain({
    required NativeTransportBridge bridge,
    required TransportFrameHandler handler,
  }) {
    if (_maxPayloadBytes < 1) {
      return NativeTransportFrameDrain.unavailable(
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
    return _bridge ??
        MethodChannelNativeTransportBridge(cancellation: _cancellation);
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
    final lower = normalized.toLowerCase();
    if (lower.contains('secret') ||
        lower.contains('token') ||
        lower.contains('password') ||
        normalized.contains('\\')) {
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
  _UnavailableTransportFrameSender({required List<String> warnings})
    : warnings = _safeNativeTransportWarnings(warnings);

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
    this.cancellation,
  });

  final TransportFrameSender sender;
  final NativeTransportFrameDrain drain;
  final int maxPayloadBytes;
  final String nativeNotes;
  final Future<void>? cancellation;

  AppTableSessionTransportSource createSource({
    required String sessionId,
    required String peerId,
    Duration pollInterval = const Duration(seconds: 1),
    NativeTransportSourceTimerFactory? timerFactory,
    Future<void>? cancellation,
  }) {
    return AppTableSessionTransportSource(
      drain: () => drain.drain(
        sessionId: sessionId,
        peerId: peerId,
        cancellation: cancellation ?? this.cancellation,
      ),
      drainWithCancellation: (sourceCancellation) => drain.drain(
        sessionId: sessionId,
        peerId: peerId,
        cancellation: sourceCancellation,
      ),
      sessionId: sessionId,
      peerId: peerId,
      pollInterval: pollInterval,
      timerFactory: timerFactory,
      cancellation: cancellation ?? this.cancellation,
    );
  }
}

class NativeTransportSessionLoadResult {
  NativeTransportSessionLoadResult({
    required this.available,
    required this.session,
    List<String> warnings = const <String>[],
  }) : warnings = _safeNativeTransportWarnings(warnings);

  NativeTransportSessionLoadResult.available({
    required NativeTransportSession session,
    List<String> warnings = const <String>[],
  }) : this(available: true, session: session, warnings: warnings);

  NativeTransportSessionLoadResult.unavailable({
    List<String> warnings = const <String>[],
  }) : this(available: false, session: null, warnings: warnings);

  final bool available;
  final NativeTransportSession? session;
  final List<String> warnings;
}

List<String> _safeNativeTransportWarnings(List<String> warnings) {
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
              warning.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)
          ? 'Native transport session warning unavailable.'
          : warning,
    );
  }
  if (truncated) {
    safe.add('Native transport session warnings truncated.');
  }
  return List<String>.unmodifiable(safe);
}
