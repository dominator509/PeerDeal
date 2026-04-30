class DemoStatusBannerVm {
  final String label;
  final String severity;
  final bool visible;

  const DemoStatusBannerVm({
    required this.label,
    required this.severity,
    required this.visible,
  });
}

class DemoReceiptSummaryVm {
  final String verificationState;
  final String retentionMode;
  final String bindingMode;

  const DemoReceiptSummaryVm({
    required this.verificationState,
    required this.retentionMode,
    required this.bindingMode,
  });
}

class DemoChatSummaryVm {
  final int unreadCount;
  final bool disappearingEnabled;

  const DemoChatSummaryVm({
    required this.unreadCount,
    required this.disappearingEnabled,
  });
}
