import 'package:peerdeal_capture/peerdeal_capture.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';

class CaptureSurfacePlan {
  const CaptureSurfacePlan({
    required this.surface,
    required this.decision,
    required this.nativeNotes,
  });

  final CaptureSurface surface;
  final CapturePolicyDecision decision;
  final String nativeNotes;

  bool get shouldRequestNativeBlocking => decision.asksNativeBridgeToBlock;
  bool get shouldObscure => decision.requiresVisualObscuring;
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
        warning: nativeCapability.warning,
      ),
    );

    return CaptureSurfacePlan(
      surface: surface,
      decision: decision,
      nativeNotes: nativeCapability.notes,
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
}
