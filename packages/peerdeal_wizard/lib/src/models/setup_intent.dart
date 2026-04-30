import 'package:meta/meta.dart';

import 'helper_suggestion.dart';
import 'setup_surface.dart';

@immutable
class SetupIntent {
  const SetupIntent({
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
    this.partialSettings = const <String, Object?>{},
    this.presetRefs = const <String>[],
    this.helperEnabled = false,
    this.helperSuggestions = const <HelperSuggestion>[],
    this.ambiguities = const <String>[],
  });

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
