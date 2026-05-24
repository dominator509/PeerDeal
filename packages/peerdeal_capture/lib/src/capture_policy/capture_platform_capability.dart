import 'package:meta/meta.dart';

@immutable
class CapturePlatformCapability {
  const CapturePlatformCapability({
    required this.supportsBlocking,
    required this.supportsObscuring,
    this.warning,
  });

  const CapturePlatformCapability.none({this.warning})
    : supportsBlocking = false,
      supportsObscuring = false;

  final bool supportsBlocking;
  final bool supportsObscuring;
  final String? warning;
}
