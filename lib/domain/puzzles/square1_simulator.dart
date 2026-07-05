/// Simulador puro para Square-1, portado de csTimer (`scramble_sq1_new.js`
/// + `image.js`).
///
/// El estado son 24 slots de 30°: 0..11 la capa superior (empezando en la
/// posición 12 en punto, sentido horario) y 12..23 la inferior. Cada slot
/// guarda el id de pieza 0..15; las esquinas ocupan dos slots contiguos con
/// el mismo id. Ids pares = aristas, impares = esquinas. Piezas 0..7 nacen
/// en la capa U y 8..15 en la D.
library;

/// Modelo de piezas del Square-1 (port bit a bit de `SqCubie` de csTimer).
///
/// `ul`/`ur`/`dl`/`dr` empaquetan 6 slots de 4 bits cada uno; `middleOffset`
/// vale 0 si la capa media es cuadrada y 1 si está desfasada.
class Square1Cubie {
  int ul = 0x011233;
  int ur = 0x455677;
  int dl = 0x998bba;
  int dr = 0xddcffe;
  int middleOffset = 0;

  int pieceAt(int idx) {
    final int packed;
    if (idx < 6) {
      packed = ul >> ((5 - idx) << 2);
    } else if (idx < 12) {
      packed = ur >> ((11 - idx) << 2);
    } else if (idx < 18) {
      packed = dl >> ((17 - idx) << 2);
    } else {
      packed = dr >> ((23 - idx) << 2);
    }
    return packed & 0xf;
  }

  /// `move` > 0 gira la capa superior esa cantidad de slots, `move` < 0 la
  /// inferior, y `move` == 0 ejecuta el slice (`/`).
  void doMove(int move) {
    var shift = move << 2;
    int temp;
    if (shift > 24) {
      shift = 48 - shift;
      temp = ul;
      ul = (ul >> shift | ur << (24 - shift)) & 0xffffff;
      ur = (ur >> shift | temp << (24 - shift)) & 0xffffff;
    } else if (shift > 0) {
      temp = ul;
      ul = (ul << shift | ur >> (24 - shift)) & 0xffffff;
      ur = (ur << shift | temp >> (24 - shift)) & 0xffffff;
    } else if (shift == 0) {
      temp = ur;
      ur = dl;
      dl = temp;
      middleOffset = 1 - middleOffset;
    } else if (shift >= -24) {
      shift = -shift;
      temp = dl;
      dl = (dl << shift | dr >> (24 - shift)) & 0xffffff;
      dr = (dr << shift | temp >> (24 - shift)) & 0xffffff;
    } else {
      shift = 48 + shift;
      temp = dl;
      dl = (dl >> shift | dr << (24 - shift)) & 0xffffff;
      dr = (dr >> shift | temp << (24 - shift)) & 0xffffff;
    }
  }

  /// El slice corta la capa superior entre los slots 5|6 y 11|0; es legal
  /// solo si ninguna esquina queda atravesando el corte.
  bool get topSliceable =>
      pieceAt(5) != pieceAt(6) && pieceAt(11) != pieceAt(0);

  /// Corte inferior entre los slots 17|18 y 23|12.
  bool get bottomSliceable =>
      pieceAt(17) != pieceAt(18) && pieceAt(23) != pieceAt(12);

  Square1Cubie clone() {
    return Square1Cubie()
      ..ul = ul
      ..ur = ur
      ..dl = dl
      ..dr = dr
      ..middleOffset = middleOffset;
  }
}

/// Estado del Square-1 tras aplicar un scramble, listo para dibujar.
class Square1State {
  const Square1State({required this.pieces, required this.middleIsSquare});

  /// Id de pieza (0..15) en cada uno de los 24 slots.
  final List<int> pieces;

  /// `true` si la capa media quedó cuadrada.
  final bool middleIsSquare;
}

class Square1Simulator {
  static final RegExp _pairPattern =
      RegExp(r'^\s*\(\s*(-?\d+)\s*,\s*(-?\d+)\s*\)\s*$');

  /// Aplica un scramble en notación `(top,bottom) / (top,bottom) / ...`.
  ///
  /// Entre cada par (separador `/`) se ejecuta un slice. Segmentos que no
  /// matchean la notación se ignoran.
  Square1State apply(String notation) {
    final cubie = Square1Cubie();
    final segments = notation.split('/');

    for (var i = 0; i < segments.length; i++) {
      final match = _pairPattern.firstMatch(segments[i]);
      if (match != null) {
        final top = (int.parse(match.group(1)!) + 12) % 12;
        final bottom = (int.parse(match.group(2)!) + 12) % 12;
        if (top != 0) {
          cubie.doMove(top);
        }
        if (bottom != 0) {
          cubie.doMove(-bottom);
        }
      }
      final isLast = i == segments.length - 1;
      if (!isLast) {
        cubie.doMove(0);
      }
    }

    return Square1State(
      pieces: List<int>.generate(24, cubie.pieceAt, growable: false),
      middleIsSquare: cubie.middleOffset == 0,
    );
  }
}
