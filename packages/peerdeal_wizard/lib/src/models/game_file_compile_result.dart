import 'package:meta/meta.dart';

import 'model_collection_ownership.dart';

@immutable
class GameFileCompileResult {
  GameFileCompileResult({
    required this.isCompiled,
    Map<String, Object?>? gameFile,
    List<String> warnings = const <String>[],
    List<String> errors = const <String>[],
  }) : gameFile = gameFile == null ? null : freezeWizardObjectMap(gameFile),
       warnings = List<String>.unmodifiable(warnings),
       errors = List<String>.unmodifiable(errors);

  GameFileCompileResult.compiled({
    required Map<String, Object?> gameFile,
    List<String> warnings = const <String>[],
  }) : this(isCompiled: true, gameFile: gameFile, warnings: warnings);

  GameFileCompileResult.rejected({
    required List<String> errors,
    List<String> warnings = const <String>[],
  }) : this(isCompiled: false, errors: errors, warnings: warnings);

  final bool isCompiled;
  final Map<String, Object?>? gameFile;
  final List<String> warnings;
  final List<String> errors;
}
