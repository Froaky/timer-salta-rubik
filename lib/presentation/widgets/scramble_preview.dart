import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/scramble.dart';
import '../../domain/puzzles/clock_simulator.dart';
import '../../domain/puzzles/megaminx_simulator.dart';
import '../../domain/puzzles/nxn_cube_simulator.dart';
import '../../domain/puzzles/pyraminx_simulator.dart';
import '../../domain/puzzles/skewb_simulator.dart';
import '../../domain/puzzles/square1_simulator.dart';
import 'preview/clock_painter.dart';
import 'preview/cube_net_painter.dart';
import 'preview/megaminx_net_painter.dart';
import 'preview/pyraminx_net_painter.dart';
import 'preview/skewb_net_painter.dart';
import 'preview/square1_painter.dart';

/// Preview 2D del estado resultante de aplicar el scramble actual.
///
/// La simulación del puzzle vive en `lib/domain/puzzles/` (Dart puro) y el
/// dibujo en `lib/presentation/widgets/preview/`. Para soportar un puzzle
/// nuevo: crear su simulador + painter y registrarlo en [_painterFor].
class ScramblePreview extends StatelessWidget {
  final Scramble scramble;
  final double? width;
  final double? height;
  final bool showLabel;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Key? containerKey;
  final Key? svgKey;

  const ScramblePreview({
    super.key,
    required this.scramble,
    this.width,
    this.height,
    this.showLabel = true,
    this.padding,
    this.backgroundColor,
    this.containerKey,
    this.svgKey,
  });

  static const Map<String, int> _nxnSizes = {
    '2x2': 2,
    '3x3': 3,
    '4x4': 4,
    '5x5': 5,
    '6x6': 6,
    '7x7': 7,
  };

  /// Variantes de categoría que comparten puzzle base (y por lo tanto net).
  static const Map<String, String> _aliases = {
    '3x3oh': '3x3',
    '3x3bf': '3x3',
    '3x3fm': '3x3',
    '3x3mbf': '3x3',
    '444bf': '4x4',
    '4x4bf': '4x4',
    '555bf': '5x5',
    '5x5bf': '5x5',
    'square-1': 'sq1',
  };

  static String _normalize(String cubeType) {
    final lower = cubeType.toLowerCase();
    return _aliases[lower] ?? lower;
  }

  /// Indica si existe preview visual para la categoría dada.
  static bool supports(String cubeType) {
    final type = _normalize(cubeType);
    return _nxnSizes.containsKey(type) ||
        const {'pyraminx', 'skewb', 'megaminx', 'clock', 'sq1'}.contains(type);
  }

  static CustomPainter? _painterFor(String cubeType, String notation) {
    final type = _normalize(cubeType);

    final nxnSize = _nxnSizes[type];
    if (nxnSize != null) {
      return CubeNetPainter(
        facelets: NxnCubeSimulator(size: nxnSize).apply(notation),
        notation: notation,
      );
    }

    switch (type) {
      case 'pyraminx':
        return PyraminxNetPainter(
          facelets: PyraminxSimulator().apply(notation),
          notation: notation,
        );
      case 'skewb':
        return SkewbNetPainter(
          facelets: SkewbSimulator().apply(notation),
          notation: notation,
        );
      case 'megaminx':
        return MegaminxNetPainter(
          facelets: MegaminxSimulator().apply(notation),
          notation: notation,
        );
      case 'clock':
        return ClockPainter(
          state: ClockSimulator().apply(notation),
          notation: notation,
        );
      case 'sq1':
        return Square1Painter(
          state: Square1Simulator().apply(notation),
          notation: notation,
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final painter = _painterFor(scramble.cubeType, scramble.notation);
    if (painter == null) {
      return const SizedBox.shrink();
    }

    return Container(
      key: containerKey ?? const ValueKey('scramble-preview'),
      padding: padding ?? const EdgeInsets.all(16),
      color: backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fallback = math.min(
            width ?? constraints.maxWidth,
            height ??
                (constraints.maxHeight == double.infinity
                    ? constraints.maxWidth
                    : constraints.maxHeight),
          );

          return CustomPaint(
            key: svgKey ?? const ValueKey('scramble-preview-svg'),
            size: Size(width ?? fallback, height ?? fallback),
            painter: painter,
          );
        },
      ),
    );
  }
}
