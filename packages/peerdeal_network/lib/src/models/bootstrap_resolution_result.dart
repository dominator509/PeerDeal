import 'bootstrap_candidate.dart';
import 'session_path_descriptor.dart';

class BootstrapResolutionResult {
  BootstrapResolutionResult({
    required List<BootstrapCandidate> candidates,
    required this.selectedPath,
    required this.routeChanged,
  }) : candidates = List<BootstrapCandidate>.unmodifiable(candidates);

  final List<BootstrapCandidate> candidates;
  final SessionPathDescriptor selectedPath;
  final bool routeChanged;
}
