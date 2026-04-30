import '../models/scrubbed_diagnostics.dart';

abstract interface class DiagnosticsScrubber {
  ScrubbedDiagnostics scrub(Map<String, Object?> input);
}
