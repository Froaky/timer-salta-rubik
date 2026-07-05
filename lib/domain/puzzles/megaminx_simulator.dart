/// Simulador facelet puro para Megaminx (notación Pochmann WCA), portado de
/// csTimer (`image.js`).
///
/// El estado son 12 caras de 11 stickers: índices 0..4 esquinas, 5..9 aristas
/// y 10 el centro. El id de color de cada sticker es el índice de la cara en
/// la que nace (0..11), a resolver con la paleta estándar en presentación.
///
/// Caras 0..5 forman la "flor" superior (0 = U, 2 = F) y 6..11 la inferior
/// (11 = D), igual que el net de csTimer.
library;

/// Estado facelet del Megaminx: 12 caras de 11 stickers con ids 0..11.
class MegaminxFacelets {
  const MegaminxFacelets(this.faces);

  /// `faces[cara][sticker]` con esquinas 0..4, aristas 5..9, centro 10.
  final List<List<int>> faces;
}

class MegaminxSimulator {
  // Permutaciones exactas de csTimer sobre el estado plano de 132 stickers.
  // Aplicar el mapa una vez equivale a U (72°) o a R++/D++ (144° del bloque).
  static const List<int> _moveU = [
    4, 0, 1, 2, 3, 9, 5, 6, 7, 8, 10, 11, 12, 13, 58, 59, 16, 17, 18, 63, 20,
    21, 22, 23, 24, 14, 15, 27, 28, 29, 19, 31, 32, 33, 34, 35, 25, 26, 38, //
    39, 40, 30, 42, 43, 44, 45, 46, 36, 37, 49, 50, 51, 41, 53, 54, 55, 56,
    57, 47, 48, 60, 61, 62, 52, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74,
    75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92,
    93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108,
    109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123,
    124, 125, 126, 127, 128, 129, 130, 131,
  ];

  static const List<int> _moveR = [
    81, 77, 78, 3, 4, 86, 82, 83, 8, 85, 87, 122, 123, 124, 125, 121, 127, //
    128, 129, 130, 126, 131, 89, 90, 24, 25, 88, 94, 95, 29, 97, 93, 98, 33,
    34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 26, 22, 23, 48, 30, 31, 27,
    28, 53, 32, 69, 70, 66, 67, 68, 74, 75, 71, 72, 73, 76, 101, 102, 103, 99,
    100, 106, 107, 108, 104, 105, 109, 46, 47, 79, 80, 45, 51, 52, 84, 49, 50,
    54, 0, 1, 2, 91, 92, 5, 6, 7, 96, 9, 10, 15, 11, 12, 13, 14, 20, 16, 17,
    18, 19, 21, 113, 114, 110, 111, 112, 118, 119, 115, 116, 117, 120, 55, 56,
    57, 58, 59, 60, 61, 62, 63, 64, 65,
  ];

  static const List<int> _moveD = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 33, 34, 35, 14, 15, 38, 39, 40, 19, 42,
    43, 44, 45, 46, 25, 26, 49, 50, 51, 30, 53, 54, 55, 56, 57, 36, 37, 60, //
    61, 62, 41, 64, 65, 11, 12, 13, 47, 48, 16, 17, 18, 52, 20, 21, 22, 23,
    24, 58, 59, 27, 28, 29, 63, 31, 32, 88, 89, 90, 91, 92, 93, 94, 95, 96,
    97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111,
    112, 113, 114, 115, 116, 117, 118, 119, 120, 66, 67, 68, 69, 70, 71, 72,
    73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 124, 125, 121,
    122, 123, 129, 130, 126, 127, 128, 131,
  ];

  static const List<List<int>> _moveMaps = [_moveU, _moveR, _moveD];

  /// Aplica un scramble Pochmann (`R++ D-- U'` en líneas separadas por
  /// espacios o saltos de línea). Tokens desconocidos se ignoran.
  MegaminxFacelets apply(String notation) {
    var state = List<int>.generate(132, (i) => i ~/ 11, growable: false);

    for (final token in notation.split(RegExp(r'\s+'))) {
      final match =
          RegExp(r"^(?:([RD])(\+\+|--)|(U)('?))$").firstMatch(token.trim());
      if (match == null) {
        continue;
      }
      final isU = match.group(3) != null;
      final axis = isU ? 0 : (match.group(1) == 'R' ? 1 : 2);
      final inverted = isU ? match.group(4) == "'" : match.group(2) == '--';
      state = _permuted(state, _moveMaps[axis], inverted: inverted);
    }

    return MegaminxFacelets(
      List.generate(
        12,
        (face) => state.sublist(face * 11, face * 11 + 11),
        growable: false,
      ),
    );
  }

  static List<int> _permuted(
    List<int> state,
    List<int> map, {
    required bool inverted,
  }) {
    final next = List<int>.filled(132, 0, growable: false);
    for (var i = 0; i < 132; i++) {
      if (inverted) {
        next[map[i]] = state[i];
      } else {
        next[i] = state[map[i]];
      }
    }
    return next;
  }
}
