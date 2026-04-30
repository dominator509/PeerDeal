class ModeIdentity {
  const ModeIdentity({
    required this.modeId,
    required this.modeFamily,
    required this.displayName,
    required this.adapterVersion,
    required this.protocolVersionRange,
    required this.gameFileVersionRange,
  });

  final String modeId;
  final String modeFamily;
  final String displayName;
  final String adapterVersion;
  final String protocolVersionRange;
  final String gameFileVersionRange;
}
