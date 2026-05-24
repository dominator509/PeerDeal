import 'package:peerdeal_capture/peerdeal_capture.dart';
import 'package:peerdeal_mobile/safe_surface/safe_surface.dart';
import 'package:peerdeal_native_bridges/peerdeal_native_bridges.dart';
import 'package:test/test.dart';

void main() {
  test(
    'requests native blocking and visual obscuring when supported',
    () async {
      final coordinator = CaptureSurfaceCoordinator(
        bridge: _FakeCaptureProtectionBridge(
          capability: const CaptureProtectionCapability(
            blockingSupported: true,
            obscuringSupported: true,
            notes: 'screen-protection-supported',
            warning: 'best-effort',
          ),
        ),
      );

      final plan = await coordinator.resolve(CaptureSurface.receiptDetail);

      expect(plan.surface, CaptureSurface.receiptDetail);
      expect(plan.shouldRequestNativeBlocking, isTrue);
      expect(plan.shouldObscure, isTrue);
      expect(plan.nativeNotes, 'screen-protection-supported');
      expect(plan.warning, 'best-effort');
    },
  );

  test('allows non-sensitive surfaces without native action', () async {
    final coordinator = CaptureSurfaceCoordinator(
      bridge: _FakeCaptureProtectionBridge(
        capability: const CaptureProtectionCapability(
          blockingSupported: true,
          obscuringSupported: true,
          notes: 'screen-protection-supported',
        ),
      ),
    );

    final plan = await coordinator.resolve(CaptureSurface.lobby);

    expect(plan.shouldRequestNativeBlocking, isFalse);
    expect(plan.shouldObscure, isFalse);
    expect(plan.nativeNotes, 'screen-protection-supported');
  });

  test('fails closed when native capability lookup throws', () async {
    final coordinator = CaptureSurfaceCoordinator(
      bridge: const _ThrowingCaptureProtectionBridge(),
    );

    final plan = await coordinator.resolve(CaptureSurface.privateLedger);

    expect(plan.shouldRequestNativeBlocking, isFalse);
    expect(plan.shouldObscure, isTrue);
    expect(plan.nativeNotes, 'unavailable');
    expect(plan.warning, contains('could not be read'));
  });
}

class _FakeCaptureProtectionBridge implements CaptureProtectionBridge {
  const _FakeCaptureProtectionBridge({required this.capability});

  final CaptureProtectionCapability capability;

  @override
  Future<CaptureProtectionCapability> getCapability() async => capability;
}

class _ThrowingCaptureProtectionBridge implements CaptureProtectionBridge {
  const _ThrowingCaptureProtectionBridge();

  @override
  Future<CaptureProtectionCapability> getCapability() async {
    throw StateError('platform channel unavailable');
  }
}
