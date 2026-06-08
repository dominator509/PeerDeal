import 'package:flutter/widgets.dart';

class PeerDealInfoRow extends StatelessWidget {
  const PeerDealInfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF9CB4AD)),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
