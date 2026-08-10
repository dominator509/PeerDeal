class CaptureProtectionCapability {
  const CaptureProtectionCapability({
    required this.blockingSupported,
    required this.obscuringSupported,
    required this.notes,
    this.warning,
  });

  const CaptureProtectionCapability.unavailable({this.warning})
    : blockingSupported = false,
      obscuringSupported = false,
      notes = 'unavailable';

  final bool blockingSupported;
  final bool obscuringSupported;
  final String notes;
  final String? warning;
}

class CaptureProtectionActionResult {
  const CaptureProtectionActionResult({
    required this.isSuccess,
    required this.blockingEnabled,
    this.warning,
  });

  const CaptureProtectionActionResult.failure({required this.warning})
    : isSuccess = false,
      blockingEnabled = false;

  final bool isSuccess;
  final bool blockingEnabled;
  final String? warning;
}
