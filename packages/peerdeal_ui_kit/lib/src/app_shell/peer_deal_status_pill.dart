import 'package:flutter/widgets.dart';

class PeerDealStatusPill extends StatelessWidget {
  const PeerDealStatusPill({
    super.key,
    required this.label,
    this.severity = 'info',
  });

  final String label;
  final String severity;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(severity);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: TextStyle(color: colors.foreground, fontSize: 13),
        ),
      ),
    );
  }

  _StatusPillColors _colorsFor(String severity) {
    return switch (severity) {
      'critical' || 'error' => const _StatusPillColors(
        background: Color(0xFF421A1A),
        border: Color(0xFFA24A4A),
        foreground: Color(0xFFFFD9D9),
      ),
      'warning' || 'degraded' => const _StatusPillColors(
        background: Color(0xFF3D3214),
        border: Color(0xFFA78932),
        foreground: Color(0xFFFFE6A7),
      ),
      'success' || 'stable' => const _StatusPillColors(
        background: Color(0xFF123C2D),
        border: Color(0xFF2D8F68),
        foreground: Color(0xFFD9FCEB),
      ),
      _ => const _StatusPillColors(
        background: Color(0xFF172B36),
        border: Color(0xFF416C80),
        foreground: Color(0xFFD8F1FF),
      ),
    };
  }
}

class _StatusPillColors {
  const _StatusPillColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}
