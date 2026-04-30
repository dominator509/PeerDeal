import 'package:meta/meta.dart';

@immutable
class HelperSuggestion {
  const HelperSuggestion({
    required this.key,
    required this.value,
    required this.reason,
    this.confidence = 0.5,
  });

  final String key;
  final Object? value;
  final String reason;
  final double confidence;
}
