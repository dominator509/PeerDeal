import 'package:peerdeal_capture/peerdeal_capture.dart';
import 'package:test/test.dart';

void main() {
  const resolver = DefaultCapturePolicyResolver();

  test('allows non-sensitive surfaces without native action', () {
    final decision = resolver.resolve(
      surface: CaptureSurface.lobby,
      capability: const CapturePlatformCapability(
        supportsBlocking: true,
        supportsObscuring: true,
      ),
    );

    expect(decision.action, CapturePolicyAction.allow);
    expect(decision.isSensitive, isFalse);
    expect(decision.asksNativeBridgeToBlock, isFalse);
    expect(decision.requiresVisualObscuring, isFalse);
  });

  test(
    'requests native block and obscure for sensitive surfaces when available',
    () {
      final decision = resolver.resolve(
        surface: CaptureSurface.receiptDetail,
        capability: const CapturePlatformCapability(
          supportsBlocking: true,
          supportsObscuring: true,
        ),
      );

      expect(decision.action, CapturePolicyAction.requestBlockAndObscure);
      expect(decision.isSensitive, isTrue);
      expect(decision.asksNativeBridgeToBlock, isTrue);
      expect(decision.requiresVisualObscuring, isTrue);
      expect(decision.warning, contains('best-effort'));
    },
  );

  test(
    'obscures without promising universal prevention when blocking unavailable',
    () {
      final decision = resolver.resolve(
        surface: CaptureSurface.privateLedger,
        capability: const CapturePlatformCapability.none(),
      );

      expect(decision.action, CapturePolicyAction.obscureOnly);
      expect(decision.isSensitive, isTrue);
      expect(decision.asksNativeBridgeToBlock, isFalse);
      expect(decision.requiresVisualObscuring, isTrue);
      expect(decision.warning, contains('platform capability'));
    },
  );

  test('preserves native capability warning for sensitive surfaces', () {
    final decision = resolver.resolve(
      surface: CaptureSurface.receiptDetail,
      capability: const CapturePlatformCapability.none(
        warning: 'native hook unavailable',
      ),
    );

    expect(decision.action, CapturePolicyAction.obscureOnly);
    expect(decision.requiresVisualObscuring, isTrue);
    expect(decision.warning, 'native hook unavailable');
  });
}
