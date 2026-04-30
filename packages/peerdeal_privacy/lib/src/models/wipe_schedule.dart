class WipeSchedule {
  const WipeSchedule({
    required this.mode,
    required this.timedWipeSeconds,
    required this.durableExportAllowed,
    required this.ephemeralExportOnly,
  });

  final String mode;
  final int? timedWipeSeconds;
  final bool durableExportAllowed;
  final bool ephemeralExportOnly;
}
