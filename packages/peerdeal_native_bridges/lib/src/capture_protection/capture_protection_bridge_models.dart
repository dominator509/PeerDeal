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
