import 'package:peerdeal_protocol/peerdeal_protocol.dart';

import '../models/scrubbed_diagnostics.dart';

abstract interface class DiagnosticsScrubber {
  ScrubbedDiagnostics scrub(Map<String, Object?> input);

  ProtocolDiagnostic scrubProtocolDiagnostic(ProtocolDiagnostic diagnostic);

  List<ProtocolDiagnostic> scrubProtocolDiagnostics(
    Iterable<ProtocolDiagnostic> diagnostics,
  );
}
