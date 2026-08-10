import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peerdeal_ui_kit/peerdeal_ui_kit.dart';

void main() {
  testWidgets('app scaffold renders title, subtitle, actions, and body', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PeerDealAppScaffold(
          title: 'PeerDeal',
          subtitle: 'Table control',
          actions: <Widget>[
            PeerDealActionButton(
              label: 'Open',
              onPressed: () {
                tapped = true;
              },
            ),
          ],
          child: const Text('Body'),
        ),
      ),
    );

    expect(find.text('PeerDeal'), findsOneWidget);
    expect(find.text('Table control'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);

    await tester.tap(find.text('Open'));

    expect(tapped, isTrue);
    expect(find.bySemanticsLabel('Open'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Open')),
      matchesSemantics(
        label: 'Open',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('status pill and info row render compact operational facts', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            PeerDealStatusPill(label: 'stable', severity: 'success'),
            PeerDealInfoRow(label: 'Network', value: 'stable'),
          ],
        ),
      ),
    );

    expect(find.text('stable'), findsNWidgets(2));
    expect(find.text('Network'), findsOneWidget);
  });

  testWidgets('info row stacks content within a narrow viewport', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 240,
            child: PeerDealInfoRow(
              label: 'Current actor',
              value: 'Waiting for seat 12',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Current actor'), findsOneWidget);
    expect(find.text('Waiting for seat 12'), findsOneWidget);
    expect(
      tester.getRect(find.text('Waiting for seat 12')).top,
      greaterThan(tester.getRect(find.text('Current actor')).bottom),
    );
    expect(tester.takeException(), isNull);
  });
}
