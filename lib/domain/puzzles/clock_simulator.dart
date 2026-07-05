/// Simulador puro para Rubik's Clock (notación WCA), portado de csTimer
/// (`image.js` + `scramble/clock.js`).
///
/// El resultado son las dos grillas de 9 relojes (izquierda = frente tras el
/// `y2` del scramble estándar, derecha = dorso) con horas 0..11, más el estado
/// de los 8 pines visibles.
library;

/// Estado final del Clock listo para dibujar.
class ClockDialsState {
  const ClockDialsState({
    required this.leftDials,
    required this.rightDials,
    required this.frontOnLeft,
    required this.pinsUp,
  });

  /// Horas (0..11) de la grilla izquierda, row-major (fila por fila).
  final List<int> leftDials;

  /// Horas (0..11) de la grilla derecha, row-major.
  final List<int> rightDials;

  /// `true` si la grilla izquierda corresponde al frente del reloj
  /// (scrambles WCA estándar con un `y2`). Solo afecta el color de las caras.
  final bool frontOnLeft;

  /// Pines en orden de dibujo: para cada grilla (izquierda, derecha) los 4
  /// pines interiores como [sup-izq, inf-izq, sup-der, inf-der].
  /// `true` = pin arriba (amarillo).
  final List<bool> pinsUp;
}

class ClockSimulator {
  static const List<String> _moveOrder = [
    'UR', 'DR', 'DL', 'UL', 'U', 'R', 'D', 'L', 'ALL', //
  ];

  /// Efecto de cada eje de giro sobre los 14 relojes independientes.
  /// Filas 0..8: movimientos después del `y2`; filas 9..17: antes del `y2`.
  /// Tabla exacta de csTimer (`scramble/clock.js`).
  static const List<List<int>> _moveArr = [
    [0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0],
    [1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0],
    [0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0],
    [1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0],
    [11, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0],
    [0, 0, 0, 0, 0, 0, 11, 0, 0, 0, 0, 1, 1, 1],
    [0, 0, 0, 0, 0, 0, 0, 0, 11, 0, 1, 1, 0, 1],
    [0, 0, 11, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0],
    [11, 0, 11, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0],
    [11, 0, 0, 0, 0, 0, 11, 0, 0, 1, 0, 1, 1, 1],
    [0, 0, 0, 0, 0, 0, 11, 0, 11, 0, 1, 1, 1, 1],
    [0, 0, 11, 0, 0, 0, 0, 0, 11, 1, 1, 1, 0, 1],
    [11, 0, 11, 0, 0, 0, 11, 0, 11, 1, 1, 1, 1, 1],
  ];

  /// Aplica un scramble WCA de Clock (`UR1- DR5+ ... y2 U3- ... UL`).
  ///
  /// Los tokens de pin sueltos al final (`UR`, `DL`...) marcan pines arriba.
  ClockDialsState apply(String notation) {
    final clks = List<int>.filled(14, 0);
    final buttons = List<int>.filled(4, 0);
    var flip = 9;

    final tokenPattern = RegExp(r'^(UR|DR|DL|UL|ALL|[URDL])(?:(\d)([+-]?))?$');

    for (final token in notation.split(RegExp(r'\s+'))) {
      final trimmed = token.trim();
      if (trimmed == 'y2') {
        flip = 9 - flip;
        continue;
      }
      final match = tokenPattern.firstMatch(trimmed);
      if (match == null) {
        continue;
      }
      final index = _moveOrder.indexOf(match.group(1)!);
      if (index < 0) {
        continue;
      }
      final axis = index + flip;
      if (match.group(2) == null) {
        // Token de pin (sin dígito): solo válido para esquinas UR/DR/DL/UL.
        if (index < 4) {
          buttons[index] = 1;
        }
        continue;
      }
      final amount = int.parse(match.group(2)!);
      final power = amount * (match.group(3) == '-' ? -1 : 1) + 12;
      for (var j = 0; j < 14; j++) {
        clks[j] = (clks[j] + _moveArr[axis][j] * power) % 12;
      }
    }

    // Expansión de los 14 relojes independientes a los 18 visibles
    // (los relojes de esquina se comparten entre frente y dorso, invertidos).
    final display = <int>[
      clks[0], clks[3], clks[6], clks[1], clks[4], clks[7], //
      clks[2], clks[5], clks[8],
      (12 - clks[2]) % 12, clks[10], (12 - clks[8]) % 12,
      clks[9], clks[11], clks[13],
      (12 - clks[0]) % 12, clks[12], (12 - clks[6]) % 12,
    ];

    // Cada valor `ii` se dibuja en la posición `(ii + flip) % 18`; las
    // posiciones 0..8 son la grilla izquierda en orden columna-por-columna.
    final byPosition = List<int>.filled(18, 0);
    for (var ii = 0; ii < 18; ii++) {
      byPosition[(ii + flip) % 18] = display[ii];
    }

    List<int> gridRowMajor(int offset) {
      final grid = List<int>.filled(9, 0);
      for (var p = 0; p < 9; p++) {
        final column = p ~/ 3;
        final row = p % 3;
        grid[row * 3 + column] = byPosition[offset + p];
      }
      return grid;
    }

    final pins = <bool>[
      buttons[3] == 1, // izquierda sup-izq (UL)
      buttons[2] == 1, // izquierda inf-izq (DL)
      buttons[0] == 1, // izquierda sup-der (UR)
      buttons[1] == 1, // izquierda inf-der (DR)
      buttons[0] == 0, // derecha sup-izq (UR visto desde atrás)
      buttons[1] == 0,
      buttons[3] == 0,
      buttons[2] == 0,
    ];

    return ClockDialsState(
      leftDials: gridRowMajor(0),
      rightDials: gridRowMajor(9),
      frontOnLeft: flip == 0,
      pinsUp: pins,
    );
  }
}
