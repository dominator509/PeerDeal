import 'package:meta/meta.dart';

import 'model_collection_ownership.dart';

@immutable
class HelperSuggestion {
  HelperSuggestion({
    required this.key,
    required Object? value,
    required this.reason,
    this.confidence = 0.5,
  }) : value = freezeWizardValue(value);

  final String key;
  final Object? value;
  final String reason;
  final double confidence;
}
