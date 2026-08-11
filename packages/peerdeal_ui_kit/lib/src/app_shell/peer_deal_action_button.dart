import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class PeerDealActionButton extends StatefulWidget {
  const PeerDealActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<PeerDealActionButton> createState() => _PeerDealActionButtonState();
}

class _PeerDealActionButtonState extends State<PeerDealActionButton> {
  final FocusNode _focusNode = FocusNode();
  bool _hasFocus = false;
  bool _showFocusHighlight = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _activate() {
    _focusNode.requestFocus();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    return Semantics(
      button: true,
      enabled: true,
      label: label,
      focusable: true,
      focused: _hasFocus,
      onTap: _activate,
      excludeSemantics: true,
      child: FocusableActionDetector(
        focusNode: _focusNode,
        shortcuts: <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.numpadEnter):
              const ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        mouseCursor: SystemMouseCursors.click,
        onFocusChange: (hasFocus) {
          if (_hasFocus == hasFocus) return;
          if (mounted) setState(() => _hasFocus = hasFocus);
        },
        onShowFocusHighlight: (showHighlight) {
          if (_showFocusHighlight == showHighlight) return;
          if (mounted) setState(() => _showFocusHighlight = showHighlight);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _activate,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF143D34),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _showFocusHighlight
                      ? const Color(0xFF9ED6C5)
                      : const Color(0xFF2C6B5D),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Text(label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
