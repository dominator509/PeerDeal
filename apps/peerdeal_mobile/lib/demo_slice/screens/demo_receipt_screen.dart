import 'package:flutter/widgets.dart';

import '../../safe_surface/safe_surface.dart';
import '../controllers/demo_receipt_surface_presenter.dart';

class DemoReceiptScreen extends StatelessWidget {
  const DemoReceiptScreen({super.key, required this.surface});

  final DemoReceiptSurfaceVm surface;

  @override
  Widget build(BuildContext context) {
    return SafeSurface(
      model: surface.safeSurface,
      obscuredChild: const Text('Receipt content hidden'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(surface.receipt.status),
          Text(surface.receipt.message),
          for (final field in surface.receipt.shareableFields.entries)
            Text('${field.key}: ${field.value}'),
          if (surface.recovery case final recovery?) ...[
            Text(recovery.recommendedAction),
            for (final diagnostic in recovery.diagnosticsJson)
              Text('${diagnostic['code']}: ${diagnostic['message']}'),
          ],
        ],
      ),
    );
  }
}
