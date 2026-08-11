import 'capture_protection_bridge_models.dart';

abstract interface class CaptureProtectionBridge {
  Future<CaptureProtectionCapability> getCapability();
}

/// Optional cancellation capability for callers that own a route lifecycle.
///
/// The base bridge remains unchanged for existing integrations; callers can
/// detect this capability before passing route cancellation through.
abstract interface class CancellableCaptureProtectionBridge {
  Future<CaptureProtectionCapability> getCapability({
    Future<void>? cancellation,
  });
}

abstract interface class CaptureProtectionActionBridge {
  Future<CaptureProtectionActionResult> setBlocking({required bool enabled});
}

/// Optional cancellation capability for native capture actions.
abstract interface class CancellableCaptureProtectionActionBridge {
  Future<CaptureProtectionActionResult> setBlocking({
    required bool enabled,
    Future<void>? cancellation,
  });
}
