import '../models/preset_models.dart';
import '../models/resolved_setup_draft.dart';
import '../models/setup_intent.dart';
import '../models/validated_setup_plan.dart';

abstract interface class PresetResolver {
  PresetResolutionResult mergeLayers(List<PresetLayer> layers);

  ResolvedSetupDraft resolveIntent({
    required SetupIntent intent,
    required List<PresetLayer> presetLayers,
  });

  ValidatedSetupPlan validateDraft(ResolvedSetupDraft draft);
}
