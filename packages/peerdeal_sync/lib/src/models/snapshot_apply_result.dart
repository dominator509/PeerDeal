import 'package:meta/meta.dart';

@immutable
class SnapshotApplyResult<TState> {
  const SnapshotApplyResult({
    required this.state,
    required this.appliedEventCount,
    required this.finalAppliedEventSeq,
    this.warnings = const <String>[],
  });

  final TState state;
  final int appliedEventCount;
  final int? finalAppliedEventSeq;
  final List<String> warnings;
}
