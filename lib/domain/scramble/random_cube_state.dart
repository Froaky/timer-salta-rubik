import 'dart:math';

import 'package:cuber/cuber.dart' as cuber;

/// Construye un estado del cubo 3x3 **uniformemente aleatorio** y válido
/// (resoluble), respetando las tres restricciones de un cubo real:
///
/// 1. La suma de orientaciones de esquinas ≡ 0 (mod 3).
/// 2. La suma de orientaciones de aristas ≡ 0 (mod 2).
/// 3. La permutación de esquinas y la de aristas tienen la misma paridad.
///
/// Alimentar este estado al solver de Kociemba (`cube.solve()`) y luego
/// invertir la solución produce un scramble *random-state* con la misma
/// fortaleza que TNoodle, a diferencia de `cuber.Cube.scrambled()`, que sólo
/// aplica 20 movimientos al azar (un pseudo-estado, no uniforme).
cuber.Cube randomThreeByThreeState(Random random) {
  final cp = _randomPermutation(8, random);
  final ep = _randomPermutation(12, random);

  // Igualar la paridad de ambas permutaciones (restricción 3). Un solo
  // intercambio invierte la paridad de las aristas y mantiene la uniformidad.
  if (_permutationParity(cp) != _permutationParity(ep)) {
    final t = ep[0];
    ep[0] = ep[1];
    ep[1] = t;
  }

  // Orientación de esquinas: 7 libres, la 8ª fija la suma ≡ 0 (mod 3).
  final co = List<int>.filled(8, 0);
  var coSum = 0;
  for (var i = 0; i < 7; i++) {
    co[i] = random.nextInt(3);
    coSum += co[i];
  }
  co[7] = (3 - coSum % 3) % 3;

  // Orientación de aristas: 11 libres, la 12ª fija la suma ≡ 0 (mod 2).
  final eo = List<int>.filled(12, 0);
  var eoSum = 0;
  for (var i = 0; i < 11; i++) {
    eo[i] = random.nextInt(2);
    eoSum += eo[i];
  }
  eo[11] = eoSum & 1;

  return cuber.Cube.fromJson({'cp': cp, 'co': co, 'ep': ep, 'eo': eo});
}

List<int> _randomPermutation(int n, Random random) {
  final p = [for (var i = 0; i < n; i++) i];
  for (var i = n - 1; i > 0; i--) {
    final j = random.nextInt(i + 1);
    final t = p[i];
    p[i] = p[j];
    p[j] = t;
  }
  return p;
}

int _permutationParity(List<int> p) {
  var inversions = 0;
  for (var i = 0; i < p.length; i++) {
    for (var j = i + 1; j < p.length; j++) {
      if (p[i] > p[j]) inversions++;
    }
  }
  return inversions & 1;
}
