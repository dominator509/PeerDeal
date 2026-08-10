import 'package:peerdeal_capture/peerdeal_capture.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:peerdeal_ui_kit/peerdeal_ui_kit.dart';

class CaptureSurfacePlan implements SafeSurfaceCapturePlan {
  const CaptureSurfacePlan({
    required this.surface,
    required this.decision,
    required this.nativeNotes,
  });

  final CaptureSurface surface;
  final CapturePolicyDecision decision;
  @override
  final String nativeNotes;

  @override
  bool get shouldRequestNativeBlocking => decision.asksNativeBridgeToBlock;
  @override
  bool get shouldObscure => decision.requiresVisualObscuring;
  @override
  String? get warning => decision.warning;
}

class CaptureSurfaceCoordinator {
  CaptureSurfaceCoordinator({
    required CaptureProtectionBridge bridge,
    CaptureProtectionActionBridge? actionBridge,
    DefaultCapturePolicyResolver policyResolver =
        const DefaultCapturePolicyResolver(),
  }) : _bridge = bridge,
       _actionBridge =
           actionBridge ??
           (bridge is CaptureProtectionActionBridge
               ? bridge as CaptureProtectionActionBridge
               : null),
       _policyResolver = policyResolver;

  final CaptureProtectionBridge _bridge;
  final CaptureProtectionActionBridge? _actionBridge;
  final DefaultCapturePolicyResolver _policyResolver;
  Future<void> _lastResolution = Future<void>.value();
  Future<void> _lastBlockingAction = Future<void>.value();

  Future<CaptureSurfacePlan> resolve(CaptureSurface surface) {
    final operation = _resolve(surface);
    final tracked = operation.then<void>((_) {}, onError: (_) {});
    _lastResolution = Future.wait<void>(<Future<void>>[
      _lastResolution,
      tracked,
    ]).then<void>((_) {});
    return operation;
  }

  Future<CaptureSurfacePlan> _resolve(CaptureSurface surface) async {
    final nativeCapability = await _loadNativeCapability();
    var decision = _policyResolver.resolve(
      surface: surface,
      capability: CapturePlatformCapability(
        supportsBlocking: nativeCapability.blockingSupported,
        supportsObscuring: nativeCapability.obscuringSupported,
        warning: _safeWarning(nativeCapability.warning),
      ),
    );

    if (decision.asksNativeBridgeToBlock && _actionBridge != null) {
      final action = await _queueBlocking(true);
      if (action == null || !action.isSuccess || !action.blockingEnabled) {
        decision = CapturePolicyDecision(
          action: CapturePolicyAction.obscureOnly,
          isSensitive: true,
          reason:
              'Sensitive surface is obscured because native blocking could not be applied.',
          warning:
              _safeWarning(action?.warning) ??
              'Native capture blocking could not be applied.',
        );
      }
    }

    return CaptureSurfacePlan(
      surface: surface,
      decision: decision,
      nativeNotes: _safeNotes(nativeCapability.notes),
    );
  }

  Future<CaptureProtectionActionResult?> release() async {
    if (_actionBridge == null) {
      return null;
    }
    await _lastResolution;
    return _queueBlocking(false);
  }

  Future<CaptureProtectionCapability> _loadNativeCapability() async {
    try {
      return await _bridge.getCapability();
    } catch (_) {
      return const CaptureProtectionCapability.unavailable(
        warning:
            'Capture protection capability could not be read from the platform.',
      );
    }
  }

  Future<CaptureProtectionActionResult?> _queueBlocking(bool enabled) {
    final operation = _lastBlockingAction.then(
      (_) => _safeSetBlocking(enabled),
      onError: (_) => _safeSetBlocking(enabled),
    );
    _lastBlockingAction = operation.then<void>((_) {}, onError: (_) {});
    return operation;
  }

  Future<CaptureProtectionActionResult?> _safeSetBlocking(bool enabled) async {
    try {
      return await _actionBridge!.setBlocking(enabled: enabled);
    } catch (_) {
      return const CaptureProtectionActionResult.failure(
        warning: 'Native capture blocking could not be applied.',
      );
    }
  }

  static String? _safeWarning(String? warning) {
    if (warning == null || warning.trim().isEmpty) {
      return null;
    }
    return 'Native capture protection reported a platform warning.';
  }

  static String _safeNotes(String notes) {
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
