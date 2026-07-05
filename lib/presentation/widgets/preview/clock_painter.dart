import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/puzzles/clock_simulator.dart';
import 'preview_fit.dart';
import 'puzzle_palettes.dart';

/// Dibuja el estado final del Rubik's Clock: dos grillas de 3x3 relojes
/// (frente y dorso) con sus pines, en el layout de csTimer.
class ClockPainter extends CustomPainter {
  ClockPainter({required this.state, required this.notation});

  final ClockDialsState state;
  final String notation;

  static const List<double> _columnX = [10, 30, 50, 75, 95, 115];
  static const List<double> _rowY = [10, 30, 50];
  static const List<double> _pinX = [20, 40, 85, 105];
  static const List<double> _pinY = [20, 40];
  static const double _dialRadius = 9;

  @override
  void paint(Canvas canvas, Size size) {
    const contentWidth = 125.0;
    const contentHeight = 60.0;
    PreviewFit.contain(size, contentWidth, contentHeight).applyTo(canvas);

    final leftColor = state.frontOnLeft
        ? PuzzlePalettes.clockFront
        : PuzzlePalettes.clockBack;
    final rightColor = state.frontOnLeft
        ? PuzzlePalettes.clockBack
        : PuzzlePalettes.clockFront;

    _drawGrid(canvas,
        columnOffset: 0, dials: state.leftDials, color: leftColor);
    _drawGrid(
      canvas,
      columnOffset: 3,
      dials: state.rightDials,
      color: rightColor,
    );

    for (var i = 0; i < 8; i++) {
      final center = Offset(_pinX[i ~/ 2], _pinY[i % 2]);
      final paint = Paint()
        ..color = state.pinsUp[i]
            ? PuzzlePalettes.clockPinUp
            : PuzzlePalettes.clockPinDown;
      canvas.drawCircle(center, 3, paint);
      canvas.drawCircle(
        center,
        3,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.4,
      );
    }
  }

  void _drawGrid(
    Canvas canvas, {
    required int columnOffset,
    required List<int> dials,
    required Color color,
  }) {
    for (var i = 0; i < 9; i++) {
      final row = i ~/ 3;
      final column = i % 3;
      final center = Offset(_columnX[columnOffset + column], _rowY[row]);
      _drawDial(canvas, center, dials[i], color);
    }
  }

  void _drawDial(Canvas canvas, Offset center, int hour, Color faceColor) {
    canvas.drawCircle(center, _dialRadius, Paint()..color = faceColor);
    canvas.drawCircle(
      center,
      _dialRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    // Marcas horarias: la de las 12 es más grande para leer la referencia.
    for (var tick = 0; tick < 12; tick++) {
      final angle = tick * math.pi / 6 - math.pi / 2;
      final tickCenter = center +
          Offset(math.cos(angle), math.sin(angle)) * (_dialRadius - 1.4);
      canvas.drawCircle(
        tickCenter,
        tick == 0 ? 0.8 : 0.45,
        Paint()..color = Colors.white.withValues(alpha: tick == 0 ? 0.95 : 0.6),
      );
    }

    // Aguja apuntando a la hora (0 = 12 en punto, sentido horario).
    final needleAngle = hour * math.pi / 6 - math.pi / 2;
    final direction = Offset(math.cos(needleAngle), math.sin(needleAngle));
    final normal = Offset(-direction.dy, direction.dx);
    final tip = center + direction * (_dialRadius - 2.2);
    final baseA = center + normal * 1.1 - direction * 1.2;
    final baseB = center - normal * 1.1 - direction * 1.2;

    final needle = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(baseA.dx, baseA.dy)
      ..lineTo(baseB.dx, baseB.dy)
      ..close();
    canvas.drawPath(needle, Paint()..color = PuzzlePalettes.clockNeedle);
    canvas.drawPath(
      needle,
      Paint()
        ..color = PuzzlePalettes.clockNeedleEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.35
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(center, 1.1, Paint()..color = PuzzlePalettes.clockNeedle);
  }

  @override
  bool shouldRepaint(covariant ClockPainter oldDelegate) =>
      oldDelegate.notation != notation;
}
