import 'package:meta/meta.dart';

@immutable
class VariantIdentity {
  const VariantIdentity({
    required this.variantId,
    required this.variantFamily,
    required this.displayName,
    required this.adapterVersion,
    required this.seatCountMin,
    required this.seatCountMax,
    required this.holeCardCount,
    required this.boardCardCount,
    required this.bettingStructureType,
  });

  final String variantId;
  final String variantFamily;
  final String displayName;
  final String adapterVersion;
  final int seatCountMin;
  final int seatCountMax;
  final int holeCardCount;
  final int boardCardCount;
  final String bettingStructureType;
}

@immutable
class VariantCapabilities {
  const VariantCapabilities({
    required this.mustUseExactHoleCards,
    required this.supportsAnte,
    required this.supportsMixedRotation,
    required this.supportsDealersChoice,
    required this.supportsPotLimit,
  });

  final bool mustUseExactHoleCards;
  final bool supportsAnte;
  final bool supportsMixedRotation;
  final bool supportsDealersChoice;
  final bool supportsPotLimit;
}

@immutable
class VariantValidationResult {
  const VariantValidationResult({
    required this.isValid,
    this.warnings = const <String>[],
    this.errors = const <String>[],
  });

  final bool isValid;
  final List<String> warnings;
  final List<String> errors;
}

@immutable
class HandPlan {
  const HandPlan({
    required this.privateCardsPerSeat,
    required this.boardStages,
  });

  final int privateCardsPerSeat;
  final List<int> boardStages;
}

abstract interface class VariantAdapter {
  VariantIdentity getIdentity();
  VariantCapabilities getCapabilities();
  VariantValidationResult validateConfig({
    required int seatCount,
    required String modeType,
    required String bettingStructureType,
  });
  HandPlan buildHandPlan();
}
