import 'package:meta/meta.dart';

@immutable
class GameFileCompileResult {
  const GameFileCompileResult({
    required this.isCompiled,
    this.gameFile,
    this.warnings = const <String>[],
    this.errors = const <String>[],
  });

  const GameFileCompileResult.compiled({
    required Map<String, Object?> gameFile,
    List<String> warnings = const <String>[],
  }) : this(isCompiled: true, gameFile: gameFile, warnings: warnings);

  const GameFileCompileResult.rejected({
    required List<String> errors,
    List<String> warnings = const <String>[],
  }) : this(isCompiled: false, errors: errors, warnings: warnings);

  final bool isCompiled;
  final Map<String, Object?>? gameFile;
  final List<String> warnings;
  final List<String> errors;
}
