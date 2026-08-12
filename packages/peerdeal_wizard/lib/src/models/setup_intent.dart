import 'package:meta/meta.dart';

import 'helper_suggestion.dart';
import 'model_collection_ownership.dart';
import 'setup_surface.dart';

@immutable
class SetupIntent {
  SetupIntent({
    required this.intentId,
    required this.sourceType,
    required this.hostPseudonymousId,
    this.promptText,
    this.modePreference,
    this.variantPreference,
    this.seatCountPreference,
    this.speedPreference,
    this.privacyPreference,
    this.capturePreference,
    Map<String, Object?> partialSettings = const <String, Object?>{},
    List<String> presetRefs = const <String>[],
    this.helperEnabled = false,
    List<HelperSuggestion> helperSuggestions = const <HelperSuggestion>[],
    List<String> ambiguities = const <String>[],
  }) : partialSettings = freezeWizardObjectMap(partialSettings),
       presetRefs = List<String>.unmodifiable(presetRefs),
       helperSuggestions = List<HelperSuggestion>.unmodifiable(
         helperSuggestions,
       ),
       ambiguities = List<String>.unmodifiable(ambiguities);

  final String intentId;
  final SetupSurface sourceType;
  final String hostPseudonymousId;
  final String? promptText;
  final String? modePreference;
  final String? variantPreference;
  final int? seatCountPreference;
  final String? speedPreference;
  final String? privacyPreference;
  final String? capturePreference;
  final Map<String, Object?> partialSettings;
  final List<String> presetRefs;
  final bool helperEnabled;
  final List<HelperSuggestion> helperSuggestions;
  final List<String> ambiguities;
}
