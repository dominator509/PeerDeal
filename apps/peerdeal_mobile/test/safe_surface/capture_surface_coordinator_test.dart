import 'dart:async';

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
      expect(
        plan.warning,
        'Native capture protection reported a platform warning.',
      );
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

  test(
    'applies and releases native blocking when an action bridge is present',
    () async {
      final actionBridge = _RecordingCaptureProtectionActionBridge();
      final coordinator = CaptureSurfaceCoordinator(
        bridge: _FakeCaptureProtectionBridge(
          capability: const CaptureProtectionCapability(
            blockingSupported: true,
            obscuringSupported: true,
            notes: 'screen-protection-supported',
          ),
        ),
        actionBridge: actionBridge,
      );

      final plan = await coordinator.resolve(CaptureSurface.receiptDetail);
      final release = await coordinator.release();

      expect(plan.shouldRequestNativeBlocking, isTrue);
      expect(release?.isSuccess, isTrue);
      expect(actionBridge.enabledCalls, [true, false]);
    },
  );

  test('downgrades to obscuring when native blocking action fails', () async {
    final coordinator = CaptureSurfaceCoordinator(
      bridge: _FakeCaptureProtectionBridge(
        capability: const CaptureProtectionCapability(
          blockingSupported: true,
          obscuringSupported: true,
          notes: 'screen-protection-supported',
        ),
      ),
      actionBridge: _RecordingCaptureProtectionActionBridge(succeeds: false),
    );

    final plan = await coordinator.resolve(CaptureSurface.receiptDetail);

    expect(plan.shouldRequestNativeBlocking, isFalse);
    expect(plan.shouldObscure, isTrue);
    expect(
      plan.warning,
      'Native capture protection reported a platform warning.',
    );
  });

  test('release waits for an in-flight blocking resolution', () async {
    final bridge = _DeferredCaptureProtectionBridge();
    final actionBridge = _RecordingCaptureProtectionActionBridge();
    final coordinator = CaptureSurfaceCoordinator(
      bridge: bridge,
      actionBridge: actionBridge,
    );

    final resolution = coordinator.resolve(CaptureSurface.receiptDetail);
    final release = coordinator.release();
    await Future<void>.delayed(Duration.zero);

    expect(actionBridge.enabledCalls, isEmpty);

    bridge.complete();
    await resolution;
    final releaseResult = await release;

    expect(releaseResult?.isSuccess, isTrue);
    expect(actionBridge.enabledCalls, [true, false]);
  });

  test(
    'passes route cancellation to cancellable native capture calls',
    () async {
      final cancellation = Completer<void>();
      final bridge = _CancellableCaptureProtectionBridge();
      final actionBridge = _CancellableCaptureProtectionActionBridge();
      final coordinator = CaptureSurfaceCoordinator(
        bridge: bridge,
        actionBridge: actionBridge,
      );

      final plan = await coordinator.resolve(
        CaptureSurface.receiptDetail,
        cancellation: cancellation.future,
      );

      expect(plan.shouldRequestNativeBlocking, isTrue);
      expect(bridge.cancellations.single, same(cancellation.future));
      expect(actionBridge.cancellations.single, same(cancellation.future));
    },
  );

  test(
    'does not apply legacy native blocking after capability cancellation',
    () async {
      final cancellation = Completer<void>();
      final bridge = _DeferredCaptureProtectionBridge();
      final actionBridge = _RecordingCaptureProtectionActionBridge();
      final coordinator = CaptureSurfaceCoordinator(
        bridge: bridge,
        actionBridge: actionBridge,
      );

      final resolution = coordinator.resolve(
        CaptureSurface.receiptDetail,
        cancellation: cancellation.future,
      );
      cancellation.complete();
      bridge.complete();

      final plan = await resolution;

      expect(actionBridge.enabledCalls, isEmpty);
      expect(plan.shouldRequestNativeBlocking, isFalse);
      expect(plan.shouldObscure, isTrue);
      expect(plan.nativeNotes, 'unavailable');
    },
  );

  test(
    'does not start a queued legacy blocking action after cancellation',
    () async {
      final firstAction = _DeferredCaptureProtectionActionBridge();
      final coordinator = CaptureSurfaceCoordinator(
        bridge: _FakeCaptureProtectionBridge(
          capability: const CaptureProtectionCapability(
            blockingSupported: true,
            obscuringSupported: true,
            notes: 'screen-protection-supported',
          ),
        ),
        actionBridge: firstAction,
      );

      final firstResolution = coordinator.resolve(CaptureSurface.receiptDetail);
      await Future<void>.delayed(Duration.zero);
      final cancellation = Completer<void>();
      final secondResolution = coordinator.resolve(
        CaptureSurface.receiptDetail,
        cancellation: cancellation.future,
      );
      cancellation.complete();
      firstAction.complete();

      await firstResolution;
      final secondPlan = await secondResolution;

      expect(firstAction.enabledCalls, [true]);
      expect(secondPlan.shouldRequestNativeBlocking, isFalse);
      expect(secondPlan.shouldObscure, isTrue);
      expect(firstAction.enabledCalls, isNot(contains(false)));
    },
  );

  test('fails closed when native capability lookup throws', () async {
    final coordinator = CaptureSurfaceCoordinator(
      bridge: const _ThrowingCaptureProtectionBridge(),
    );

    final plan = await coordinator.resolve(CaptureSurface.privateLedger);

    expect(plan.shouldRequestNativeBlocking, isFalse);
    expect(plan.shouldObscure, isTrue);
    expect(plan.nativeNotes, 'unavailable');
    expect(
      plan.warning,
      'Native capture protection reported a platform warning.',
    );
  });

  test('scrubs native warning detail before projecting capture plan', () async {
    final coordinator = CaptureSurfaceCoordinator(
      bridge: _FakeCaptureProtectionBridge(
        capability: CaptureProtectionCapability(
          blockingSupported: false,
          obscuringSupported: true,
          notes: '${'trusted '.padRight(120, 'x')}\nsecret',
          warning: 'capture_failed: platform path C:\\secret\\screen.log',
        ),
      ),
    );

    final plan = await coordinator.resolve(CaptureSurface.receiptDetail);

    expect(
      plan.warning,
      'Native capture protection reported a platform warning.',
    );
    expect(plan.warning, isNot(contains('screen.log')));
    expect(plan.nativeNotes, 'unavailable');
    expect(plan.nativeNotes, isNot(contains('secret')));
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

class _DeferredCaptureProtectionBridge implements CaptureProtectionBridge {
  _DeferredCaptureProtectionBridge();

  final Completer<CaptureProtectionCapability> _completer =
      Completer<CaptureProtectionCapability>();

  void complete() {
    _completer.complete(
      const CaptureProtectionCapability(
        blockingSupported: true,
        obscuringSupported: true,
        notes: 'screen-protection-supported',
      ),
    );
  }

  @override
  Future<CaptureProtectionCapability> getCapability() => _completer.future;
}

class _RecordingCaptureProtectionActionBridge
    implements CaptureProtectionActionBridge {
  _RecordingCaptureProtectionActionBridge({this.succeeds = true});

  final bool succeeds;
  final List<bool> enabledCalls = <bool>[];

  @override
  Future<CaptureProtectionActionResult> setBlocking({
    required bool enabled,
  }) async {
    enabledCalls.add(enabled);
    if (!succeeds) {
      return const CaptureProtectionActionResult.failure(
        warning: 'platform action failed',
      );
    }
    return CaptureProtectionActionResult(
      isSuccess: true,
      blockingEnabled: enabled,
    );
  }
}

class _DeferredCaptureProtectionActionBridge
    implements CaptureProtectionActionBridge {
  final Completer<CaptureProtectionActionResult> _completer =
      Completer<CaptureProtectionActionResult>();
  final List<bool> enabledCalls = <bool>[];

  void complete() {
    _completer.complete(
      const CaptureProtectionActionResult(
        isSuccess: true,
        blockingEnabled: true,
      ),
    );
  }

  @override
  Future<CaptureProtectionActionResult> setBlocking({
    required bool enabled,
  }) {
    enabledCalls.add(enabled);
    return _completer.future;
  }
}

class _CancellableCaptureProtectionBridge
    implements CaptureProtectionBridge, CancellableCaptureProtectionBridge {
  final List<Future<void>?> cancellations = <Future<void>?>[];

  @override
  Future<CaptureProtectionCapability> getCapability({
    Future<void>? cancellation,
  }) async {
    cancellations.add(cancellation);
    return const CaptureProtectionCapability(
      blockingSupported: true,
      obscuringSupported: true,
      notes: 'screen-protection-supported',
    );
  }
}

class _CancellableCaptureProtectionActionBridge
    implements
        CaptureProtectionActionBridge,
        CancellableCaptureProtectionActionBridge {
  final List<Future<void>?> cancellations = <Future<void>?>[];

  @override
  Future<CaptureProtectionActionResult> setBlocking({
    required bool enabled,
    Future<void>? cancellation,
  }) async {
    cancellations.add(cancellation);
    return CaptureProtectionActionResult(
      isSuccess: true,
      blockingEnabled: enabled,
    );
  }
}
