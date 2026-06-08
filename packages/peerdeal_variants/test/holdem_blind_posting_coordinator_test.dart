import 'package:peerdeal_variants/peerdeal_variants.dart';
import 'package:test/test.dart';

void main() {
  const coordinator = HoldemBlindPostingCoordinator();

  HoldemHandState buildState({
    HoldemHandPhase phase = HoldemHandPhase.blindsPosting,
    int pot = 0,
    int currentBetToCall = 0,
    List<HoldemSeatState> seats = const <HoldemSeatState>[
      HoldemSeatState(
        seat: 1,
        stack: 1000,
        inHand: true,
        folded: false,
        allIn: false,
      ),
      HoldemSeatState(
        seat: 2,
        stack: 1000,
        inHand: true,
        folded: false,
        allIn: false,
      ),
      HoldemSeatState(
        seat: 3,
        stack: 1000,
        inHand: true,
        folded: false,
        allIn: false,
      ),
    ],
  }) {
    return HoldemHandState(
      handId: 'hand_001',
      phase: phase,
      bettingRound: HoldemBettingRound.preflop,
      seats: seats,
      currentActorSeat: 1,
      buttonSeat: 1,
      smallBlindSeat: 2,
      bigBlindSeat: 3,
      currentBetToCall: currentBetToCall,
      minimumRaiseAmount: 100,
      pot: pot,
    );
  }

  test('posts blinds into dealing-hole state deterministically', () {
    final result = coordinator.postBlinds(
      state: buildState(),
      smallBlindAmount: 50,
      bigBlindAmount: 100,
    );

    final smallBlind = result.state.findSeat(2)!;
    final bigBlind = result.state.findSeat(3)!;

    expect(result.isPosted, isTrue);
    expect(result.warnings, isEmpty);
    expect(result.state.phase, HoldemHandPhase.dealingHole);
    expect(result.state.pot, 150);
    expect(result.state.currentBetToCall, 100);
    expect(result.state.minimumRaiseAmount, 100);
    expect(result.state.lastAggressorSeat, 3);
    expect(result.state.lastActionSummary, 'blinds_posted_sb_50_bb_100');
    expect(smallBlind.stack, 950);
    expect(smallBlind.committedThisRound, 50);
    expect(smallBlind.committedThisHand, 50);
    expect(smallBlind.allIn, isFalse);
    expect(bigBlind.stack, 900);
    expect(bigBlind.committedThisRound, 100);
    expect(bigBlind.committedThisHand, 100);
    expect(bigBlind.allIn, isFalse);
  });

  test('posts short all-in blinds without exceeding stacks', () {
    final result = coordinator.postBlinds(
      state: buildState(
        seats: const <HoldemSeatState>[
          HoldemSeatState(
            seat: 1,
            stack: 1000,
            inHand: true,
            folded: false,
            allIn: false,
          ),
          HoldemSeatState(
            seat: 2,
            stack: 25,
            inHand: true,
            folded: false,
            allIn: false,
          ),
          HoldemSeatState(
            seat: 3,
            stack: 75,
            inHand: true,
            folded: false,
            allIn: false,
          ),
        ],
      ),
      smallBlindAmount: 50,
      bigBlindAmount: 100,
    );

    final smallBlind = result.state.findSeat(2)!;
    final bigBlind = result.state.findSeat(3)!;

    expect(result.isPosted, isTrue);
    expect(result.state.pot, 100);
    expect(result.state.currentBetToCall, 75);
    expect(result.state.minimumRaiseAmount, 100);
    expect(result.state.lastActionSummary, 'blinds_posted_sb_25_bb_75');
    expect(smallBlind.stack, 0);
    expect(smallBlind.allIn, isTrue);
    expect(smallBlind.committedThisRound, 25);
    expect(bigBlind.stack, 0);
    expect(bigBlind.allIn, isTrue);
    expect(bigBlind.committedThisRound, 75);
  });

  test('fails closed outside blind-posting phase', () {
    final state = buildState(phase: HoldemHandPhase.handPreparing);

    final result = coordinator.postBlinds(
      state: state,
      smallBlindAmount: 50,
      bigBlindAmount: 100,
    );

    expect(result.isPosted, isFalse);
    expect(result.state, same(state));
    expect(result.warnings, contains('ERR_HOLDEM_BLINDS_PHASE'));
    expect(result.warnings, contains('ERR_HOLDEM_BLINDS_TRANSITION'));
  });

  test('fails closed for invalid blind amounts', () {
    final state = buildState();

    final result = coordinator.postBlinds(
      state: state,
      smallBlindAmount: 100,
      bigBlindAmount: 50,
    );

    expect(result.isPosted, isFalse);
    expect(result.state, same(state));
    expect(result.warnings, contains('ERR_HOLDEM_BIG_BLIND_AMOUNT'));
  });

  test('fails closed when blind seats are missing or ineligible', () {
    final state = buildState(
      seats: const <HoldemSeatState>[
        HoldemSeatState(
          seat: 1,
          stack: 1000,
          inHand: true,
          folded: false,
          allIn: false,
        ),
        HoldemSeatState(
          seat: 2,
          stack: 1000,
          inHand: true,
          folded: true,
          allIn: false,
        ),
      ],
    );

    final result = coordinator.postBlinds(
      state: state,
      smallBlindAmount: 50,
      bigBlindAmount: 100,
    );

    expect(result.isPosted, isFalse);
    expect(result.state, same(state));
    expect(result.warnings, contains('ERR_HOLDEM_SMALL_BLIND_SEAT'));
    expect(result.warnings, contains('ERR_HOLDEM_BIG_BLIND_SEAT'));
  });

  test('fails closed when blind commitments already exist', () {
    final state = buildState(
      pot: 50,
      currentBetToCall: 50,
      seats: const <HoldemSeatState>[
        HoldemSeatState(
          seat: 1,
          stack: 1000,
          inHand: true,
          folded: false,
          allIn: false,
        ),
        HoldemSeatState(
          seat: 2,
          stack: 950,
          inHand: true,
          folded: false,
          allIn: false,
          committedThisRound: 50,
          committedThisHand: 50,
        ),
        HoldemSeatState(
          seat: 3,
          stack: 1000,
          inHand: true,
          folded: false,
          allIn: false,
        ),
      ],
    );

    final result = coordinator.postBlinds(
      state: state,
      smallBlindAmount: 50,
      bigBlindAmount: 100,
    );

    expect(result.isPosted, isFalse);
    expect(result.state, same(state));
    expect(result.warnings, contains('ERR_HOLDEM_BLINDS_ALREADY_POSTED'));
  });
}
