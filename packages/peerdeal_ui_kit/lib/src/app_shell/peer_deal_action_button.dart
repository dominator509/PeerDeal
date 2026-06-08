import 'package:flutter/widgets.dart';

class PeerDealActionButton extends StatelessWidget {
  const PeerDealActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF143D34),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF2C6B5D)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
