import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_ui_kit/peerdeal_ui_kit.dart';

void main() {
  test('scrubs capture plan warning and native note text', () {
    final model =
        SafeSurfaceRenderModel.fromCapturePlans(const <SafeSurfaceCapturePlan?>[
          _CapturePlan(
            warning: r'capture token C:\secret\screen.log',
            nativeNotes: r'native token C:\secret\screen.log',
          ),
          _CapturePlan(
            warning: 'best-effort',
            nativeNotes: 'screen-protection-supported',
          ),
        ]);

    expect(model.warnings, <String>[
      'Capture warning unavailable.',
      'best-effort',
    ]);
    expect(model.nativeNotes, <String>['screen-protection-supported']);
  });

  test('normalizes and bounds capture plan render text', () {
    final model =
        SafeSurfaceRenderModel.fromCapturePlans(<SafeSurfaceCapturePlan?>[
          _CapturePlan(
            warning: '${'warning '.padRight(120, 'x')}\nmore',
            nativeNotes: '${'native '.padRight(120, 'x')}\nmore',
          ),
        ]);

    expect(model.warnings.single, isNot(contains('\n')));
    expect(model.warnings.single.length, lessThanOrEqualTo(96));
    expect(model.nativeNotes.single, isNot(contains('\n')));
    expect(model.nativeNotes.single.length, lessThanOrEqualTo(96));
  });
}

class _CapturePlan implements SafeSurfaceCapturePlan {
  const _CapturePlan({required this.warning, required this.nativeNotes});

  @override
  bool get shouldObscure => true;

  @override
  bool get shouldRequestNativeBlocking => true;

  @override
  final String? warning;

  @override
  final String nativeNotes;
}
