import 'package:flutter/material.dart';

/// Paletas de color para los previews de scramble.
///
/// El índice de cada lista corresponde al id de color que devuelve el
/// simulador de dominio de ese puzzle (ver `lib/domain/puzzles/`).
abstract final class PuzzlePalettes {
  /// Cubos NxN, indexado por `CubeColorIds`
  /// (white, yellow, green, blue, red, orange).
  static const List<Color> cube = [
    Colors.white,
    Color(0xFFFFEB3B),
    Color(0xFF22C55E),
    Color(0xFF1D4ED8),
    Color(0xFFF44336),
    Color(0xFFFF9800),
  ];

  /// Pyraminx: 0=F verde, 1=L rojo, 2=R azul, 3=D amarillo (esquema WCA).
  static const List<Color> pyraminx = [
    Color(0xFF22C55E),
    Color(0xFFF44336),
    Color(0xFF1D4ED8),
    Color(0xFFFFEB3B),
  ];

  /// Skewb, en el orden de caras del simulador
  /// (blanco, azul, rojo, amarillo, verde, naranja).
  static const List<Color> skewb = [
    Colors.white,
    Color(0xFF1D4ED8),
    Color(0xFFF44336),
    Color(0xFFFFEB3B),
    Color(0xFF22C55E),
    Color(0xFFFF9800),
  ];

  /// Megaminx: 12 colores estándar de csTimer, indexados por cara 0..11.
  static const List<Color> megaminx = [
    Color(0xFFFFFFFF), // 0 U blanco
    Color(0xFFDD0000), // 1 rojo oscuro
    Color(0xFF006600), // 2 F verde oscuro
    Color(0xFF8811FF), // 3 violeta
    Color(0xFFFFCC00), // 4 amarillo dorado
    Color(0xFF0000BB), // 5 azul oscuro
    Color(0xFFFFFFBB), // 6 crema
    Color(0xFF88DDFF), // 7 celeste
    Color(0xFFFF8833), // 8 naranja
    Color(0xFF77EE00), // 9 lima
    Color(0xFFFF99FF), // 10 rosa
    Color(0xFF999999), // 11 D gris
  ];

  /// Square-1, por cara (esquema por defecto de csTimer: U amarillo arriba,
  /// D blanco abajo, R naranja, L rojo).
  static const Map<String, Color> square1 = {
    'U': Color(0xFFFFEB3B),
    'R': Color(0xFFFF9800),
    'F': Color(0xFF22C55E),
    'D': Colors.white,
    'L': Color(0xFFF44336),
    'B': Color(0xFF1D4ED8),
  };

  /// Colores del Clock (esquema csTimer).
  static const Color clockFront = Color(0xFF3377BB);
  static const Color clockBack = Color(0xFF55CCFF);
  static const Color clockNeedle = Color(0xFFFFEB3B);
  static const Color clockNeedleEdge = Color(0xFFCC3333);
  static const Color clockPinUp = Color(0xFFFFEB3B);
  static const Color clockPinDown = Color(0xFF885500);
}
