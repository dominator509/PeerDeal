class ProtocolDiagnostic {
  const ProtocolDiagnostic({
    required this.code,
    required this.message,
    this.expected,
    this.actual,
  });

  final String code;
  final String message;
  final Object? expected;
  final Object? actual;

  Map<String, Object?> toJson() => {
    'code': code,
    'message': message,
    if (expected != null) 'expected': expected,
    if (actual != null) 'actual': actual,
  };
}
