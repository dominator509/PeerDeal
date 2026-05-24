import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_desktop/safe_surface/safe_surface.dart';

void main() {
  testWidgets('renders child when surface does not need obscuring', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SafeSurface(
          model: SafeSurfaceRenderModel(
            shouldObscure: false,
            shouldRequestNativeBlocking: false,
            warnings: [],
            nativeNotes: [],
          ),
          child: Text('receipt detail'),
          obscuredChild: Text('hidden'),
        ),
      ),
    );

    expect(find.text('receipt detail'), findsOneWidget);
    expect(find.text('hidden'), findsNothing);
  });

  testWidgets('renders obscured child instead of sensitive content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SafeSurface(
          model: SafeSurfaceRenderModel(
            shouldObscure: true,
            shouldRequestNativeBlocking: true,
            warnings: ['best-effort'],
            nativeNotes: ['screen-protection-supported'],
          ),
          child: Text('private receipt token'),
          obscuredChild: Text('hidden'),
        ),
      ),
    );

    expect(find.text('private receipt token'), findsNothing);
    expect(find.text('hidden'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('hidden')),
      matchesSemantics(
        label: 'Sensitive content hidden',
        hasEnabledState: false,
      ),
    );
  });
}
