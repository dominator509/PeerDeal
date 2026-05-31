import 'package:flutter/widgets.dart';

import '../models/demo_scenario_snapshot.dart';

class DemoChatScreen extends StatelessWidget {
  const DemoChatScreen({
    super.key,
    required this.snapshot,
    required this.onOpenTable,
  });

  final DemoScenarioSnapshot snapshot;
  final VoidCallback onOpenTable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Demo chat'),
          Text('Scenario: ${snapshot.scenarioId}'),
          Text('Unread: ${snapshot.chat.unreadCount}'),
          Text('Disappearing: ${snapshot.chat.disappearingEnabled}'),
          GestureDetector(
            onTap: onOpenTable,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Table'),
            ),
          ),
        ],
      ),
    );
  }
}
