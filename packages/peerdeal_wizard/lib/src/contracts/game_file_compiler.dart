import '../models/game_file_compile_result.dart';
import '../models/validated_setup_plan.dart';

abstract interface class GameFileCompiler {
  Map<String, Object?> compile(ValidatedSetupPlan plan);

  GameFileCompileResult tryCompile(ValidatedSetupPlan plan);
}
