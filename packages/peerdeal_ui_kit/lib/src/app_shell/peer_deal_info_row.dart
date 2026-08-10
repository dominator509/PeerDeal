import 'package:flutter/widgets.dart';

class PeerDealInfoRow extends StatelessWidget {
  const PeerDealInfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact =
            constraints.maxWidth.isFinite && constraints.maxWidth < 360;
        final content = isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _labelText(),
                  const SizedBox(height: 2),
                  Text(value),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(width: 150, child: _labelText()),
                  Expanded(child: Text(value)),
                ],
              );
        return Semantics(
          container: true,
          label: '$label: $value',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: content,
          ),
        );
      },
    );
  }

  Widget _labelText() {
    return Text(label, style: const TextStyle(color: Color(0xFF9CB4AD)));
  }
}
