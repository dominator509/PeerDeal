import '../contracts/showdown_models.dart';
import '../contracts/variant_adapter.dart';
import 'holdem_showdown_stub.dart';

class HoldemAdapter implements VariantAdapter {
  const HoldemAdapter({
    this.showdown = const HoldemShowdownStub(),
  });

  final HoldemShowdownStub showdown;

  String get variantId => getIdentity().variantId;

  int get holeCardCount => getIdentity().holeCardCount;

  int get boardCardCount => getIdentity().boardCardCount;

  @override
  VariantIdentity getIdentity() {
    return const VariantIdentity(
      variantId: 'holdem_nlhe',
      variantFamily: 'holdem',
      displayName: "Texas Hold'em",
      adapterVersion: '0.1.0',
      seatCountMin: 2,
      seatCountMax: 9,
      holeCardCount: 2,
      boardCardCount: 5,
      bettingStructureType: 'no_limit',
    );
  }

  @override
  VariantCapabilities getCapabilities() {
    return const VariantCapabilities(
      mustUseExactHoleCards: false,
      supportsAnte: true,
      supportsMixedRotation: false,
      supportsDealersChoice: false,
      supportsPotLimit: false,
    );
  }

  @override
  VariantValidationResult validateConfig({
    required int seatCount,
    required String modeType,
    required String bettingStructureType,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    if (seatCount < 2 || seatCount > 9) {
      errors.add('Hold\'em seat count must be between 2 and 9.');
    }

    if (bettingStructureType != 'no_limit') {
      errors.add('Starter Hold\'em adapter currently supports only no_limit.');
    }

    if (modeType != 'tournament' && modeType != 'open_table') {
      warnings.add('Unknown mode type: $modeType');
    }

    return VariantValidationResult(
      isValid: errors.isEmpty,
      warnings: warnings,
      errors: errors,
    );
  }

  @override
  HandPlan buildHandPlan() {
    return const HandPlan(
      privateCardsPerSeat: 2,
      boardStages: <int>[3, 1, 1],
    );
  }

  ShowdownEvaluationResult evaluate(ShowdownEvaluationInput input) {
    return showdown.evaluate(input);
  }
}
