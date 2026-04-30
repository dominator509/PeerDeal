import 'package:meta/meta.dart';

@immutable
class CoreEvent {
  const CoreEvent({
    required this.eventId,
    required this.eventType,
    required this.actorRef,
    required this.payload,
  });

  final String eventId;
  final String eventType;
  final String actorRef;
  final Map<String, Object?> payload;
}
