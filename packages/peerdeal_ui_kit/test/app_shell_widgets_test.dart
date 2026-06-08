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
}
