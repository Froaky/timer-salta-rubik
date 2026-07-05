import 'dart:math';
import 'dart:typed_data';

/// Generador de scrambles *random-state* para el Pyraminx, con la misma
/// fortaleza que TNoodle.
///
/// Sortea un estado del "cuerpo" (4 esquinas axiales + 6 aristas)
/// uniformemente entre los 933.120 posibles, calcula su solución óptima
/// (≤ 11 giros) y la invierte; luego agrega giros de puntas (tips)
/// aleatorios uniformes. Notación WCA: `U L R B` (capa) y `u l r b` (solo
/// tip), con modificador `'`.
///
/// El modelo de movimientos fue derivado del simulador facelet de csTimer
/// (`pyraminx_simulator.dart`, el mismo que usa el preview) y verificado con
/// BFS de cobertura total, así que los scrambles son físicamente consistentes
/// con lo que se muestra.
class PyraminxScrambler {
  PyraminxScrambler._();

  static final PyraminxScrambler instance = PyraminxScrambler._();

  static const int _nCorner = 81; // 3^4 orientaciones de esquinas axiales
  static const int _nPerm = 720; // 6!  permutaciones de aristas
  static const int _nOri = 64; //   2^6 orientaciones de aristas
  static const int _nStates = _nCorner * _nPerm * _nOri; // 3.732.480
  static const int _bodyStates = 933120; // estados realmente alcanzables
  static const int _unseen = 255;

  int get stateCount => _nStates;
  int get bodyStateCount => _bodyStates;

  // Ejes en orden U, R, L, B (idéntico al simulador). Cada giro tuerce su
  // esquina en +1 y permuta/voltea 3 aristas. Constantes derivadas y validadas
  // con derive_pyraminx.dart (BFS == 933.120, maxDepth == 11).
  static const List<String> _axisNames = ['U', 'R', 'L', 'B'];
  static const List<String> _tipNames = ['u', 'r', 'l', 'b'];
  static const List<List<int>> _edgePermSrc = [
    [0, 3, 1, 2, 4, 5], // U
    [5, 0, 2, 3, 4, 1], // R
    [2, 1, 4, 3, 0, 5], // L
    [0, 1, 2, 5, 3, 4], // B
  ];
  static const List<List<int>> _edgeFlip = [
    [0, 1, 1, 0, 0, 0], // U
    [1, 1, 0, 0, 0, 0], // R
    [1, 0, 0, 0, 1, 0], // L
    [0, 0, 0, 0, 1, 1], // B
  ];

  // 8 movimientos de capa = {U,R,L,B} x {1, 2 tercios de giro}.
  // Índice m = eje*2 + (giros-1).
  Int32List? _cornerMove; // [_nCorner * 8]
  Int32List? _permMove; //   [_nPerm  * 8]
  Int32List? _oriMove; //    [_nOri   * 8]
  Uint8List? _dist; //       [_nStates]

  bool get _ready => _dist != null;

  /// Genera un scramble de Pyraminx como lista de movimientos.
  List<String> generateScramble(Random random) {
    _ensureTables();

    // Sortear un estado del cuerpo uniformemente entre los alcanzables.
    final co = [for (var i = 0; i < 4; i++) random.nextInt(3)];
    final ep = _randomEvenPerm(random);
    final eo = _randomEvenOri(random);
    final stateIdx =
        _encode(_cornerIndex(co), _permToIndex(ep), _oriToIndex(eo));

    final moves = _solveInverted(stateIdx);

    // Puntas: cada tip uniforme en {nada, horario, antihorario}. Como el giro
    // ya inducido por el cuerpo es fijo, sumar uniforme deja la punta uniforme.
    for (var ax = 0; ax < 4; ax++) {
      switch (random.nextInt(3)) {
        case 1:
          moves.add(_tipNames[ax]);
          break;
        case 2:
          moves.add("${_tipNames[ax]}'");
          break;
      }
    }
    return moves;
  }

  /// Cantidad de estados del cuerpo alcanzables por BFS (para tests: debe ser
  /// [bodyStateCount]).
  int reachableStateCount() {
    _ensureTables();
    final dist = _dist!;
    var count = 0;
    for (int i = 0; i < _nStates; i++) {
      if (dist[i] != _unseen) count++;
    }
    return count;
  }

  /// Índice de estado del cuerpo a partir de sus coordenadas crudas. Expuesto
  /// para tests de ida y vuelta.
  int encode(List<int> co, List<int> ep, List<int> eo) =>
      _encode(_cornerIndex(co), _permToIndex(ep), _oriToIndex(eo));

  /// Scramble (solo capa) que lleva el cubo resuelto al estado [stateIdx].
  List<String> scrambleForBodyIndex(int stateIdx) {
    _ensureTables();
    return _solveInverted(stateIdx);
  }

  /// Aplica una secuencia de giros de capa (`U`, `R'`, ...) al cubo resuelto y
  /// devuelve el índice de estado del cuerpo resultante. Trabaja sobre las
  /// piezas directamente (no usa las tablas de transición) para servir de
  /// verificación independiente.
  int applyBodyMovesToSolved(List<String> moves) {
    var co = <int>[0, 0, 0, 0];
    var ep = <int>[0, 1, 2, 3, 4, 5];
    var eo = <int>[0, 0, 0, 0, 0, 0];
    for (final move in moves) {
      final ax = _axisNames.indexOf(move[0]);
      if (ax < 0) continue; // tip u/l/r/b: no afecta al cuerpo
      final turns = move.endsWith("'") ? 2 : 1;
      for (var t = 0; t < turns; t++) {
        final nep = List<int>.filled(6, 0);
        final neo = List<int>.filled(6, 0);
        for (var i = 0; i < 6; i++) {
          final src = _edgePermSrc[ax][i];
          nep[i] = ep[src];
          neo[i] = (eo[src] + _edgeFlip[ax][i]) % 2;
        }
        ep = nep;
        eo = neo;
        co[ax] = (co[ax] + 1) % 3;
      }
    }
    return _encode(_cornerIndex(co), _permToIndex(ep), _oriToIndex(eo));
  }

  List<String> _solveInverted(int stateIdx) {
    final dist = _dist!;
    final cornerMove = _cornerMove!;
    final permMove = _permMove!;
    final oriMove = _oriMove!;

    var ci = stateIdx ~/ (_nPerm * _nOri);
    var pi = (stateIdx ~/ _nOri) % _nPerm;
    var oi = stateIdx % _nOri;

    final solution = <int>[];
    var d = dist[stateIdx];
    while (d > 0) {
      final cBase = ci * 8;
      final pBase = pi * 8;
      final oBase = oi * 8;
      for (int m = 0; m < 8; m++) {
        final nci = cornerMove[cBase + m];
        final npi = permMove[pBase + m];
        final noi = oriMove[oBase + m];
        if (dist[_encode(nci, npi, noi)] == d - 1) {
          solution.add(m);
          ci = nci;
          pi = npi;
          oi = noi;
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

  void _ensureTables() {
    if (_ready) return;
    _buildMoveTables();
    _buildDistanceTable();
  }

  void _buildMoveTables() {
    final cornerMove = Int32List(_nCorner * 8);
    final permMove = Int32List(_nPerm * 8);
    final oriMove = Int32List(_nOri * 8);

    for (int c = 0; c < _nCorner; c++) {
      final co = _indexToCorner(c);
      for (int ax = 0; ax < 4; ax++) {
        final cur = List<int>.of(co);
        for (int pw = 1; pw <= 2; pw++) {
          cur[ax] = (cur[ax] + 1) % 3;
          cornerMove[c * 8 + ax * 2 + (pw - 1)] = _cornerIndex(cur);
        }
      }
    }

    for (int p = 0; p < _nPerm; p++) {
      final perm = _indexToPerm(p);
      for (int ax = 0; ax < 4; ax++) {
        var cur = perm;
        for (int pw = 1; pw <= 2; pw++) {
          cur = [for (int i = 0; i < 6; i++) cur[_edgePermSrc[ax][i]]];
          permMove[p * 8 + ax * 2 + (pw - 1)] = _permToIndex(cur);
        }
      }
    }

    for (int o = 0; o < _nOri; o++) {
      final eo = _indexToOri(o);
      for (int ax = 0; ax < 4; ax++) {
        var cur = eo;
        for (int pw = 1; pw <= 2; pw++) {
          cur = [
            for (int i = 0; i < 6; i++)
              (cur[_edgePermSrc[ax][i]] + _edgeFlip[ax][i]) % 2
          ];
          oriMove[o * 8 + ax * 2 + (pw - 1)] = _oriToIndex(cur);
        }
      }
    }

    _cornerMove = cornerMove;
    _permMove = permMove;
    _oriMove = oriMove;
  }

  void _buildDistanceTable() {
    final dist = Uint8List(_nStates)..fillRange(0, _nStates, _unseen);
    final cornerMove = _cornerMove!;
    final permMove = _permMove!;
    final oriMove = _oriMove!;

    final queue = Uint32List(_bodyStates);
    var head = 0;
    var tail = 0;
    dist[0] = 0; // estado resuelto
    queue[tail++] = 0;

    while (head < tail) {
      final s = queue[head++];
      final ci = s ~/ (_nPerm * _nOri);
      final pi = (s ~/ _nOri) % _nPerm;
      final oi = s % _nOri;
      final nd = dist[s] + 1;
      final cBase = ci * 8;
      final pBase = pi * 8;
      final oBase = oi * 8;
      for (int m = 0; m < 8; m++) {
        final ns = _encode(
            cornerMove[cBase + m], permMove[pBase + m], oriMove[oBase + m]);
        if (dist[ns] == _unseen) {
          dist[ns] = nd;
          queue[tail++] = ns;
        }
      }
    }

    _dist = dist;
  }

  static int _encode(int cornerIdx, int permIdx, int oriIdx) =>
      (cornerIdx * _nPerm + permIdx) * _nOri + oriIdx;

  /// Nombre WCA del inverso del movimiento [m] (m = eje*2 + (giros-1)).
  static String _invertedName(int m) {
    final face = _axisNames[m ~/ 2];
    // 1 giro (m par) -> inverso 2 giros ("X'"); 2 giros (m impar) -> "X".
    return (m & 1) == 0 ? "$face'" : face;
  }

  // ---- Muestreo uniforme dentro del espacio alcanzable ----

  List<int> _randomEvenPerm(Random random) {
    final p = [0, 1, 2, 3, 4, 5];
    for (int i = 5; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final t = p[i];
      p[i] = p[j];
      p[j] = t;
    }
    // Las permutaciones de aristas alcanzables son pares; si salió impar, un
    // solo intercambio corrige la paridad (mapea uniforme -> uniforme par).
    if (_isOddPermutation(p)) {
      final t = p[0];
      p[0] = p[1];
      p[1] = t;
    }
    return p;
  }

  static bool _isOddPermutation(List<int> p) {
    var inversions = 0;
    for (int i = 0; i < p.length; i++) {
      for (int j = i + 1; j < p.length; j++) {
        if (p[i] > p[j]) inversions++;
      }
    }
    return inversions.isOdd;
  }

  List<int> _randomEvenOri(Random random) {
    final eo = List<int>.filled(6, 0);
    var sum = 0;
    for (int i = 0; i < 5; i++) {
      eo[i] = random.nextInt(2);
      sum += eo[i];
    }
    eo[5] = sum & 1; // la suma de volteos es par (invariante)
    return eo;
  }

  // ---- Coordenadas ----

  static int _cornerIndex(List<int> co) =>
      co[0] + 3 * co[1] + 9 * co[2] + 27 * co[3];

  static List<int> _indexToCorner(int index) {
    var idx = index;
    final co = List<int>.filled(4, 0);
    for (int i = 0; i < 4; i++) {
      co[i] = idx % 3;
      idx ~/= 3;
    }
    return co;
  }

  static int _permToIndex(List<int> p) {
    var index = 0;
    for (int i = 0; i < 6; i++) {
      index *= (6 - i);
      for (int j = i + 1; j < 6; j++) {
        if (p[j] < p[i]) index++;
      }
    }
    return index;
  }

  static List<int> _indexToPerm(int index) {
    final code = List<int>.filled(6, 0);
    var idx = index;
    for (int i = 5; i >= 0; i--) {
      final radix = 6 - i;
      code[i] = idx % radix;
      idx ~/= radix;
    }
    final available = <int>[0, 1, 2, 3, 4, 5];
    final p = List<int>.filled(6, 0);
    for (int i = 0; i < 6; i++) {
      p[i] = available.removeAt(code[i]);
    }
    return p;
  }

  static int _oriToIndex(List<int> eo) {
    var index = 0;
    for (int i = 0; i < 6; i++) {
      index = index * 2 + eo[i];
    }
    return index;
  }

  static List<int> _indexToOri(int index) {
    final eo = List<int>.filled(6, 0);
    var idx = index;
    for (int i = 5; i >= 0; i--) {
      eo[i] = idx & 1;
      idx >>= 1;
    }
    return eo;
  }
}
