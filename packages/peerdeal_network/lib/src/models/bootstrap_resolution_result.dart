import 'bootstrap_candidate.dart';
import 'session_path_descriptor.dart';

class BootstrapResolutionResult {
  const BootstrapResolutionResult({
    required this.candidates,
    required this.selectedPath,
    required this.routeChanged,
  });

  final List<BootstrapCandidate> candidates;
  final SessionPathDescriptor selectedPath;
  final bool routeChanged;
}
