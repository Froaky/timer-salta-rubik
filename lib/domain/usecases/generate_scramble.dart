import 'dart:math';

import 'package:cuber/cuber.dart' as cuber;

import '../../core/usecases/usecase.dart';
import '../entities/scramble.dart';
import '../puzzles/square1_simulator.dart';
import '../scramble/pyraminx_scrambler.dart';
import '../scramble/random_cube_state.dart';
import '../scramble/skewb_scrambler.dart';
import '../scramble/two_by_two_scrambler.dart';

/// Generador de scrambles usando el paquete cuber que implementa
/// el algoritmo de Kociemba y sigue estándares WCA más robustos
class GenerateScramble implements UseCaseSync<Scramble, String> {
  @override
  Scramble call(String cubeType) {
    switch (cubeType) {
      case '3x3':
      case '3x3oh':
      case '3x3bf':
      case '3x3fm':
      case '3x3mbf':
        return _generate3x3Scramble();
      case '2x2':
        return _generate2x2Scramble();
      case '4x4':
      case '444bf':
      case '4x4bf':
        return _generate4x4Scramble();
      case '5x5':
      case '555bf':
      case '5x5bf':
        return _generate5x5Scramble();
      case '6x6':
        return _generate6x6Scramble();
      case '7x7':
        return _generate7x7Scramble();
      case 'pyraminx':
        return _generatePyraminxScramble();
      case 'megaminx':
        return _generateMegaminxScramble();
      case 'skewb':
        return _generateSkewbScramble();
      case 'clock':
        return _generateClockScramble();
      case 'sq1':
      case 'square-1':
        return _generateSquare1Scramble();
      default:
        return _generate3x3Scramble();
    }
  }

  /// Genera scramble para 3x3 con calidad *random-state* equivalente a TNoodle.
  ///
  /// Proceso: 1) sortear un estado del cubo uniformemente aleatorio y válido
  /// (ver [randomThreeByThreeState]), 2) resolverlo con Kociemba, 3) invertir la
  /// solución. Reintenta con estados nuevos si el solver no converge; sólo cae
  /// al scramble de respaldo (movimientos al azar) en el caso extremo.
  Scramble _generate3x3Scramble() {
    final random = Random();
    try {
      for (var attempt = 0; attempt < 3; attempt++) {
        final randomCube = randomThreeByThreeState(random);
        final solution = randomCube.solve(
            maxDepth: 25, timeout: const Duration(seconds: 10));

        if (solution != null && solution.algorithm.moves.isNotEmpty) {
          // Invertir la solución óptima para obtener el scramble.
          final scrambleMoves = _invertMoves(solution.algorithm.moves);
          return Scramble(
            notation: scrambleMoves.join(' '),
            cubeType: '3x3',
            moves: scrambleMoves,
            generatedAt: DateTime.now(),
          );
        }
      }
      return _generateFallbackScramble('3x3');
    } catch (e) {
      return _generateFallbackScramble('3x3');
    }
  }

  /// Genera scramble para 2x2x2 con calidad equivalente a TNoodle.
  ///
  /// Usa un generador *random-state*: sortea un estado del cubo uniformemente
  /// al azar (entre los 3.674.160 posibles) y emite la inversa de su solución
  /// óptima como scramble. Solo usa las caras R, U, F (notación WCA), fijando
  /// la esquina DBL como referencia. Ver [TwoByTwoScrambler].
  Scramble _generate2x2Scramble() {
    final moves = TwoByTwoScrambler.instance.generateScramble(Random());
    return Scramble(
      notation: moves.join(' '),
      cubeType: '2x2',
      moves: moves,
      generatedAt: DateTime.now(),
    );
  }

  /// Genera scramble para 4x4x4 siguiendo el estilo de scrambles oficiales/referidos.
  /// El bloque inicial es de tipo 3x3 (solo movimientos exteriores) y luego se
  /// incorporan los wides Rw, Uw, Fw. Se evitan los wides Dw, Lw y Bw porque
  /// dejan de aparecer en los scrambles oficiales de 4x4.
  Scramble _generate4x4Scramble() {
    final random = Random();
    final outerFaces = ['R', 'U', 'F', 'L', 'D', 'B'];
    final wideFaces = ['Rw', 'Uw', 'Fw'];
    final modifiers = ['', '\'', '2'];
    final moves = <String>[];

    String? lastFace;
    String? secondLastFace;

    // WCA suele usar 40 movimientos para 4x4. Los primeros movimientos forman
    // un bloque tipo 3x3, los restantes mezclan outer + wides permitidos.
    const moveCount = 40;
    const prefix3x3Length = 8;

    for (int i = 0; i < prefix3x3Length; i++) {
      String face;
      do {
        face = outerFaces[random.nextInt(outerFaces.length)];
      } while (_isInvalidMoveNxN(face, lastFace, secondLastFace));

      final modifier = modifiers[random.nextInt(modifiers.length)];
      moves.add('$face$modifier');

      secondLastFace = lastFace;
      lastFace = face;
    }

    final mixedFaces = [...outerFaces, ...wideFaces];

    for (int i = prefix3x3Length; i < moveCount; i++) {
      String face;
      do {
        face = mixedFaces[random.nextInt(mixedFaces.length)];
      } while (_isInvalidMoveNxN(face, lastFace, secondLastFace));

      final modifier = modifiers[random.nextInt(modifiers.length)];
      moves.add('$face$modifier');

      secondLastFace = lastFace;
      lastFace = face;
    }

    return Scramble(
      notation: moves.join(' '),
      cubeType: '4x4',
      moves: moves,
      generatedAt: DateTime.now(),
    );
  }

  /// Genera scramble para 5x5x5 siguiendo estándares WCA oficiales
  /// Notación WCA: R, U, F, L, D, B (outer) y Rw, Uw, Fw, Lw, Dw, Bw (wide de 2 capas)
  /// Mínimo 2 movimientos para resolver (WCA 4b3e)
  Scramble _generate5x5Scramble() {
    final random = Random();
    final outerFaces = ['R', 'U', 'F', 'L', 'D', 'B'];
    final wideFaces = ['Rw', 'Uw', 'Fw', 'Lw', 'Dw', 'Bw'];
    final allFaces = [...outerFaces, ...wideFaces];
    final modifiers = ['', '\'', '2'];
    final moves = <String>[];

    String? lastFace;
    String? secondLastFace;

    // WCA suele usar 60 movimientos para 5x5
    final moveCount = 60;

    for (int i = 0; i < moveCount; i++) {
      String face;

      // Evitar movimientos consecutivos en la misma cara o caras opuestas
      do {
        face = allFaces[random.nextInt(allFaces.length)];
      } while (_isInvalidMoveNxN(face, lastFace, secondLastFace));

      final modifier = modifiers[random.nextInt(modifiers.length)];
      moves.add('$face$modifier');

      secondLastFace = lastFace;
      lastFace = face;
    }

    return Scramble(
      notation: moves.join(' '),
      cubeType: '5x5',
      moves: moves,
      generatedAt: DateTime.now(),
    );
  }

  /// Genera scramble para 6x6x6 siguiendo estándares WCA usuales
  /// Notación: outer (R,U,F,L,D,B), wide 2 capas (Rw,Uw,Fw,Lw,Dw,Bw) y wide 3 capas (3Rw,3Uw,3Fw,3Lw,3Dw,3Bw)
  /// Longitud típica: 80 movimientos
  Scramble _generate6x6Scramble() {
    final random = Random();
    final outerFaces = ['R', 'U', 'F', 'L', 'D', 'B'];
    final wide2Faces = ['Rw', 'Uw', 'Fw', 'Lw', 'Dw', 'Bw'];
    final wide3Faces = ['3Rw', '3Uw', '3Fw', '3Lw', '3Dw', '3Bw'];
    final allFaces = [...outerFaces, ...wide2Faces, ...wide3Faces];
    final modifiers = ['', '\'', '2'];
    final moves = <String>[];

    String? lastFace;
    String? secondLastFace;

    final moveCount = 80;

    for (int i = 0; i < moveCount; i++) {
      String face;
      do {
        face = allFaces[random.nextInt(allFaces.length)];
      } while (_isInvalidMoveNxN(face, lastFace, secondLastFace));

      final modifier = modifiers[random.nextInt(modifiers.length)];
      moves.add('$face$modifier');

      secondLastFace = lastFace;
      lastFace = face;
    }

    return Scramble(
      notation: moves.join(' '),
      cubeType: '6x6',
      moves: moves,
      generatedAt: DateTime.now(),
    );
  }

  /// Genera scramble para 7x7x7 siguiendo estándares WCA usuales
  /// Notación: outer (R,U,F,L,D,B), wide 2 capas (Rw,Uw,Fw,Lw,Dw,Bw) y wide 3 capas (3Rw,3Uw,3Fw,3Lw,3Dw,3Bw)
  /// Longitud típica: 100 movimientos
  Scramble _generate7x7Scramble() {
    final random = Random();
    final outerFaces = ['R', 'U', 'F', 'L', 'D', 'B'];
    final wide2Faces = ['Rw', 'Uw', 'Fw', 'Lw', 'Dw', 'Bw'];
    final wide3Faces = ['3Rw', '3Uw', '3Fw', '3Lw', '3Dw', '3Bw'];
    final allFaces = [...outerFaces, ...wide2Faces, ...wide3Faces];
    final modifiers = ['', '\'', '2'];
    final moves = <String>[];

    String? lastFace;
    String? secondLastFace;

    final moveCount = 100;

    for (int i = 0; i < moveCount; i++) {
      String face;
      do {
        face = allFaces[random.nextInt(allFaces.length)];
      } while (_isInvalidMoveNxN(face, lastFace, secondLastFace));

      final modifier = modifiers[random.nextInt(modifiers.length)];
      moves.add('$face$modifier');

      secondLastFace = lastFace;
      lastFace = face;
    }

    return Scramble(
      notation: moves.join(' '),
      cubeType: '7x7',
      moves: moves,
      generatedAt: DateTime.now(),
    );
  }

  /// Invierte una lista de movimientos para generar scramble desde solución
  List<String> _invertMoves(List<cuber.Move> solutionMoves) {
    final invertedMoves = <String>[];

    // Recorrer en orden inverso
    for (int i = solutionMoves.length - 1; i >= 0; i--) {
      final move = solutionMoves[i];
      final moveStr = move.toString();

      // Invertir cada movimiento
      String invertedMove;
      if (moveStr.endsWith('\'')) {
        // R' -> R
        invertedMove = moveStr.substring(0, moveStr.length - 1);
      } else if (moveStr.endsWith('2')) {
        // R2 -> R2 (los movimientos dobles son su propio inverso)
        invertedMove = moveStr;
      } else {
        // R -> R'
        invertedMove = "$moveStr'";
      }

      invertedMoves.add(invertedMove);
    }

    return invertedMoves;
  }

  /// Genera scramble para 3x3x3 siguiendo estándares WCA oficiales
  /// Orientación: WHITE arriba, GREEN al frente
  /// Mínimo 2 movimientos para resolver (WCA 4b3)
  /// Notación: R, L, U, D, F, B con modificadores '', \', 2
  String _generateRandomScrambleNotation() {
    final random = Random();
    final faces = ['R', 'L', 'U', 'D', 'F', 'B'];
    final modifiers = ['', '\'', '2'];
    final moves = <String>[];

    String? lastFace;
    String? secondLastFace;

    // Generar entre 20-25 movimientos para 3x3x3 (mínimo WCA 20)
    final moveCount = 20 + random.nextInt(6);

    for (int i = 0; i < moveCount; i++) {
      String face;

      do {
        face = faces[random.nextInt(faces.length)];
      } while (_isInvalidMove(face, lastFace, secondLastFace));

      final modifier = modifiers[random.nextInt(modifiers.length)];
      moves.add('$face$modifier');

      secondLastFace = lastFace;
      lastFace = face;
    }

    return moves.join(' ');
  }

  /// Scramble de respaldo: genera aleatoriamente 20-25 movimientos válidos
  Scramble _generateFallbackScramble(String cubeType) {
    final notation = _generateRandomScrambleNotation();
    final moves = notation.split(' ');
    return Scramble(
      notation: notation,
      cubeType: cubeType,
      moves: moves,
      generatedAt: DateTime.now(),
    );
  }

  /// Verifica si un movimiento es inválido
  bool _isInvalidMove(String face, String? lastFace, String? secondLastFace) {
    // No repetir la misma cara
    if (face == lastFace) return true;

    // No hacer caras opuestas consecutivamente (R L R, etc.)
    final oppositeFaces = {
      'R': 'L',
      'L': 'R',
      'U': 'D',
      'D': 'U',
      'F': 'B',
      'B': 'F',
      'Rw': 'Lw',
      'Lw': 'Rw',
      'Uw': 'Dw',
      'Dw': 'Uw',
      'Fw': 'Bw',
      'Bw': 'Fw',
    };

    if (lastFace != null &&
        secondLastFace != null &&
        oppositeFaces[face] == lastFace &&
        face == secondLastFace) {
      return true;
    }

    return false;
  }

  /// Genera scramble para Pyraminx con calidad equivalente a TNoodle.
  ///
  /// Usa un generador *random-state* (ver [PyraminxScrambler]): sortea el
  /// estado del cuerpo uniformemente entre los 933.120 posibles, emite la
  /// inversa de su solución óptima y agrega puntas aleatorias. Orientación
  /// WCA: amarillo abajo, verde al frente.
  Scramble _generatePyraminxScramble() {
    final moves = PyraminxScrambler.instance.generateScramble(Random());
    return Scramble(
      notation: moves.join(' '),
      cubeType: 'pyraminx',
      moves: moves,
      generatedAt: DateTime.now(),
    );
  }

  /// Genera scramble para Skewb con calidad equivalente a TNoodle.
  ///
  /// Usa un generador *random-state* (ver [SkewbScrambler]): sortea un estado
  /// uniforme entre los 3.149.280 posibles y emite la inversa de su solución
  /// óptima. Notación WCA: R, U, L, B.
  Scramble _generateSkewbScramble() {
    final moves = SkewbScrambler.instance.generateScramble(Random());
    return Scramble(
      notation: moves.join(' '),
      cubeType: 'skewb',
      moves: moves,
      generatedAt: DateTime.now(),
    );
  }

  /// Genera scramble para Megaminx siguiendo notación oficial WCA (Pochmann)
  /// Formato: 7 líneas de 10 movimientos R/D + 1 movimiento U
  /// Orientación: WHITE arriba, GREEN al frente
  /// Ejemplo: R++ D-- R++ D-- R++ D-- R++ D-- R++ D-- U
  Scramble _generateMegaminxScramble() {
    final random = Random();
    final lines = <String>[];

    // Generar 7 líneas de scramble según formato WCA oficial
    for (int line = 0; line < 7; line++) {
      final lineMoves = <String>[];

      // 10 movimientos R/D por línea (patrón alternado R-D-R-D...)
      for (int move = 0; move < 10; move++) {
        // Alternar entre R y D según posición
        final face = move % 2 == 0 ? 'R' : 'D';

        // Elegir aleatoriamente entre ++ y --
        final modifier = random.nextBool() ? '++' : '--';

        lineMoves.add('$face$modifier');
      }

      // Agregar movimiento U al final de cada línea
      final uMove = random.nextBool() ? 'U' : "U'";
      lineMoves.add(uMove);

      lines.add(lineMoves.join(' '));
    }

    final fullNotation = lines.join('\n');
    final allMoves =
        lines.join(' ').split(' ').where((move) => move.isNotEmpty).toList();

    return Scramble(
      notation: fullNotation,
      cubeType: 'megaminx',
      moves: allMoves,
      generatedAt: DateTime.now(),
    );
  }

  /// Genera scramble para Clock (simplificado)
  Scramble _generateClockScramble() {
    final random = Random();
    const firstPhasePins = ['UR', 'DR', 'DL', 'UL', 'U', 'R', 'D', 'L', 'ALL'];
    const secondPhasePins = ['U', 'R', 'D', 'L', 'ALL'];
    final moves = <String>[
      ...firstPhasePins.map((pin) => _generateClockTurn(pin, random)),
      'y2',
      ...secondPhasePins.map((pin) => _generateClockTurn(pin, random)),
    ];
    final notation = moves.join(' ');

    return Scramble(
      notation: notation,
      cubeType: 'clock',
      moves: moves,
      generatedAt: DateTime.now(),
    );
  }

  String _generateClockTurn(String pin, Random random) {
    final value = random.nextInt(7);
    final sign = value == 6 ? '+' : (random.nextBool() ? '+' : '-');
    return '$pin$value$sign';
  }

  /// Genera scramble para Square-1 con movimientos ejecutables en un cubo
  /// real: cada par `(top,bottom)` se elige de modo que el slice (`/`) que lo
  /// sigue no quede bloqueado por una esquina en ninguna de las dos capas.
  ///
  /// Simula el estado con [Square1Cubie] (mismo modelo que usa el preview),
  /// evita el par nulo `(0,0)` y muestra los giros en el rango estándar
  /// `-5..6`.
  Scramble _generateSquare1Scramble() {
    final random = Random();
    final cubie = Square1Cubie();
    final moves = <String>[];
    const pairCount = 13;

    for (int i = 0; i < pairCount; i++) {
      final legalTops = _legalSquare1Turns(cubie, top: true);
      final legalBottoms = _legalSquare1Turns(cubie, top: false);

      int top;
      int bottom;
      do {
        top = legalTops[random.nextInt(legalTops.length)];
        bottom = legalBottoms[random.nextInt(legalBottoms.length)];
      } while (top == 0 && bottom == 0);

      if (top != 0) {
        cubie.doMove(top);
      }
      if (bottom != 0) {
        cubie.doMove(-bottom);
      }
      final isLast = i == pairCount - 1;
      if (!isLast) {
        cubie.doMove(0);
      }

      final displayTop = top > 6 ? top - 12 : top;
      final displayBottom = bottom > 6 ? bottom - 12 : bottom;
      moves.add('($displayTop,$displayBottom)');
    }

    return Scramble(
      notation: moves.join(' / '),
      cubeType: 'sq1',
      moves: moves,
      generatedAt: DateTime.now(),
    );
  }

  /// Giros (0..11) de la capa pedida que dejan esa capa lista para el slice.
  ///
  /// Siempre hay al menos uno: en cualquier forma de capa existen dos cortes
  /// enfrentados, así que alguna rotación alinea el plano del slice.
  List<int> _legalSquare1Turns(Square1Cubie cubie, {required bool top}) {
    final legal = <int>[];
    for (int amount = 0; amount < 12; amount++) {
      final probe = cubie.clone();
      if (amount != 0) {
        probe.doMove(top ? amount : -amount);
      }
      if (top ? probe.topSliceable : probe.bottomSliceable) {
        legal.add(amount);
      }
    }
    return legal;
  }
}

/// Verifica si un movimiento NxN es inválido (misma base o cara opuesta consecutiva)
bool _isInvalidMoveNxN(String face, String? lastFace, String? secondLastFace) {
  if (lastFace == null) return false;

  // Extraer cara base: una de R, L, U, D, F, B
  String getBaseFace(String f) {
    final upper = f.toUpperCase();
    final match = RegExp(r'[RLUDFB]').firstMatch(upper);
    return match?.group(0) ?? upper;
  }

  String axisOf(String f) {
    final b = getBaseFace(f);
    if (b == 'R' || b == 'L') return 'X';
    if (b == 'U' || b == 'D') return 'Y';
    return 'Z'; // F o B
  }

  final baseFace = getBaseFace(face);
  final lastBaseFace = getBaseFace(lastFace);

  // 1) No permitir movimientos consecutivos en la misma cara base (R seguido de Rw/3Rw, etc.)
  if (baseFace == lastBaseFace) return true;

  // 2) Evitar tres movimientos consecutivos sobre el mismo eje (p.ej., R L R / U D U)
  if (secondLastFace != null) {
    final axis = axisOf(face);
    final lastAxis = axisOf(lastFace);
    final secondAxis = axisOf(secondLastFace);
    if (axis == lastAxis && lastAxis == secondAxis) return true;
  }

  return false;
}
