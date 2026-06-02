import 'package:peerdeal_capture/peerdeal_capture.dart';
import 'package:peerdeal_desktop/safe_surface/safe_surface.dart';
import 'package:test/test.dart';

void main() {
  test('collapses capture plans into stable render flags', () {
    final model = SafeSurfaceRenderModel.fromCapturePlans([
      const CaptureSurfacePlan(
        surface: CaptureSurface.receiptDetail,
        decision: CapturePolicyDecision(
          action: CapturePolicyAction.requestBlockAndObscure,
          isSensitive: true,
          reason: 'sensitive',
          warning: 'best-effort',
        ),
        nativeNotes: 'screen-protection-supported',
      ),
      const CaptureSurfacePlan(
        surface: CaptureSurface.restore,
        decision: CapturePolicyDecision(
          action: CapturePolicyAction.obscureOnly,
          isSensitive: true,
          reason: 'sensitive',
          warning: 'best-effort',
        ),
        nativeNotes: 'screen-protection-supported',
      ),
      null,
    ]);

    expect(model.shouldObscure, isTrue);
    expect(model.shouldRequestNativeBlocking, isTrue);
    expect(model.warnings, ['best-effort']);
    expect(model.nativeNotes, ['screen-protection-supported']);
    expect(() => model.warnings.add('changed'), throwsUnsupportedError);
  });

  test('keeps non-sensitive render flags quiet', () {
    final model = SafeSurfaceRenderModel.fromCapturePlans([
      const CaptureSurfacePlan(
        surface: CaptureSurface.lobby,
        decision: CapturePolicyDecision(
          action: CapturePolicyAction.allow,
          isSensitive: false,
          reason: 'not sensitive',
        ),
        nativeNotes: 'screen-protection-supported',
      ),
    ]);

    expect(model.shouldObscure, isFalse);
    expect(model.shouldRequestNativeBlocking, isFalse);
    expect(model.warnings, isEmpty);
  });
}
