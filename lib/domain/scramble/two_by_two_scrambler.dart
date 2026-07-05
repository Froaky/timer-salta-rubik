import 'dart:math';
import 'dart:typed_data';

/// Generador de scrambles *random-state* para el 2x2x2, con la misma fortaleza
/// estadística que TNoodle (el generador oficial de la WCA).
///
/// A diferencia de un generador de "movimientos al azar", este sortea un estado
/// del cubo **uniformemente** entre los 3.674.160 posibles y luego calcula su
/// solución **óptima**, que invertida se emite como scramble. Eso garantiza que
/// todos los estados sean equiprobables (justicia estadística) y que el scramble
/// no tenga movimientos redundantes.
///
/// Modelo: se fija la esquina DBL como referencia (elimina la redundancia por
/// rotación del cubo entero, igual que TNoodle) y se trabaja con las otras 7
/// esquinas. Solo se usan las caras R, U, F, que generan todo el grupo del 2x2
/// — exactamente la notación de los scrambles WCA.
///
/// El costo de construir las tablas (BFS sobre los ~3,67M estados) se paga una
/// sola vez, de forma perezosa, y queda cacheado en [instance].
class TwoByTwoScrambler {
  TwoByTwoScrambler._();

  /// Instancia compartida: las tablas se construyen una única vez.
  static final TwoByTwoScrambler instance = TwoByTwoScrambler._();

  static const int _nPerm = 5040; // 7!  permutaciones de las 7 esquinas móviles
  static const int _nOri = 729; //  3^6 orientaciones (la 7ª queda determinada)
  static const int _nStates = _nPerm * _nOri; // 3.674.160
  static const int _unseen = 255;

  /// Cantidad total de estados alcanzables (para verificación en tests).
  int get stateCount => _nStates;

  /// Cantidad de permutaciones (7!) y de orientaciones (3^6). Expuestas para
  /// que los tests puedan recorrer el espacio de estados.
  int get permCount => _nPerm;
  int get orientationCount => _nOri;

  // Movimientos base sobre las 7 esquinas móviles (DBL fija). Orden: U, R, F.
  // Etiquetas de esquina tras quitar DBL:
  // 0=URF 1=UFL 2=ULB 3=UBR 4=DFR 5=DLF 6=DRB
  static const List<List<int>> _baseCp = [
    [3, 0, 1, 2, 4, 5, 6], // U
    [4, 1, 2, 0, 6, 5, 3], // R
    [1, 5, 2, 3, 0, 4, 6], // F
  ];
  static const List<List<int>> _baseCo = [
    [0, 0, 0, 0, 0, 0, 0], // U
    [2, 0, 0, 1, 1, 0, 2], // R
    [1, 2, 0, 0, 2, 1, 0], // F
  ];

  // 9 movimientos = {U, R, F} x {1, 2, 3 cuartos de giro}.
  // Índice de movimiento m = base*3 + (giros-1).
  static const List<String> _faces = ['U', 'R', 'F'];

  // Tablas de transición: para cada coordenada y cada uno de los 9 movimientos,
  // la coordenada resultante. Permutación y orientación se transforman de forma
  // independiente, así que se indexan por separado.
  Int32List? _permMove; // [_nPerm * 9]
  Int32List? _oriMove; //  [_nOri  * 9]
  Uint8List? _dist; //     [_nStates] distancia al estado resuelto (God's table)

  bool get _ready => _dist != null;

  /// Genera un scramble de 2x2 como lista de movimientos (p. ej. `["R", "U'",
  /// "F2", ...]`). Sortea un estado uniforme y devuelve la inversa de su
  /// solución óptima; la longitud es ≤ 11 (número de Dios del 2x2 en HTM).
  List<String> generateScramble(Random random) {
    _ensureTables();
    final dist = _dist!;

    // Sortear un estado uniformemente (evitando el ya resuelto / inalcanzable).
    int p, o, state;
    do {
      p = random.nextInt(_nPerm);
      o = random.nextInt(_nOri);
      state = p * _nOri + o;
    } while (dist[state] == 0 || dist[state] == _unseen);

    return scrambleForState(p, o);
  }

  /// Scramble (inversa de la solución óptima) que lleva el cubo resuelto al
  /// estado ([permIndex], [oriIndex]). Base de [generateScramble]; también se
  /// usa desde los tests para verificar el pipeline con estados conocidos.
  List<String> scrambleForState(int permIndex, int oriIndex) {
    _ensureTables();
    final dist = _dist!;
    final permMove = _permMove!;
    final oriMove = _oriMove!;

    // Resolver por descenso de gradiente: en cada paso elegir el movimiento que
    // baja la distancia en 1. La solución lleva estado -> resuelto.
    var p = permIndex;
    var o = oriIndex;
    final solution = <int>[];
    var d = dist[p * _nOri + o];
    while (d > 0) {
      final permBase = p * 9;
      final oriBase = o * 9;
      for (int m = 0; m < 9; m++) {
        final np = permMove[permBase + m];
        final no = oriMove[oriBase + m];
        if (dist[np * _nOri + no] == d - 1) {
          solution.add(m);
          p = np;
          o = no;
          d--;
          break;
        }
      }
    }

    // Scramble = inversa de la solución (orden inverso + cada giro invertido).
    final scramble = <String>[];
    for (int i = solution.length - 1; i >= 0; i--) {
      scramble.add(_invertedName(solution[i]));
    }
    return scramble;
  }

  /// Aplica una secuencia de movimientos WCA (R/U/F, con `'` o `2`) al cubo
  /// resuelto y devuelve la coordenada `[permIndex, oriIndex]` resultante.
  ///
  /// Trabaja directamente sobre las esquinas (no usa las tablas de transición),
  /// así que sirve para verificar de extremo a extremo que un scramble alcanza
  /// el estado esperado.
  List<int> stateAfterMoves(List<String> moves) {
    var cp = <int>[0, 1, 2, 3, 4, 5, 6];
    var co = <int>[0, 0, 0, 0, 0, 0, 0];
    for (final move in moves) {
      final base = _faces.indexOf(move[0]);
      final turns = move.length == 1 ? 1 : (move[1] == '2' ? 2 : 3);
      for (int t = 0; t < turns; t++) {
        cp = _applyPerm(cp, _baseCp[base]);
        co = _applyOri(co, _baseCp[base], _baseCo[base]);
      }
    }
    return [_permToIndex(cp), _oriToIndex(co)];
  }

  /// Construye las tablas si aún no existen y devuelve cuántos de los
  /// [stateCount] estados son alcanzables. En un modelo correcto debe ser igual
  /// a [stateCount]; se usa desde los tests para verificar la cobertura total.
  int reachableStateCount() {
    _ensureTables();
    final dist = _dist!;
    var count = 0;
    for (int i = 0; i < _nStates; i++) {
      if (dist[i] != _unseen) count++;
    }
    return count;
  }

  void _ensureTables() {
    if (_ready) return;
    _buildMoveTables();
    _buildDistanceTable();
  }

  void _buildMoveTables() {
    final permMove = Int32List(_nPerm * 9);
    final oriMove = Int32List(_nOri * 9);

    for (int p = 0; p < _nPerm; p++) {
      final perm = _indexToPerm(p);
      for (int b = 0; b < 3; b++) {
        var cur = perm;
        for (int t = 1; t <= 3; t++) {
          cur = _applyPerm(cur, _baseCp[b]);
          permMove[p * 9 + b * 3 + (t - 1)] = _permToIndex(cur);
        }
      }
    }

    for (int o = 0; o < _nOri; o++) {
      final co = _indexToOri(o);
      for (int b = 0; b < 3; b++) {
        var cur = co;
        for (int t = 1; t <= 3; t++) {
          cur = _applyOri(cur, _baseCp[b], _baseCo[b]);
          oriMove[o * 9 + b * 3 + (t - 1)] = _oriToIndex(cur);
        }
      }
    }

    _permMove = permMove;
    _oriMove = oriMove;
  }

  void _buildDistanceTable() {
    final dist = Uint8List(_nStates)..fillRange(0, _nStates, _unseen);
    final permMove = _permMove!;
    final oriMove = _oriMove!;

    // BFS desde el estado resuelto (perm 0, ori 0) sobre el grafo de Cayley.
    final queue = Uint32List(_nStates);
    var head = 0;
    var tail = 0;
    dist[0] = 0;
    queue[tail++] = 0;

    while (head < tail) {
      final s = queue[head++];
      final p = s ~/ _nOri;
      final o = s % _nOri;
      final nd = dist[s] + 1;
      final permBase = p * 9;
      final oriBase = o * 9;
      for (int m = 0; m < 9; m++) {
        final ns = permMove[permBase + m] * _nOri + oriMove[oriBase + m];
        if (dist[ns] == _unseen) {
          dist[ns] = nd;
          queue[tail++] = ns;
        }
      }
    }

    _dist = dist;
  }

  /// Nombre WCA del inverso del movimiento [m] (m = base*3 + (giros-1)).
  static String _invertedName(int m) {
    final face = _faces[m ~/ 3];
    switch (m % 3) {
      case 0: // 1 giro  -> inverso 3 giros
        return "$face'";
      case 1: // 2 giros  -> su propio inverso
        return '${face}2';
      default: // 3 giros -> inverso 1 giro
        return face;
    }
  }

  static List<int> _applyPerm(List<int> cp, List<int> moveCp) {
    final r = List<int>.filled(7, 0);
    for (int i = 0; i < 7; i++) {
      r[i] = cp[moveCp[i]];
    }
    return r;
  }

  static List<int> _applyOri(List<int> co, List<int> moveCp, List<int> moveCo) {
    final r = List<int>.filled(7, 0);
    for (int i = 0; i < 7; i++) {
      r[i] = (co[moveCp[i]] + moveCo[i]) % 3;
    }
    return r;
  }

  // ---- Coordenadas de permutación (código de Lehmer sobre 7 elementos) ----

  static int _permToIndex(List<int> p) {
    var index = 0;
    for (int i = 0; i < 7; i++) {
      index *= (7 - i);
      for (int j = i + 1; j < 7; j++) {
        if (p[j] < p[i]) index++;
      }
    }
    return index;
  }

  static List<int> _indexToPerm(int index) {
    final code = List<int>.filled(7, 0);
    var idx = index;
    for (int i = 6; i >= 0; i--) {
      final radix = 7 - i;
      code[i] = idx % radix;
      idx ~/= radix;
    }
    final available = <int>[0, 1, 2, 3, 4, 5, 6];
    final p = List<int>.filled(7, 0);
    for (int i = 0; i < 7; i++) {
      p[i] = available.removeAt(code[i]);
    }
    return p;
  }

  // ---- Coordenadas de orientación (base 3 sobre las primeras 6 esquinas) ----

  static int _oriToIndex(List<int> co) {
    var index = 0;
    for (int i = 0; i < 6; i++) {
      index = index * 3 + co[i];
    }
    return index;
  }

  static List<int> _indexToOri(int index) {
    final co = List<int>.filled(7, 0);
    var idx = index;
    var sum = 0;
    for (int i = 5; i >= 0; i--) {
      co[i] = idx % 3;
      idx ~/= 3;
      sum += co[i];
    }
    // La orientación total de las esquinas es invariante (≡ 0 mod 3): la 7ª
    // esquina queda determinada por las otras seis.
    co[6] = (3 - (sum % 3)) % 3;
    return co;
  }
}
