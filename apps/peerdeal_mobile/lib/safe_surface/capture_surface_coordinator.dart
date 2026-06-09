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
  const CaptureSurfaceCoordinator({
    required CaptureProtectionBridge bridge,
    DefaultCapturePolicyResolver policyResolver =
        const DefaultCapturePolicyResolver(),
  }) : _bridge = bridge,
       _policyResolver = policyResolver;

  final CaptureProtectionBridge _bridge;
  final DefaultCapturePolicyResolver _policyResolver;

  Future<CaptureSurfacePlan> resolve(CaptureSurface surface) async {
    final nativeCapability = await _loadNativeCapability();
    final decision = _policyResolver.resolve(
      surface: surface,
      capability: CapturePlatformCapability(
        supportsBlocking: nativeCapability.blockingSupported,
        supportsObscuring: nativeCapability.obscuringSupported,
        warning: _safeWarning(nativeCapability.warning),
      ),
    );

    return CaptureSurfacePlan(
      surface: surface,
      decision: decision,
      nativeNotes: _safeNotes(nativeCapability.notes),
    );
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
