import 'package:flutter/material.dart';

/// Constrains content to a comfortable reading width and centers it.
///
/// On phones this is effectively a no-op (the screen is narrower than
/// [maxWidth]), but on wide browser/desktop windows it stops panels from
/// stretching edge-to-edge — the main tell that a mobile UI was simply
/// blown up to fill a desktop viewport.
class ResponsiveCentered extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  const ResponsiveCentered({
    super.key,
    required this.child,
    this.maxWidth = 720,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
