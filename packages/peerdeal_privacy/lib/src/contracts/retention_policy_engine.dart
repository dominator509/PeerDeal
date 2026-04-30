import '../models/retention_policy.dart';
import '../models/wipe_schedule.dart';

abstract interface class RetentionPolicyEngine {
  WipeSchedule deriveWipeSchedule(RetentionPolicy policy);

  bool canRestore(RetentionPolicy policy);

  bool isWipeDue({
    required RetentionPolicy policy,
    required DateTime sessionClosedAt,
    required DateTime now,
  });
}
