import 'message_retention_policy.dart';

class DisappearingPolicy {
  const DisappearingPolicy({
    required this.disappearingChatEnabled,
    required this.disappearingSessionMode,
    required this.messageRetentionPolicy,
  });

  final bool disappearingChatEnabled;
  final bool disappearingSessionMode;
  final MessageRetentionPolicy messageRetentionPolicy;
}
