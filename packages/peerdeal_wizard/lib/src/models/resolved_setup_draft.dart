import 'package:meta/meta.dart';

@immutable
class ResolvedSetupDraft {
  const ResolvedSetupDraft({
    required this.intentId,
    required this.modeId,
    required this.variantId,
    required this.resolvedFields,
    required this.appliedPresetIds,
    this.unresolvedIssues = const <String>[],
    this.helperApplied = const <String>[],
  });

  final String intentId;
  final String modeId;
  final String variantId;
  final Map<String, Object?> resolvedFields;
  final List<String> appliedPresetIds;
  final List<String> unresolvedIssues;
  final List<String> helperApplied;
}
