import 'capture_protection_bridge_models.dart';

abstract interface class CaptureProtectionBridge {
  Future<CaptureProtectionCapability> getCapability();
}
