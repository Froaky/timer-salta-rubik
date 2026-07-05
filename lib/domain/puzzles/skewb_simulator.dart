/// Simulador facelet puro para Skewb, portado de csTimer (`image.js`).
///
/// Cada cara tiene 5 stickers: índice 0 es el cuadrado central (rotado 45°)
/// y 1..4 son los triángulos de las esquinas (1=sup-izq, 2=sup-der,
/// 3=inf-izq, 4=inf-der en el net de dibujo).
///
/// Ids de color por cara (esquema por defecto de csTimer, blanco arriba):
/// 0=blanco, 1=azul, 2=rojo, 3=amarillo, 4=verde, 5=naranja.
library;

/// Estado facelet del Skewb: 6 caras de 5 stickers con ids 0..5.
class SkewbFacelets {
  const SkewbFacelets(this.faces);

  /// `faces[cara][sticker]`.
  final List<List<int>> faces;
}

class SkewbSimulator {
  static const String _axisLetters = 'RULB';

  /// Ternas de stickers (índices en el arreglo plano de 30) cicladas por cada
  /// movimiento. Tablas exactas de csTimer.
  static const List<List<List<int>>> _moveCycles = [
    // R
    [
      [10, 5, 15],
      [14, 8, 17],
      [12, 9, 16],
      [13, 6, 19],
      [24, 4, 28],
    ],
    // U
    [
      [0, 25, 5],
      [2, 26, 7],
      [4, 27, 9],
      [1, 28, 6],
      [21, 19, 12],
    ],
    // L
    [
      [20, 15, 25],
      [23, 18, 29],
      [21, 16, 28],
      [24, 19, 27],
      [13, 9, 1],
    ],
    // B
    [
      [5, 25, 15],
      [9, 28, 19],
      [8, 26, 18],
      [7, 29, 17],
      [2, 23, 14],
    ],
  ];

  /// Aplica un scramble WCA de Skewb (`R U' L B ...`).
  SkewbFacelets apply(String notation) {
    final posit = List<int>.generate(30, (i) => i ~/ 5, growable: false);

    for (final token in notation.split(RegExp(r'\s+'))) {
      final match = RegExp(r"^([RULB])(')?$").firstMatch(token.trim());
      if (match == null) {
        continue;
      }
      final axis = _axisLetters.indexOf(match.group(1)!);
      // Los giros del Skewb tienen orden 3: X' equivale a X aplicado 2 veces.
      final power = match.group(2) == "'" ? 2 : 1;
      for (var p = 0; p < power; p++) {
        for (final cycle in _moveCycles[axis]) {
          _cycle3(posit, cycle[0], cycle[1], cycle[2]);
        }
      }
    }

    return SkewbFacelets(
      List.generate(
        6,
        (face) => posit.sublist(face * 5, face * 5 + 5),
        growable: false,
      ),
    );
  }

  /// Ciclo a→b→c→a (semántica de `mathlib.circle` de csTimer).
  static void _cycle3(List<int> arr, int a, int b, int c) {
    final temp = arr[c];
    arr[c] = arr[b];
    arr[b] = arr[a];
    arr[a] = temp;
  }
}
