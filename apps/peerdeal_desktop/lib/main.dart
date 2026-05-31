import 'package:flutter/widgets.dart';

import 'demo_slice/controllers/demo_receipt_surface_presenter.dart';
import 'demo_slice/controllers/demo_slice_controller.dart';
import 'demo_slice/demo_slice_routes.dart';
import 'demo_slice/models/demo_scenario_snapshot.dart';
import 'demo_slice/scenarios/demo_scenario_snapshots.dart';
import 'demo_slice/screens/demo_chat_screen.dart';
import 'demo_slice/screens/demo_home_screen.dart';
import 'demo_slice/screens/demo_receipt_screen.dart';
import 'demo_slice/screens/demo_table_screen.dart';

void main() {
  runApp(const PeerDealDesktopApp());
}

class PeerDealDesktopApp extends StatefulWidget {
  const PeerDealDesktopApp({super.key, DemoReceiptSurfacePresenter? presenter})
    : _receiptPresenter = presenter;

  final DemoReceiptSurfacePresenter? _receiptPresenter;

  @override
  State<PeerDealDesktopApp> createState() => _PeerDealDesktopAppState();
}

class _PeerDealDesktopAppState extends State<PeerDealDesktopApp> {
  final DemoSliceController _controller = DemoSliceController();

  DemoReceiptSurfacePresenter? get _receiptPresenter =>
      widget._receiptPresenter;

  DemoScenarioSnapshot get _activeSnapshot {
    return DemoScenarioSnapshots.byId(_controller.activeScenario.id);
  }

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'PeerDeal Desktop',
      color: const Color(0xFF1B5E20),
      initialRoute: DemoSliceRoutes.home,
      pageRouteBuilder: <T>(settings, builder) {
        return PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) {
            return builder(context);
          },
        );
      },
      routes: <String, WidgetBuilder>{
        Navigator.defaultRouteName: _buildHome,
        DemoSliceRoutes.home: _buildHome,
        DemoSliceRoutes.table: (context) => DemoTableScreen(
          snapshot: _activeSnapshot,
          onOpenChat: () =>
              Navigator.of(context).pushNamed(DemoSliceRoutes.chat),
          onOpenReceipt: () =>
              Navigator.of(context).pushNamed(DemoSliceRoutes.receipt),
        ),
        DemoSliceRoutes.chat: (context) => DemoChatScreen(
          snapshot: _activeSnapshot,
          onOpenTable: () =>
              Navigator.of(context).pushNamed(DemoSliceRoutes.table),
        ),
        DemoSliceRoutes.receipt: (_) => DemoReceiptRoute(
          snapshot: _activeSnapshot,
          presenter: _receiptPresenter ?? DemoReceiptSurfacePresenter(),
        ),
      },
    );
  }

  Widget _buildHome(BuildContext context) {
    return DemoHomeScreen(
      controller: _controller,
      onOpenTable: () => Navigator.of(context).pushNamed(DemoSliceRoutes.table),
      onOpenChat: () => Navigator.of(context).pushNamed(DemoSliceRoutes.chat),
      onOpenReceipt: () =>
          Navigator.of(context).pushNamed(DemoSliceRoutes.receipt),
      onSelectScenario: _selectScenario,
    );
  }

  void _selectScenario(String scenarioId) {
    if (!_controller.trySelectScenario(scenarioId)) return;
    setState(() {});
  }
}
