import 'package:peerdeal_network/peerdeal_network.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'app_holdem_table_session_runtime.dart';

class AppHoldemProjectionPublishResult {
  AppHoldemProjectionPublishResult._({
    required this.isComplete,
    required this.sentEventCount,
    required this.totalEventCount,
    this.reasonCode,
    List<String> warnings = const <String>[],
  }) : warnings = List<String>.unmodifiable(warnings);

  AppHoldemProjectionPublishResult.complete({required int totalEventCount})
    : this._(
        isComplete: true,
        sentEventCount: totalEventCount,
        totalEventCount: totalEventCount,
      );

  AppHoldemProjectionPublishResult.rejected({
    required String reasonCode,
    required int totalEventCount,
    int sentEventCount = 0,
    List<String> warnings = const <String>[],
  }) : this._(
         isComplete: false,
         sentEventCount: sentEventCount,
         totalEventCount: totalEventCount,
         reasonCode: reasonCode,
         warnings: warnings,
       );

  final bool isComplete;
  final int sentEventCount;
  final int totalEventCount;
  final String? reasonCode;
  final List<String> warnings;

  bool get isPartial => sentEventCount > 0 && !isComplete;
}

/// Encodes accepted Hold'em projection events into the canonical transport
/// frame contract. The runtime commits first; callers can retry a rejected or
/// partial publish without re-running variant rules.
class AppHoldemProjectionTransportPublisher {
  AppHoldemProjectionTransportPublisher({
    required TransportFrameSender sender,
    required String localPeerId,
    required String remotePeerId,
    EventEnvelopeCodec codec = const EventEnvelopeCodec(),
  }) : _sender = sender,
       _localPeerId = localPeerId,
       _remotePeerId = remotePeerId,
       _codec = codec;

  final TransportFrameSender _sender;
  final String _localPeerId;
  final String _remotePeerId;
  final EventEnvelopeCodec _codec;

  Future<AppHoldemProjectionPublishResult> publish(
    AppHoldemProjectionResult projection,
  ) async {
    final events = projection.events;
    if (!projection.isApplied) {
      return AppHoldemProjectionPublishResult.rejected(
        reasonCode: 'ERR_HOLDEM_PROJECTION_NOT_APPLIED',
        totalEventCount: events.length,
      );
    }
    if (events.isEmpty) {
      return AppHoldemProjectionPublishResult.rejected(
        reasonCode: 'ERR_HOLDEM_PROJECTION_EMPTY',
        totalEventCount: 0,
      );
    }
    if (!_isValidPeerId(_localPeerId) || !_isValidPeerId(_remotePeerId)) {
      return AppHoldemProjectionPublishResult.rejected(
        reasonCode: 'ERR_HOLDEM_PROJECTION_PEER_ID_INVALID',
        totalEventCount: events.length,
      );
    }

    var sentEventCount = 0;
    for (final event in events) {
      if (event.tableId != projection.projection.coreState.tableId ||
          event.sessionId != projection.projection.coreState.sessionId ||
          event.protocolVersion !=
              projection.projection.coreState.protocolVersion) {
        return AppHoldemProjectionPublishResult.rejected(
          reasonCode: 'ERR_HOLDEM_PROJECTION_EVENT_SCOPE_MISMATCH',
          totalEventCount: events.length,
          sentEventCount: sentEventCount,
        );
      }

      final List<int> payload;
      try {
        payload = _codec.encode(event);
      } on Object {
        return AppHoldemProjectionPublishResult.rejected(
          reasonCode: 'ERR_HOLDEM_PROJECTION_ENCODING_FAILED',
          totalEventCount: events.length,
          sentEventCount: sentEventCount,
        );
      }

      final TransportFrameSendResult result;
      try {
        result = await _sender.send(
          TransportFrame(
            sessionId: event.sessionId,
            fromPeerId: _localPeerId,
            toPeerId: _remotePeerId,
            sequence: event.eventSeq,
            payload: payload,
          ),
        );
      } on Object {
        return AppHoldemProjectionPublishResult.rejected(
          reasonCode: 'ERR_HOLDEM_PROJECTION_TRANSPORT_SEND_FAILED',
          totalEventCount: events.length,
          sentEventCount: sentEventCount,
        );
      }

      if (!result.sent) {
        return AppHoldemProjectionPublishResult.rejected(
          reasonCode: _safeReasonCode(result.reasonCode),
          totalEventCount: events.length,
          sentEventCount: sentEventCount,
          warnings: _safeWarnings(result.warnings),
        );
      }
      sentEventCount++;
    }

    return AppHoldemProjectionPublishResult.complete(
      totalEventCount: events.length,
    );
  }

  static bool _isValidPeerId(String value) {
    return value.trim().isNotEmpty &&
        value == value.trim() &&
        !value.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f);
  }

  static String _safeReasonCode(String value) {
    if (value.isNotEmpty &&
        value.length <= 96 &&
        RegExp(r'^[A-Z0-9_]+$').hasMatch(value)) {
      return value;
    }
    return 'ERR_HOLDEM_PROJECTION_TRANSPORT_REJECTED';
  }

  static List<String> _safeWarnings(Iterable<String> warnings) {
    final safe = <String>[];
    for (final warning in warnings) {
      if (safe.length == 4) break;
      if (warning.isEmpty ||
          warning.length > 160 ||
          warning.trim() != warning ||
          warning.codeUnits.any((unit) => unit < 0x20 || unit == 0x7f)) {
        safe.add('Holdem projection transport warning unavailable.');
      } else {
        safe.add(warning);
      }
    }
    return safe;
  }
}
