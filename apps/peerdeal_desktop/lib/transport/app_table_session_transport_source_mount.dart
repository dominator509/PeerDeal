import 'package:flutter/widgets.dart';

import 'app_table_session_transport_source.dart';

/// Owns a table transport source for the lifetime of a mounted app route.
class AppTableSessionTransportSourceMount extends StatefulWidget {
  const AppTableSessionTransportSourceMount({
    super.key,
    required this.source,
    required this.child,
  });

  final AppTableSessionTransportSource source;
  final Widget child;

  @override
  State<AppTableSessionTransportSourceMount> createState() =>
      _AppTableSessionTransportSourceMountState();
}

class _AppTableSessionTransportSourceMountState
    extends State<AppTableSessionTransportSourceMount> {
  @override
  void initState() {
    super.initState();
    widget.source.start();
  }

  @override
  void didUpdateWidget(AppTableSessionTransportSourceMount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source == widget.source) return;
    oldWidget.source.dispose();
    widget.source.start();
  }

  @override
  void dispose() {
    widget.source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
