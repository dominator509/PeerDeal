import '../models/validated_setup_plan.dart';

abstract interface class GameFileCompiler {
  Map<String, Object?> compile(ValidatedSetupPlan plan);
}
