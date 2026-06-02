import 'package:meta/meta.dart';

enum CapturePolicyAction { allow, obscureOnly, requestBlockAndObscure }

@immutable
class CapturePolicyDecision {
  const CapturePolicyDecision({
    required this.action,
    required this.isSensitive,
    required this.reason,
    this.warning,
  });

  final CapturePolicyAction action;
  final bool isSensitive;
  final String reason;
  final String? warning;

  bool get asksNativeBridgeToBlock =>
      action == CapturePolicyAction.requestBlockAndObscure;
  bool get requiresVisualObscuring =>
      action == CapturePolicyAction.obscureOnly ||
      action == CapturePolicyAction.requestBlockAndObscure;
}
