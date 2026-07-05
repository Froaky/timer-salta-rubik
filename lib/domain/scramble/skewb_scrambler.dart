import 'dart:math';
import 'dart:typed_data';

/// Generador de scrambles *random-state* para el Skewb, con la misma fortaleza
/// que TNoodle.
///
/// El estado del Skewb es un producto directo de dos subespacios independientes:
/// los 6 centros (360 permutaciones pares alcanzables) y las 8 esquinas (8748
/// estados alcanzables) → 360 × 8748 = 3.149.280 estados. Se sortea uno
/// uniformemente, se calcula su solución óptima (≤ 11 giros) y se invierte.
///
/// El modelo de movimientos se deriva del simulador facelet de csTimer
/// (`skewb_simulator.dart`, el mismo que usa el preview): las esquinas se
/// identifican por su "máscara de movimientos" (los 3 stickers de una esquina
/// son movidos por el mismo subconjunto de giros) y todo se valida con BFS de
/// cobertura total. Notación WCA: `R U L B` con modificador `'`.
class SkewbScrambler {
  SkewbScrambler._();

  static final SkewbScrambler instance = SkewbScrambler._();

  static const String _axisLetters = 'RULB';

  /// Ternas de stickers cicladas por cada movimiento (R, U, L, B). Tabla exacta
  /// de csTimer; la primera terna de cada giro son los 3 centros.
  static const List<List<List<int>>> _moveCycles = [
    [
      [10, 5, 15],
      [14, 8, 17],
      [12, 9, 16],
      [13, 6, 19],
      [24, 4, 28]
    ], // R
    [
      [0, 25, 5],
      [2, 26, 7],
      [4, 27, 9],
      [1, 28, 6],
      [21, 19, 12]
    ], // U
    [
      [20, 15, 25],
      [23, 18, 29],
      [21, 16, 28],
      [24, 19, 27],
      [13, 9, 1]
    ], // L
    [
      [5, 25, 15],
      [9, 28, 19],
      [8, 26, 18],
      [7, 29, 17],
      [2, 23, 14]
    ], // B
  ];
  static const List<int> _centerPositions = [0, 5, 10, 15, 20, 25];

  static const int _cornerCount = 8748;
  static const int _centerCount = 360;
  static const int _stateCount = _centerCount * _cornerCount; // 3.149.280

  int get stateCount => _stateCount;
  int get cornerSubspaceCount => _cornerCount;
  int get centerSubspaceCount => _centerCount;

  // Estructura de piezas (identificada en tiempo de construcción).
  List<List<int>>? _cornerSlots; // 8 x 3 (posiciones, ordenadas por cara)
  List<int>? _primaryColor; // color primario (para orientación) por pieza
  Int32List? _maskToPiece; // color-bitmask -> índice de pieza

  Int32List? _cornerTrans; // [8748 * 8] transición de esquinas en denso
  Int32List? _centerTrans; // [360  * 8] transición de centros en denso
  Uint8List? _dist; // [_stateCount] distancia al resuelto
  int _startCe = 0;
  int _startCo = 0;

  bool get _ready => _dist != null;

  /// Genera un scramble de Skewb como lista de movimientos (`R`, `U'`, ...).
  List<String> generateScramble(Random random) {
    _ensureTables();
    final ce = random.nextInt(_centerCount);
    final co = random.nextInt(_cornerCount);
    return _solveInverted(ce, co);
  }

  /// Scramble que lleva el resuelto al estado (centro [ce], esquina [co]).
  /// Expuesto para tests de ida y vuelta.
  List<String> scrambleForState(int ce, int co) {
    _ensureTables();
    return _solveInverted(ce, co);
  }

  /// Aplica una secuencia de giros al resuelto (vía transiciones densas) y
  /// devuelve el estado `[ce, co]` resultante. Para verificación en tests.
  List<int> applyMovesToSolved(List<String> moves) {
    _ensureTables();
    final ct = _cornerTrans!;
    final et = _centerTrans!;
    var ce = _startCe;
    var co = _startCo;
    for (final name in moves) {
      final axis = _axisLetters.indexOf(name[0]);
      final m = axis * 2 + (name.endsWith("'") ? 1 : 0);
      ce = et[ce * 8 + m];
      co = ct[co * 8 + m];
    }
    return [ce, co];
  }

  List<String> _solveInverted(int ce, int co) {
    final dist = _dist!;
    final ct = _cornerTrans!;
    final et = _centerTrans!;

    var cce = ce;
    var cco = co;
    final solution = <int>[];
    var d = dist[cce * _cornerCount + cco];
    while (d > 0) {
      final eBase = cce * 8;
      final cBase = cco * 8;
      for (int m = 0; m < 8; m++) {
        final nce = et[eBase + m];
        final nco = ct[cBase + m];
        if (dist[nce * _cornerCount + nco] == d - 1) {
          solution.add(m);
          cce = nce;
          cco = nco;
          d--;
          break;
        }
      }
    }

    final scramble = <String>[];
    for (int i = solution.length - 1; i >= 0; i--) {
      scramble.add(_invertedName(solution[i]));
    }
    return scramble;
  }

  static String _invertedName(int m) {
    final face = _axisLetters[m ~/ 2];
    // 1 giro (m par) -> inverso "X'"; 2 giros (m impar) -> "X" (orden 3).
    return (m & 1) == 0 ? "$face'" : face;
  }

  void _ensureTables() {
    if (_ready) return;
    _identifyPieces();
    _buildSubspaces();
    _buildDistance();
  }

  static List<int> _applyMove(List<int> posit, int axis, int power) {
    final p = List<int>.of(posit);
    for (int t = 0; t < power; t++) {
      for (final c in _moveCycles[axis]) {
        final tmp = p[c[2]];
        p[c[2]] = p[c[1]];
        p[c[1]] = p[c[0]];
        p[c[0]] = tmp;
      }
    }
    return p;
  }

  /// Identifica las 8 esquinas por su máscara de movimientos: los 3 stickers de
  /// una misma esquina son movidos exactamente por el mismo subconjunto de los
  /// 4 giros.
  void _identifyPieces() {
    final id = List<int>.generate(30, (i) => i);
    final movePerm = [for (int a = 0; a < 4; a++) _applyMove(id, a, 1)];
    final fwd = [
      for (int a = 0; a < 4; a++)
        (() {
          final f = List<int>.filled(30, -1);
          for (int d = 0; d < 30; d++) {
            f[movePerm[a][d]] = d;
          }
          return f;
        })()
    ];

    final byMask = <int, List<int>>{};
    for (int s = 0; s < 30; s++) {
      if (s % 5 == 0) continue; // centros
      var mask = 0;
      for (int a = 0; a < 4; a++) {
        if (fwd[a][s] != s) mask |= (1 << a);
      }
      byMask.putIfAbsent(mask, () => []).add(s);
    }

    final cornerSlots = [
      for (final slots in byMask.values)
        (slots..sort((a, b) => (a ~/ 5) - (b ~/ 5)))
    ];
    final primaryColor = <int>[];
    final maskToPiece = Int32List(64)..fillRange(0, 64, -1);
    for (int p = 0; p < cornerSlots.length; p++) {
      final colors = [for (final s in cornerSlots[p]) s ~/ 5];
      primaryColor.add(colors[0]);
      var colorMask = 0;
      for (final c in colors) {
        colorMask |= (1 << c);
      }
      maskToPiece[colorMask] = p;
    }

    _cornerSlots = cornerSlots;
    _primaryColor = primaryColor;
    _maskToPiece = maskToPiece;
  }

  int _cornerKey(List<int> posit) {
    final slots = _cornerSlots!;
    final maskToPiece = _maskToPiece!;
    final primary = _primaryColor!;
    // Permutación (Lehmer sobre 8) y orientación (base 3) juntas.
    final cornerAt = List<int>.filled(8, 0);
    var ori = 0;
    for (int b = 0; b < 8; b++) {
      final c0 = posit[slots[b][0]];
      final c1 = posit[slots[b][1]];
      final c2 = posit[slots[b][2]];
      final piece = maskToPiece[(1 << c0) | (1 << c1) | (1 << c2)];
      cornerAt[b] = piece;
      final prim = primary[piece];
      final o = c0 == prim ? 0 : (c1 == prim ? 1 : 2);
      ori = ori * 3 + o;
    }
    // Lehmer(cornerAt) * 3^8 + ori.
    var lehmer = 0;
    for (int i = 0; i < 8; i++) {
      lehmer *= (8 - i);
      for (int j = i + 1; j < 8; j++) {
        if (cornerAt[j] < cornerAt[i]) lehmer++;
      }
    }
    return lehmer * 6561 + ori;
  }

  int _centerKey(List<int> posit) {
    final c = [for (final p in _centerPositions) posit[p]];
    var lehmer = 0;
    for (int i = 0; i < 6; i++) {
      lehmer *= (6 - i);
      for (int j = i + 1; j < 6; j++) {
        if (c[j] < c[i]) lehmer++;
      }
    }
    return lehmer;
  }

  /// BFS de cada subespacio (esquinas y centros) sobre facelets, asignando
  /// índices densos y construyendo sus tablas de transición.
  void _buildSubspaces() {
    final solved = List<int>.generate(30, (i) => i ~/ 5);

    final cornerDense = <int, int>{_cornerKey(solved): 0};
    final cornerTrans = <int>[];
    final cq = <List<int>>[solved];
    var ch = 0;
    while (ch < cq.length) {
      final s = cq[ch++];
      for (int a = 0; a < 4; a++) {
        var cur = s;
        for (int pw = 1; pw <= 2; pw++) {
          cur = _applyMove(cur, a, 1);
          final k = _cornerKey(cur);
          var nd = cornerDense[k];
          if (nd == null) {
            nd = cornerDense.length;
            cornerDense[k] = nd;
            cq.add(cur);
          }
          cornerTrans.add(nd);
        }
      }
    }

    final centerDense = <int, int>{_centerKey(solved): 0};
    final centerTrans = <int>[];
    final eq = <List<int>>[solved];
    var eh = 0;
    while (eh < eq.length) {
      final s = eq[eh++];
      for (int a = 0; a < 4; a++) {
        var cur = s;
        for (int pw = 1; pw <= 2; pw++) {
          cur = _applyMove(cur, a, 1);
          final k = _centerKey(cur);
          var nd = centerDense[k];
          if (nd == null) {
            nd = centerDense.length;
            centerDense[k] = nd;
            eq.add(cur);
          }
          centerTrans.add(nd);
        }
      }
    }

    _cornerTrans = Int32List.fromList(cornerTrans);
    _centerTrans = Int32List.fromList(centerTrans);
    _startCe = centerDense[_centerKey(solved)]!;
    _startCo = cornerDense[_cornerKey(solved)]!;
  }

  /// BFS combinado en espacio denso: llena la tabla de distancia usando las
  /// transiciones de ambos subespacios (que se mueven en simultáneo).
  void _buildDistance() {
    final ct = _cornerTrans!;
    final et = _centerTrans!;
    final dist = Uint8List(_stateCount)..fillRange(0, _stateCount, 255);

    final queue = Uint32List(_stateCount);
    var head = 0;
    var tail = 0;
    final start = _startCe * _cornerCount + _startCo;
    dist[start] = 0;
    queue[tail++] = start;

    while (head < tail) {
      final s = queue[head++];
      final ce = s ~/ _cornerCount;
      final co = s % _cornerCount;
      final nd = dist[s] + 1;
      final eBase = ce * 8;
      final cBase = co * 8;
      for (int m = 0; m < 8; m++) {
        final ns = et[eBase + m] * _cornerCount + ct[cBase + m];
        if (dist[ns] == 255) {
          dist[ns] = nd;
          queue[tail++] = ns;
        }
      }
    }

    _dist = dist;
  }
}
