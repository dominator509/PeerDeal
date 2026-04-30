import 'package:meta/meta.dart';

@immutable
class CoreCommand {
  const CoreCommand({
    required this.commandId,
    required this.commandType,
    required this.actorRef,
    required this.payload,
  });

  final String commandId;
  final String commandType;
  final String actorRef;
  final Map<String, Object?> payload;
}
