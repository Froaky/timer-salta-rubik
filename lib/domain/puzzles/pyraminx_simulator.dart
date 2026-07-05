/// Simulador facelet puro para Pyraminx, portado de csTimer (`image.js`).
///
/// Orientación WCA: amarillo abajo, verde al frente.
/// Caras (y su id de color): 0 = Front (verde), 1 = Left (rojo),
/// 2 = Right (azul), 3 = Down (amarillo).
///
/// Cada cara tiene 9 stickers. La numeración de stickers es la de csTimer;
/// el painter de presentación conoce la posición de dibujo de cada índice:
///
/// Cara F (apunta arriba en el net):        Caras L/R/D (apuntan abajo):
/// ```
///        0                                  2 8 3 7 1
///      5 6 4                                  4 6 5
///    1 7 3 8 2                                  0
/// ```
library;

/// Estado facelet del Pyraminx: 4 caras de 9 stickers con ids 0..3.
class PyraminxFacelets {
  const PyraminxFacelets(this.faces);

  /// `faces[cara][sticker]` con cara 0=F, 1=L, 2=R, 3=D.
  final List<List<int>> faces;
}

class PyraminxSimulator {
  // Cada movimiento cicla 4 ternas de stickers (tip + capa); el tip solo la
  // primera. Tablas exactas de csTimer.
  static const List<int> _g1 = [0, 6, 5, 4];
  static const List<int> _g2 = [1, 7, 3, 5];
  static const List<int> _g3 = [2, 8, 4, 3];

  /// Caras afectadas por cada eje, en orden de ciclo (notación U, R, L, B).
  static const List<List<int>> _cycleFaces = [
    [0, 1, 2], // U
    [2, 3, 0], // R
    [1, 0, 3], // L
    [3, 2, 1], // B
  ];

  static const String _axisLetters = 'URLB';

  /// Aplica un scramble WCA de Pyraminx (`U L' R b u'`...).
  ///
  /// Mayúsculas giran capa + tip, minúsculas solo el tip. Tokens desconocidos
  /// se ignoran.
  PyraminxFacelets apply(String notation) {
    final posit = List<int>.generate(36, (i) => i ~/ 9, growable: false);

    for (final token in notation.split(RegExp(r'\s+'))) {
      final match = RegExp(r"^([ULRBulrb])(')?$").firstMatch(token.trim());
      if (match == null) {
        continue;
      }
      final letter = match.group(1)!;
      final tipOnly = letter == letter.toLowerCase();
      final axis = _axisLetters.indexOf(letter.toUpperCase());
      // Un giro horario es un ciclo; el antihorario equivale a dos (orden 3).
      final power = match.group(2) == "'" ? 2 : 1;
      _turn(posit, axis, tipOnly: tipOnly, power: power);
    }

    return PyraminxFacelets(
      List.generate(
        4,
        (face) => posit.sublist(face * 9, face * 9 + 9),
        growable: false,
      ),
    );
  }

  static void _turn(
    List<int> posit,
    int axis, {
    required bool tipOnly,
    required int power,
  }) {
    final faces = _cycleFaces[axis];
    final tripleCount = tipOnly ? 1 : 4;
    for (var i = 0; i < tripleCount; i++) {
      for (var p = 0; p < power; p++) {
        _cycle3(
          posit,
          faces[0] * 9 + _g1[i],
          faces[1] * 9 + _g2[i],
          faces[2] * 9 + _g3[i],
        );
      }
    }
  }

  /// Ciclo a→b→c→a (semántica de `mathlib.circle` de csTimer).
  static void _cycle3(List<int> arr, int a, int b, int c) {
    final temp = arr[c];
    arr[c] = arr[b];
    arr[b] = arr[a];
    arr[a] = temp;
  }
}
