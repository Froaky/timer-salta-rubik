import 'dart:math' as math;
import 'dart:ui';

/// Escala y centra un contenido de proporciones fijas dentro del canvas
/// disponible (equivalente a `BoxFit.contain`).
///
/// Los painters de preview dibujan en "unidades de contenido"; aplicar esta
/// transformación al canvas evita que cada painter repita la matemática de
/// letterboxing.
class PreviewFit {
  PreviewFit._(this.scale, this.offset);

  factory PreviewFit.contain(
    Size canvasSize,
    double contentWidth,
    double contentHeight,
  ) {
    final scale = math.min(
      canvasSize.width / contentWidth,
      canvasSize.height / contentHeight,
    );
    final offset = Offset(
      (canvasSize.width - contentWidth * scale) / 2,
      (canvasSize.height - contentHeight * scale) / 2,
    );
    return PreviewFit._(scale, offset);
  }

  final double scale;
  final Offset offset;

  void applyTo(Canvas canvas) {
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
  }
}
