import 'disappearing_policy.dart';
import 'manual_wipe_confirmation.dart';
import 'metadata_minimization_profile.dart';
import 'retention_mode.dart';
import 'wipe_schedule.dart';

class RetentionPolicy {
  const RetentionPolicy({
    required this.mode,
    required this.wipeSchedule,
    required this.manualWipeConfirmation,
    required this.allowSessionRestore,
    required this.allowUserRestore,
    required this.disappearingPolicy,
    required this.metadataProfile,
  });

  final RetentionMode mode;
  final WipeSchedule wipeSchedule;
  final ManualWipeConfirmation manualWipeConfirmation;
  final bool allowSessionRestore;
  final bool allowUserRestore;
  final DisappearingPolicy disappearingPolicy;
  final MetadataMinimizationProfile metadataProfile;
}
