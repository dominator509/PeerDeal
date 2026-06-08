import 'package:flutter/widgets.dart';

class PeerDealAppScaffold extends StatelessWidget {
  const PeerDealAppScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const <Widget>[],
    required this.child,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF071412)),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Color(0xFFE8F3EF),
                fontSize: 15,
                height: 1.35,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (subtitle case final subtitle?) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: Color(0xFFB5C8C1),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (actions.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Wrap(spacing: 8, runSpacing: 8, children: actions),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
