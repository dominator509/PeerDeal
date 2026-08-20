import 'package:meta/meta.dart';

import 'model_collection_ownership.dart';

@immutable
class ResolvedSetupDraft {
  ResolvedSetupDraft({
    required this.intentId,
    required this.modeId,
    required this.variantId,
    this.hostPseudonymousId = '',
    required Map<String, Object?> resolvedFields,
    required List<String> appliedPresetIds,
    List<String> unresolvedIssues = const <String>[],
    List<String> helperApplied = const <String>[],
  }) : resolvedFields = freezeWizardObjectMap(resolvedFields),
       appliedPresetIds = List<String>.unmodifiable(appliedPresetIds),
       unresolvedIssues = List<String>.unmodifiable(unresolvedIssues),
       helperApplied = List<String>.unmodifiable(helperApplied);

  final String intentId;
  final String modeId;
  final String variantId;
  final String hostPseudonymousId;
  final Map<String, Object?> resolvedFields;
  final List<String> appliedPresetIds;
  final List<String> unresolvedIssues;
  final List<String> helperApplied;
}
