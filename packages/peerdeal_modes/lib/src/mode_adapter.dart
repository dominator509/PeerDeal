abstract interface class ModeAdapter {
  String get modeId;
  bool get supportsLiveJoin;
  bool get supportsReceipts;
  Map<String, Object?> getCapabilities();
}
