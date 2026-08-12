import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_mobile/demo_slice/controllers/demo_slice_controller.dart';
import 'package:peerdeal_mobile/demo_slice/screens/demo_home_screen.dart';

void main() {
  testWidgets('home screen snapshots navigation collections', (tester) async {
    final actions = <DemoHomeNavigationAction>[
      DemoHomeNavigationAction(label: 'Initial', onPressed: () {}),
    ];
    final screen = DemoHomeScreen(
      controller: DemoSliceController(),
      demoNavigationActions: actions,
      productionNavigationActions: <DemoHomeNavigationAction>[],
      onSelectScenario: (_) {},
      showDemoScenarios: false,
    );

    Widget wrappedScreen() {
      return WidgetsApp(
        color: const Color(0xFF1B5E20),
        builder: (_, _) => screen,
      );
    }

    await tester.pumpWidget(wrappedScreen());
    expect(find.text('Initial'), findsOneWidget);

    actions.add(DemoHomeNavigationAction(label: 'Injected', onPressed: () {}));
    await tester.pumpWidget(wrappedScreen());

    expect(find.text('Initial'), findsOneWidget);
    expect(find.text('Injected'), findsNothing);
  });
}
