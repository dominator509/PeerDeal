import 'model_collection_ownership.dart';

class CommandEnvelope {
  CommandEnvelope({
    required this.commandId,
    required this.commandType,
    required this.commandVersion,
    required this.protocolVersion,
    required this.tableId,
    required this.sessionId,
    required this.handId,
    required this.issuedAt,
    required this.actorRef,
    required Map<String, Object?> payload,
  }) : payload = freezeProtocolObjectMap(payload);

  final String commandId;
  final String commandType;
  final String commandVersion;
  final String protocolVersion;
  final String? tableId;
  final String? sessionId;
  final String? handId;
  final String issuedAt;
  final String actorRef;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => {
    'command_id': commandId,
    'command_type': commandType,
    'command_version': commandVersion,
    'protocol_version': protocolVersion,
    'table_id': tableId,
    'session_id': sessionId,
    'hand_id': handId,
    'issued_at': issuedAt,
    'actor_ref': actorRef,
    'payload': payload,
  };
}
