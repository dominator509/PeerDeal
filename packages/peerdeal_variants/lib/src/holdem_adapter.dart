import 'variant_adapter.dart';

class HoldemAdapter implements VariantAdapter {
  const HoldemAdapter();

  @override
  String get variantId => 'holdem_nlhe';

  @override
  int get holeCardCount => 2;

  @override
  int get boardCardCount => 5;

  @override
  Map<String, Object?> getCapabilities() => const {
        'betting_structure_type': 'no_limit',
        'must_use_exact_hole_cards': false,
        'required_hole_cards_for_final_hand': null,
        'required_board_cards_for_final_hand': null,
      };
}
