import 'package:flutter/material.dart';

/// Responsive wrapper that centers content on wide displays and expands full height
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 680,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox.expand(
          child: child,
        ),
      ),
    );
  }
}
