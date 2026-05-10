import 'package:meta/meta.dart';
import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import 'anchor_hash.dart';
import 'replay_mismatch.dart';

@immutable
class ReplayResult<TState> {
  const ReplayResult({
    required this.isSuccess,
    required this.state,
    required this.finalAppliedEventSeq,
    required this.reconstructedAnchor,
    this.warnings = const <String>[],
    this.mismatches = const <ReplayMismatch>[],
  });

  final bool isSuccess;
  final TState? state;
  final int? finalAppliedEventSeq;
  final AnchorHash? reconstructedAnchor;
  final List<String> warnings;
  final List<ReplayMismatch> mismatches;

  List<ProtocolDiagnostic> get diagnostics => mismatches
      .map((mismatch) => mismatch.toProtocolDiagnostic())
      .toList(growable: false);
}
