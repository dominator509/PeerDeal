import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:peerdeal_modes/peerdeal_modes.dart';

GovernanceContext governanceContextFixture(String name) {
  final json =
      jsonDecode(File('test/fixtures/$name').readAsStringSync())
          as Map<String, Object?>;
  return GovernanceContext(
    modeId: json['modeId']! as String,
    participants: [
      for (final participant in json['participants']! as List<Object?>)
        _participantFromJson(participant! as Map<String, Object?>),
    ],
    seats: [
      for (final seat in json['seats']! as List<Object?>)
        _seatFromJson(seat! as Map<String, Object?>),
    ],
    waitlistOrdering: [
      for (final participantId in json['waitlistOrdering']! as List<Object?>)
        participantId! as String,
    ],
    allowSpectators: json['allowSpectators']! as bool,
    allowCohosts: json['allowCohosts']! as bool,
    allowMidSessionSeatPromotion: json['allowMidSessionSeatPromotion']! as bool,
  );
}

ParticipantSnapshot _participantFromJson(Map<String, Object?> json) {
  return ParticipantSnapshot(
    participantId: json['participantId']! as String,
    role: _roleKind(json['role']! as String),
    state: _participantState(json['state']! as String),
    waitlistState: _waitlistState(json['waitlistState']! as String),
  );
}

SeatSnapshot _seatFromJson(Map<String, Object?> json) {
  return SeatSnapshot(
    seatIndex: json['seatIndex']! as int,
    state: _seatState(json['state']! as String),
    occupantId: json['occupantId'] as String?,
  );
}

RoleKind _roleKind(String value) {
  return RoleKind.values.singleWhere((role) => role.wireValue == value);
}

ParticipantGovernanceState _participantState(String value) {
  return ParticipantGovernanceState.values.singleWhere(
    (state) => state.name == value,
  );
}

SeatState _seatState(String value) {
  return SeatState.values.singleWhere((state) => state.name == value);
}

WaitlistState _waitlistState(String value) {
  return WaitlistState.values.singleWhere((state) => state.name == value);
}

void main() {
  group('DefaultGovernanceEngine', () {
    const engine = DefaultGovernanceEngine();

    test('offers an empty seat deterministically', () {
      final context = GovernanceContext(
        modeId: 'open_table',
        participants: const [
          ParticipantSnapshot(
            participantId: 'host_1',
            role: RoleKind.host,
            state: ParticipantGovernanceState.seated,
            waitlistState: WaitlistState.notWaitlisted,
          ),
          ParticipantSnapshot(
            participantId: 'player_2',
            role: RoleKind.player,
            state: ParticipantGovernanceState.waitlisted,
            waitlistState: WaitlistState.waitlistActive,
          ),
        ],
        seats: const [SeatSnapshot(seatIndex: 1, state: SeatState.empty)],
        waitlistOrdering: const ['player_2'],
      );

      final decision = engine.evaluate(
        context: context,
        action: const GovernanceAction(
          type: GovernanceActionType.offerSeat,
          actorId: 'host_1',
          subjectId: 'player_2',
          seatIndex: 1,
        ),
      );

      expect(decision.allowed, isTrue);
      expect(decision.resultCode, GovernanceResultCodes.okSeatOffer);
      expect(decision.nextSeatState, SeatState.reservedPending.name);
    });

    test('denies missing seat offer acceptance', () {
      final context = GovernanceContext(
        modeId: 'open_table',
        participants: const [
          ParticipantSnapshot(
            participantId: 'player_2',
            role: RoleKind.player,
            state: ParticipantGovernanceState.admittedUnseated,
            waitlistState: WaitlistState.notWaitlisted,
          ),
        ],
        seats: const [],
      );

      final decision = engine.evaluate(
        context: context,
        action: const GovernanceAction(
          type: GovernanceActionType.acceptSeatOffer,
          actorId: 'player_2',
          subjectId: 'player_2',
        ),
      );

      expect(decision.allowed, isFalse);
      expect(decision.resultCode, GovernanceResultCodes.errSeatOfferMissing);
    });

    test('grants cohost role from fixture-backed tournament context', () {
      final context = governanceContextFixture('tournament_cohost_grant.json');

      final decision = engine.evaluate(
        context: context,
        action: const GovernanceAction(
          type: GovernanceActionType.grantCohost,
          actorId: 'host_1',
          subjectId: 'staff_2',
        ),
      );

      expect(decision.allowed, isTrue);
      expect(decision.resultCode, GovernanceResultCodes.okCohostGranted);
      expect(decision.nextParticipantRole, RoleKind.cohost.wireValue);
      expect(
        decision.nextParticipantState,
        ParticipantGovernanceState.admittedUnseated.name,
      );
    });

    test('denies cohost grant from non-host actor', () {
      final context = GovernanceContext(
        modeId: 'open_table',
        participants: const [
          ParticipantSnapshot(
            participantId: 'player_1',
            role: RoleKind.player,
            state: ParticipantGovernanceState.admittedUnseated,
            waitlistState: WaitlistState.notWaitlisted,
          ),
          ParticipantSnapshot(
            participantId: 'player_2',
            role: RoleKind.player,
            state: ParticipantGovernanceState.admittedUnseated,
            waitlistState: WaitlistState.notWaitlisted,
          ),
        ],
        seats: const [],
      );

      final decision = engine.evaluate(
        context: context,
        action: const GovernanceAction(
          type: GovernanceActionType.grantCohost,
          actorId: 'player_1',
          subjectId: 'player_2',
        ),
      );

      expect(decision.allowed, isFalse);
      expect(decision.resultCode, GovernanceResultCodes.errPermissionDenied);
    });

    test('revokes cohost role back to player deterministically', () {
      final context = GovernanceContext(
        modeId: 'open_table',
        participants: const [
          ParticipantSnapshot(
            participantId: 'host_1',
            role: RoleKind.host,
            state: ParticipantGovernanceState.seated,
            waitlistState: WaitlistState.notWaitlisted,
          ),
          ParticipantSnapshot(
            participantId: 'staff_2',
            role: RoleKind.cohost,
            state: ParticipantGovernanceState.admittedUnseated,
            waitlistState: WaitlistState.notWaitlisted,
          ),
        ],
        seats: const [],
      );

      final decision = engine.evaluate(
        context: context,
        action: const GovernanceAction(
          type: GovernanceActionType.revokeCohost,
          actorId: 'host_1',
          subjectId: 'staff_2',
        ),
      );

      expect(decision.allowed, isTrue);
      expect(decision.resultCode, GovernanceResultCodes.okCohostRevoked);
      expect(decision.nextParticipantRole, RoleKind.player.wireValue);
      expect(
        decision.nextParticipantState,
        ParticipantGovernanceState.admittedUnseated.name,
      );
    });

    test('denies cohost revoke for a non-cohost subject', () {
      final context = GovernanceContext(
        modeId: 'open_table',
        participants: const [
          ParticipantSnapshot(
            participantId: 'host_1',
            role: RoleKind.host,
            state: ParticipantGovernanceState.seated,
            waitlistState: WaitlistState.notWaitlisted,
          ),
          ParticipantSnapshot(
            participantId: 'player_2',
            role: RoleKind.player,
            state: ParticipantGovernanceState.admittedUnseated,
            waitlistState: WaitlistState.notWaitlisted,
          ),
        ],
        seats: const [],
      );

      final decision = engine.evaluate(
        context: context,
        action: const GovernanceAction(
          type: GovernanceActionType.revokeCohost,
          actorId: 'host_1',
          subjectId: 'player_2',
        ),
      );

      expect(decision.allowed, isFalse);
      expect(decision.resultCode, GovernanceResultCodes.errRoleNotAllowed);
    });

    test(
      'promotes the first active waitlist participant deterministically',
      () {
        final context = governanceContextFixture(
          'open_table_waitlist_promotion.json',
        );

        final decision = engine.evaluate(
          context: context,
          action: const GovernanceAction(
            type: GovernanceActionType.promoteFromWaitlist,
            actorId: 'host_1',
            subjectId: 'player_2',
          ),
        );

        expect(decision.allowed, isTrue);
        expect(decision.resultCode, GovernanceResultCodes.okSeatOffer);
        expect(
          decision.nextParticipantState,
          ParticipantGovernanceState.seatOffered.name,
        );
        expect(decision.nextWaitlistOrdering, isEmpty);
      },
    );

    test('denies waitlist promotion when mode policy disables it', () {
      final context = governanceContextFixture('tournament_cohost_grant.json');

      final decision = engine.evaluate(
        context: context,
        action: const GovernanceAction(
          type: GovernanceActionType.promoteFromWaitlist,
          actorId: 'host_1',
          subjectId: 'staff_2',
        ),
      );

      expect(decision.allowed, isFalse);
      expect(decision.resultCode, GovernanceResultCodes.errPermissionDenied);
    });

    test('denies promotion for a participant outside the waitlist head', () {
      final context = GovernanceContext(
        modeId: 'open_table',
        participants: const [
          ParticipantSnapshot(
            participantId: 'host_1',
            role: RoleKind.host,
            state: ParticipantGovernanceState.seated,
            waitlistState: WaitlistState.notWaitlisted,
          ),
          ParticipantSnapshot(
            participantId: 'player_2',
            role: RoleKind.player,
            state: ParticipantGovernanceState.waitlisted,
            waitlistState: WaitlistState.waitlistActive,
          ),
          ParticipantSnapshot(
            participantId: 'player_3',
            role: RoleKind.player,
            state: ParticipantGovernanceState.waitlisted,
            waitlistState: WaitlistState.waitlistActive,
          ),
        ],
        seats: const [SeatSnapshot(seatIndex: 1, state: SeatState.empty)],
        waitlistOrdering: const ['player_2', 'player_3'],
      );

      final decision = engine.evaluate(
        context: context,
        action: const GovernanceAction(
          type: GovernanceActionType.promoteFromWaitlist,
          actorId: 'host_1',
          subjectId: 'player_3',
        ),
      );

      expect(decision.allowed, isFalse);
      expect(
        decision.resultCode,
        GovernanceResultCodes.errWaitlistPromotionUnavailable,
      );
    });
  });
}
