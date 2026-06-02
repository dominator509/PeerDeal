import 'capture_platform_capability.dart';
import 'capture_policy_decision.dart';
import 'capture_surface.dart';

class DefaultCapturePolicyResolver {
  const DefaultCapturePolicyResolver();

  CapturePolicyDecision resolve({
    required CaptureSurface surface,
    required CapturePlatformCapability capability,
  }) {
    if (!surface.isAlwaysSensitive) {
      return const CapturePolicyDecision(
        action: CapturePolicyAction.allow,
        isSensitive: false,
        reason: 'Surface is not classified as always sensitive.',
      );
    }

    final warning = capability.warning ?? _platformLimitWarning;
    if (capability.supportsBlocking) {
      return CapturePolicyDecision(
        action: CapturePolicyAction.requestBlockAndObscure,
        isSensitive: true,
        reason: 'Sensitive surface should request native blocking and obscure.',
        warning: warning,
      );
    }

    if (capability.supportsObscuring) {
      return CapturePolicyDecision(
        action: CapturePolicyAction.obscureOnly,
        isSensitive: true,
        reason:
            'Sensitive surface should obscure because blocking is unavailable.',
        warning: warning,
      );
    }

    return CapturePolicyDecision(
      action: CapturePolicyAction.obscureOnly,
      isSensitive: true,
      reason:
          'Sensitive surface remains sensitive even when platform hooks are unavailable.',
      warning: warning,
    );
  }

  static const _platformLimitWarning =
      'Capture protection is best-effort and limited by platform capability.';
}
