import 'dart:math';

import 'package:cuber/cuber.dart' as cuber;

import '../../core/usecases/usecase.dart';
import '../entities/scramble.dart';

/// Generador de scrambles usando el paquete cuber que implementa
/// el algoritmo de Kociemba y sigue estándares WCA más robustos
class GenerateScramble implements UseCaseSync<Scramble, String> {
  @override
  Scramble call(String cubeType) {
    switch (cubeType) {
      case '3x3':
        return _generate3x3Scramble();
      case '2x2':
        return _generate2x2Scramble();
      case '4x4':
        return _generate4x4Scramble();
      case '5x5':
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
      default:
        return _generate3x3Scramble();
    }
  }

  /// Genera scramble para 3x3 usando algoritmo de Kociemba (WCA standard)
  /// Proceso: 1) Generar estado aleatorio, 2) Resolver con Kociemba, 3) Invertir solución
  Scramble _generate3x3Scramble() {
    try {
      // Generar un cubo con estado aleatorio usando cuber
      final randomCube = cuber.Cube.scrambled();
      
      // Resolver el cubo usando algoritmo de Kociemba
       final solution = randomCube.solve(maxDepth: 25, timeout: Duration(seconds: 5));
       
       if (solution != null && solution.algorithm.moves.isNotEmpty) {
         // Invertir la solución para obtener el scramble
         final scrambleMoves = _invertMoves(solution.algorithm.moves);
         final scrambleNotation = scrambleMoves.join(' ');
         
         return Scramble(
           notation: scrambleNotation,
           cubeType: '3x3',
           moves: scrambleMoves,
           generatedAt: DateTime.now(),
         );
       } else {
         // Si no se encuentra solución, usar fallback
         return _generateFallbackScramble('3x3');
       }
    } catch (e) {
      // Fallback a scramble básico si hay error
      return _generateFallbackScramble('3x3');
    }
  }

  /// Genera scramble para 2x2x2 siguiendo estándares WCA oficiales
  /// Orientación: WHITE arriba, GREEN al frente
  /// Mínimo 4 movimientos para resolver (WCA 4b3b)
  /// Notación: R, U, F (D, L, B son redundantes para 2x2x2)
  Scramble _generate2x2Scramble() {
    final random = Random();
    final faces = ['R', 'U', 'F'];
    final modifiers = ['', '\'', '2'];
    final moves = <String>[];
    
    String? lastFace;
    String? secondLastFace;
    
    // Generar entre 6-8 movimientos (estándar WCA actual)
    final moveCount = 6 + random.nextInt(3);
    
    for (int i = 0; i < moveCount; i++) {
      String face;
      
      // Evitar movimientos consecutivos en la misma cara
      do {
        face = faces[random.nextInt(faces.length)];
      } while (_isInvalidMove(face, lastFace, secondLastFace));
      
      final modifier = modifiers[random.nextInt(modifiers.length)];
      moves.add('$face$modifier');
      
      secondLastFace = lastFace;
      lastFace = face;
    }
    
    return Scramble(
      notation: moves.join(' '),
      cubeType: '2x2',
      moves: moves,
      generatedAt: DateTime.now(),
    );
  }

  /// Genera scramble para 4x4x4 siguiendo estándares WCA oficiales
  /// Notación WCA: R, U, F, L, D, B (outer) y Rw, Uw, Fw, Lw, Dw, Bw (wide de 2 capas)
  /// Mínimo 2 movimientos para resolver (WCA 4b3d)
  Scramble _generate4x4Scramble() {
    final random = Random();
    final outerFaces = ['R', 'U', 'F', 'L', 'D', 'B'];
    final wideFaces = ['Rw', 'Uw', 'Fw', 'Lw', 'Dw', 'Bw'];
    final allFaces = [...outerFaces, ...wideFaces];
    final modifiers = ['', '\'', '2'];
    final moves = <String>[];
    
    String? lastFace;
    String? secondLastFace;
    
    // WCA suele usar 40 movimientos para 4x4
    final moveCount = 40;
    
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
        invertedMove = moveStr + '\'';
      }
      
      invertedMoves.add(invertedMove);
    }
    
    return invertedMoves;
  }

  /// Genera una secuencia de movimientos válida
  List<String> _generateMoveSequence({
    required List<String> faces,
    required int length,
    bool allowTips = false,
  }) {
    final moves = <String>[];
    final modifiers = allowTips ? ['', '\''] : ['', '\'', '2'];
    String? lastFace;
    String? secondLastFace;

    for (int i = 0; i < length; i++) {
      String face;
      
      // Evitar movimientos consecutivos en la misma cara o caras opuestas
      do {
        face = faces[(DateTime.now().millisecondsSinceEpoch + i) % faces.length];
      } while (_isInvalidMove(face, lastFace, secondLastFace));

      final modifier = modifiers[(DateTime.now().microsecondsSinceEpoch + i) % modifiers.length];
      
      // Para Pyraminx, agregar ocasionalmente movimientos de tips
      if (allowTips && (DateTime.now().millisecondsSinceEpoch + i) % 4 == 0) {
        final tips = ['r', 'l', 'u', 'b'];
        final tip = tips[i % tips.length];
        final tipModifier = ['', '\''][(DateTime.now().microsecondsSinceEpoch + i) % 2];
        moves.add('$tip$tipModifier');
      } else {
        moves.add('$face$modifier');
      }

      secondLastFace = lastFace;
      lastFace = face;
    }

    return moves;
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

    // Generar entre 18-25 movimientos para 3x3x3 (estándar WCA ~20)
    final moveCount = 18 + random.nextInt(8);

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

  /// Scramble de respaldo en caso de error
  Scramble _generateFallbackScramble(String cubeType) {
    final moves = ['R', 'U', 'R\'', 'U\'', 'F', 'R', 'F\'', 'U2', 'R2', 'U\'', 'R', 'U', 'R\'', 'U\'', 'R'];
    
    return Scramble(
      notation: moves.join(' '),
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
      'R': 'L', 'L': 'R',
      'U': 'D', 'D': 'U',
      'F': 'B', 'B': 'F',
      'Rw': 'Lw', 'Lw': 'Rw',
      'Uw': 'Dw', 'Dw': 'Uw',
      'Fw': 'Bw', 'Bw': 'Fw',
    };

    if (lastFace != null && 
        secondLastFace != null && 
        oppositeFaces[face] == lastFace && 
        face == secondLastFace) {
      return true;
    }

    return false;
  }

  /// Verifica si un movimiento 4x4x4 es inválido
  bool _isInvalidMove4x4(String face, String? lastFace, String? secondLastFace) {
    if (lastFace == null) return false;
    
    // Extraer la cara base (sin w o minúscula)
    String getBaseFace(String f) {
      if (f.endsWith('w')) return f.substring(0, f.length - 1);
      return f.toUpperCase();
    }
    
    final baseFace = getBaseFace(face);
    final lastBaseFace = getBaseFace(lastFace);
    
    // No permitir movimientos consecutivos en la misma cara base
    if (baseFace == lastBaseFace) return true;
    
    // No permitir caras opuestas consecutivas
    final oppositeFaces = {
      'R': 'L', 'L': 'R',
      'U': 'D', 'D': 'U',
      'F': 'B', 'B': 'F',
    };
    
    if (oppositeFaces[baseFace] == lastBaseFace) return true;
    
    return false;
  }

  /// Genera scramble para Pyraminx siguiendo estándares WCA oficiales
  /// Orientación: YELLOW abajo, GREEN al frente
  /// Mínimo 6 movimientos para resolver (WCA 4b3f)
  /// Notación: R, L, U, B (mayúsculas = capa + tip, minúsculas = solo tip)
  Scramble _generatePyraminxScramble() {
    final random = Random();
    final faces = ['R', 'L', 'U', 'B'];
    final modifiers = ['', '\''];
    final tips = ['r', 'l', 'u', 'b'];
    final moves = <String>[];
    
    String? lastFace;
    String? secondLastFace;
    
    // Generar entre 8-12 movimientos principales para asegurar complejidad
    final mainMoves = 8 + random.nextInt(5);
    
    for (int i = 0; i < mainMoves; i++) {
      String face;
      
      // Evitar movimientos consecutivos en la misma cara
      do {
        face = faces[random.nextInt(faces.length)];
      } while (_isInvalidMove(face, lastFace, secondLastFace));
      
      final modifier = modifiers[random.nextInt(modifiers.length)];
      moves.add('$face$modifier');
      
      secondLastFace = lastFace;
      lastFace = face;
    }
    
    // Agregar movimientos de tips aleatorios (máximo uno de cada tipo)
    // Mezclar los tips para seleccionar aleatoriamente cuáles usar
    final shuffledTips = [...tips]..shuffle(random);
    
    // Seleccionar entre 0-4 tips para usar (puede ser ninguno o todos)
    final tipsToUse = shuffledTips.take(random.nextInt(5));
    
    // Agregar cada tip seleccionado con un modificador aleatorio
    for (final tip in tipsToUse) {
      final modifier = modifiers[random.nextInt(modifiers.length)];
      moves.add('$tip$modifier');
    }
    
    return Scramble(
      notation: moves.join(' '),
      cubeType: 'pyraminx',
      moves: moves,
      generatedAt: DateTime.now(),
    );
  }

  /// Genera scramble para Skewb siguiendo estándares WCA oficiales
  /// Orientación: WHITE arriba, GREEN izquierda, RED derecha
  /// Mínimo 7 movimientos para resolver (WCA 4b3c)
  /// Notación: R, U, L, B (solo estas 4 caras cubren todos los estados)
  Scramble _generateSkewbScramble() {
    final random = Random();
    final faces = ['R', 'U', 'L', 'B'];
    final modifiers = ['', '\''];
    final moves = <String>[];
    
    String? lastFace;
    String? secondLastFace;
    
    // Generar entre 7-9 movimientos según ejemplos WCA
    final moveCount = 7 + random.nextInt(3);
    
    for (int i = 0; i < moveCount; i++) {
      String face;
      
      // Evitar movimientos consecutivos en la misma cara
      do {
        face = faces[random.nextInt(faces.length)];
      } while (_isInvalidMove(face, lastFace, secondLastFace));
      
      final modifier = modifiers[random.nextInt(modifiers.length)];
      moves.add('$face$modifier');
      
      secondLastFace = lastFace;
      lastFace = face;
    }
    
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
    final allMoves = lines.join(' ').split(' ').where((move) => move.isNotEmpty).toList();
    
    return Scramble(
      notation: fullNotation,
      cubeType: 'megaminx',
      moves: allMoves,
      generatedAt: DateTime.now(),
    );
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