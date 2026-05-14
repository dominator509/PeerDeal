import 'demo_view_models.dart';

class DemoScenarioSnapshot {
  const DemoScenarioSnapshot({
    required this.scenarioId,
    required this.mode,
    required this.variant,
    required this.networkConfidence,
    required this.statusBanner,
    required this.chat,
    required this.receipt,
  });

  final String scenarioId;
  final String mode;
  final String variant;
  final String networkConfidence;
  final DemoStatusBannerVm statusBanner;
  final DemoChatSummaryVm chat;
  final DemoReceiptSummaryVm receipt;

  factory DemoScenarioSnapshot.fromJson(Map<String, Object?> json) {
    return DemoScenarioSnapshot(
      scenarioId: _string(json, 'scenario_id'),
      mode: _string(json, 'mode'),
      variant: _string(json, 'variant'),
      networkConfidence: _string(json, 'network_confidence'),
      statusBanner: _statusBanner(_map(json, 'status_banner')),
      chat: _chat(_map(json, 'chat')),
      receipt: _receipt(_map(json, 'receipt')),
    );
  }

  static DemoStatusBannerVm _statusBanner(Map<String, Object?> json) {
    return DemoStatusBannerVm(
      label: _string(json, 'label'),
      severity: _string(json, 'severity'),
      visible: _bool(json, 'visible'),
    );
  }

  static DemoChatSummaryVm _chat(Map<String, Object?> json) {
    return DemoChatSummaryVm(
      unreadCount: _int(json, 'unread_count'),
      disappearingEnabled: _bool(json, 'disappearing_enabled'),
    );
  }

  static DemoReceiptSummaryVm _receipt(Map<String, Object?> json) {
    return DemoReceiptSummaryVm(
      verificationState: _string(json, 'verification_state'),
      retentionMode: _string(json, 'retention_mode'),
      bindingMode: _string(json, 'binding_mode'),
    );
  }

  static Map<String, Object?> _map(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is Map<String, Object?>) {
      return value;
    }

    throw FormatException('Expected object at $key.');
  }

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }

    throw FormatException('Expected string at $key.');
  }

  static bool _bool(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is bool) {
      return value;
    }

    throw FormatException('Expected bool at $key.');
  }

  static int _int(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }

    throw FormatException('Expected int at $key.');
  }
}
