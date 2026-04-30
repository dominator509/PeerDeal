import '../contracts/retention_policy_engine.dart';
import '../models/retention_mode.dart';
import '../models/retention_policy.dart';
import '../models/wipe_schedule.dart';

class DefaultRetentionPolicyEngine implements RetentionPolicyEngine {
  const DefaultRetentionPolicyEngine();

  @override
  WipeSchedule deriveWipeSchedule(RetentionPolicy policy) {
    if (policy.mode == RetentionMode.strictEphemeral) {
      return const WipeSchedule(
        mode: 'strict_ephemeral',
        timedWipeSeconds: 0,
        durableExportAllowed: false,
        ephemeralExportOnly: true,
      );
    }
    return policy.wipeSchedule;
  }

  @override
  bool canRestore(RetentionPolicy policy) {
    if (policy.mode == RetentionMode.strictEphemeral) {
      return false;
    }
    return policy.allowSessionRestore || policy.allowUserRestore;
  }

  @override
  bool isWipeDue({
    required RetentionPolicy policy,
    required DateTime sessionClosedAt,
    required DateTime now,
  }) {
    final schedule = deriveWipeSchedule(policy);
    final seconds = schedule.timedWipeSeconds;
    if (seconds == null) {
      return false;
    }
    return now.isAfter(sessionClosedAt.add(Duration(seconds: seconds))) ||
        now.isAtSameMomentAs(sessionClosedAt.add(Duration(seconds: seconds)));
  }
}
