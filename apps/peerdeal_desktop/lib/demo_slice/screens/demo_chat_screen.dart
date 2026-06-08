import 'package:flutter/widgets.dart';
import 'package:peerdeal_ui_kit/peerdeal_ui_kit.dart';

import '../models/demo_scenario_snapshot.dart';

class DemoChatScreen extends StatelessWidget {
  const DemoChatScreen({super.key, required this.snapshot, this.onOpenTable});

  final DemoScenarioSnapshot snapshot;
  final VoidCallback? onOpenTable;

  @override
  Widget build(BuildContext context) {
    return PeerDealAppScaffold(
      title: 'Demo chat',
      subtitle: 'Fixture-backed table conversation',
      actions: <Widget>[
        if (onOpenTable != null)
          PeerDealActionButton(label: 'Table', onPressed: onOpenTable!),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PeerDealInfoRow(label: 'Scenario', value: snapshot.scenarioId),
          Text('Scenario: ${snapshot.scenarioId}'),
          PeerDealInfoRow(
            label: 'Unread',
            value: snapshot.chat.unreadCount.toString(),
          ),
          Text('Unread: ${snapshot.chat.unreadCount}'),
          PeerDealInfoRow(
            label: 'Disappearing',
            value: snapshot.chat.disappearingEnabled.toString(),
          ),
          Text('Disappearing: ${snapshot.chat.disappearingEnabled}'),
        ],
      ),
    );
  }
}
