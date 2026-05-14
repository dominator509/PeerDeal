import '../models/demo_scenario.dart';

class DemoScenarioCatalog {
  static const scenarios = <DemoScenario>[
    DemoScenario(
      id: 'open_table_live_turn',
      title: 'Open Table - Live Turn',
      description:
          'Open Table live-hand shell with action bar, chat, and verification badge.',
      fixturePath: 'tools/demo_slice_fixtures/open_table_live_turn.json',
    ),
    DemoScenario(
      id: 'tournament_break',
      title: 'Tournament - Break',
      description:
          'Tournament shell with break banner, paused action area, and seat summaries.',
      fixturePath: 'tools/demo_slice_fixtures/tournament_break.json',
    ),
    DemoScenario(
      id: 'recovery_pause_transfer',
      title: 'Recovery Pause - Primary-Peer Transfer',
      description:
          'Paused recovery shell with degraded network confidence and transfer messaging.',
      fixturePath: 'tools/demo_slice_fixtures/recovery_pause_transfer.json',
    ),
    DemoScenario(
      id: 'verification_receipt_review',
      title: 'Verification / Receipt Review',
      description:
          'Verification badge, receipt summary, and privacy/retention surfaces.',
      fixturePath: 'tools/demo_slice_fixtures/verification_receipt_review.json',
    ),
    DemoScenario(
      id: 'chat_heavy_table',
      title: 'Chat-Heavy Table',
      description: 'Table shell with active table chat and DM launch points.',
      fixturePath: 'tools/demo_slice_fixtures/chat_heavy_table.json',
    ),
  ];
}
