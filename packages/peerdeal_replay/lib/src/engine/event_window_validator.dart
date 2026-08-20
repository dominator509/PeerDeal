import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../models/replay_mismatch.dart';

class EventWindowValidator {
  EventWindowValidator({
    int maxEvents = defaultMaxEvents,
    this.eventHashCalculator = computeCanonicalEventHash,
  }) : _maxEvents = maxEvents {
    if (maxEvents <= 0) {
      throw ArgumentError.value(
        maxEvents,
        'maxEvents',
        'Replay event limit must be positive.',
      );
    }
  }

  static const defaultMaxEvents = 4096;

  final int _maxEvents;
  final EventHashCalculator eventHashCalculator;

  List<ReplayMismatch> validateEventCount(List<EventEnvelope> events) {
    if (events.length <= _maxEvents) {
      return const <ReplayMismatch>[];
    }

    return <ReplayMismatch>[
      ReplayMismatch(
        code: 'ERR_REPLAY_EVENT_WINDOW_TOO_LARGE',
        message: 'Replay event window exceeds the configured limit.',
        expected: _maxEvents,
        actual: events.length,
      ),
    ];
  }

  List<ReplayMismatch> validate(
    List<EventEnvelope> events, {
    int? expectedPreviousEventSeq,
  }) {
    final sizeMismatches = validateEventCount(events);
    if (sizeMismatches.isNotEmpty) {
      return sizeMismatches;
    }

    final mismatches = <ReplayMismatch>[];

    if (expectedPreviousEventSeq != null && events.isNotEmpty) {
      final expectedFirstSeq = expectedPreviousEventSeq + 1;
      if (events.first.eventSeq != expectedFirstSeq) {
        mismatches.add(
          ReplayMismatch(
            code: 'ERR_REPLAY_SNAPSHOT_SUFFIX_GAP',
            message:
                'Snapshot replay suffix does not continue from the snapshot base sequence.',
            expected: expectedFirstSeq,
            actual: events.first.eventSeq,
          ),
        );
      }
    } else if (events.isNotEmpty) {
      if (events.first.eventSeq != 1) {
        mismatches.add(
          ReplayMismatch(
            code: 'ERR_REPLAY_EVENT_WINDOW_START_GAP',
            message: 'Full replay event windows must start at event_seq 1.',
            expected: 1,
            actual: events.first.eventSeq,
          ),
        );
      }
      if (events.first.prevEventHash != genesisEventHash) {
        mismatches.add(
          ReplayMismatch(
            code: 'ERR_REPLAY_GENESIS_HASH_MISMATCH',
            message:
                'Full replay event windows must start from the genesis event hash.',
            expected: genesisEventHash,
            actual: events.first.prevEventHash,
          ),
        );
      }
    }

    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      final identityValidation = validateEventEnvelopeIdentity(event);
      if (!identityValidation.isValid) {
        mismatches.add(
          ReplayMismatch(
            code: 'ERR_REPLAY_EVENT_IDENTITY_INVALID',
            message: 'Event envelope identity is empty or unsafe.',
          ),
        );
      }
      _appendEventHashMismatch(event, mismatches);
      if (i > 0) {
        final previous = events[i - 1];
        if (event.eventSeq <= previous.eventSeq) {
          mismatches.add(
            ReplayMismatch(
              code: 'ERR_REPLAY_EVENT_SEQUENCE_NOT_INCREASING',
              message: 'Event sequence must increase monotonically.',
              expected: previous.eventSeq + 1,
              actual: event.eventSeq,
            ),
          );
        } else if (event.eventSeq != previous.eventSeq + 1) {
          mismatches.add(
            ReplayMismatch(
              code: 'ERR_REPLAY_EVENT_GAP',
              message: 'Event sequence gap detected.',
              expected: previous.eventSeq + 1,
              actual: event.eventSeq,
            ),
          );
        }
        if (event.prevEventHash != previous.eventHash) {
          mismatches.add(
            ReplayMismatch(
              code: 'ERR_REPLAY_HASH_CHAIN_BREAK',
              message: 'Event hash chain continuity failed.',
              expected: previous.eventHash,
              actual: event.prevEventHash,
            ),
          );
        }
      }
    }

    return mismatches;
  }

  void _appendEventHashMismatch(
    EventEnvelope event,
    List<ReplayMismatch> mismatches,
  ) {
    try {
      final expectedHash = eventHashCalculator(event);
      if (expectedHash == event.eventHash) return;
      mismatches.add(
        ReplayMismatch(
          code: 'ERR_REPLAY_EVENT_HASH_INVALID',
          message: 'Event content hash does not match the event envelope.',
          expected: expectedHash,
          actual: event.eventHash,
        ),
      );
    } on Object {
      mismatches.add(
        ReplayMismatch(
          code: 'ERR_REPLAY_EVENT_HASH_INVALID',
          message: 'Event content hash could not be calculated.',
          actual: event.eventHash,
        ),
      );
    }
  }
}
