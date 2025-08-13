# Implementación de Scrambles WCA con TNoodle/Cuber

## Resumen

Se ha integrado el paquete `cuber` para generar scrambles que siguen los estándares de la WCA (World Cube Association), reemplazando la implementación básica anterior.

## ¿Qué es TNoodle?

TNoodle es el programa oficial de scrambles de la WCA <mcreference link="https://github.com/thewca/tnoodle" index="3">3</mcreference>. Está escrito principalmente en Kotlin y Java, y es el único programa de scrambles oficial para competencias WCA desde enero de 2013 <mcreference link="https://github.com/thewca/tnoodle" index="3">3</mcreference>.

## Implementación en Flutter

Como TNoodle está escrito en Java/Kotlin, no se puede usar directamente en Flutter. Sin embargo, se encontró el paquete `cuber` que implementa el algoritmo de Kociemba (algoritmo de dos fases) para resolver y generar scrambles del cubo de Rubik <mcreference link="https://pub.dev/packages/cuber" index="5">5</mcreference>.

### Paquete Cuber

El paquete `cuber` es una implementación en Dart del algoritmo de dos fases de Herbert Kociemba para resolver el cubo de Rubik <mcreference link="https://github.com/tiagohm/cuber" index="2">2</mcreference>. Características principales:

- ✅ Implementación del algoritmo de Kociemba
- ✅ Generación de scrambles válidos
- ✅ Soporte para múltiples tipos de cubo
- ✅ Compatible con Flutter/Dart
- ✅ Scrambles más robustos que implementaciones básicas

## Cambios Implementados

### 1. Dependencias Actualizadas

```yaml
# pubspec.yaml
dependencies:
  # Scramble Generation (WCA Standard)
  cuber: ^0.4.0
```

### 2. Generador de Scrambles Mejorado

Se actualizó `lib/domain/usecases/generate_scramble.dart` con:

#### Características Nuevas:
- **Soporte multi-cubo**: 2x2, 3x3, 4x4, 5x5
- **Algoritmo robusto**: Usa el paquete cuber para 3x3
- **Validación mejorada**: Evita movimientos consecutivos inválidos
- **Fallback seguro**: Scramble de respaldo en caso de error
- **Longitudes apropiadas**: 
  - 2x2: 11 movimientos
  - 3x3: 25 movimientos
  - 4x4: 40 movimientos
  - 5x5: 60 movimientos

#### Movimientos Soportados:
- **Básicos**: R, L, U, D, F, B
- **Modificadores**: ninguno, ', 2
- **Wide moves (4x4/5x5)**: Rw, Lw, Uw, Dw, Fw, Bw

### 3. Validación de Movimientos

La nueva implementación incluye validación avanzada:
- No repetir la misma cara consecutivamente
- No alternar caras opuestas (R L R)
- Soporte para wide moves en cubos grandes

## Beneficios de la Nueva Implementación

1. **Estándares WCA**: Más cercano a los estándares oficiales
2. **Calidad mejorada**: Scrambles más aleatorios y válidos
3. **Escalabilidad**: Soporte para múltiples tipos de cubo
4. **Robustez**: Manejo de errores con fallbacks
5. **Mantenibilidad**: Código más limpio y documentado

## Uso en la Aplicación

La integración es transparente para el usuario:

```dart
// Generar scramble para 3x3
context.read<SolveBloc>().add(GenerateNewScramble('3x3'));

// Generar scramble para otros cubos
context.read<SolveBloc>().add(GenerateNewScramble('2x2'));
context.read<SolveBloc>().add(GenerateNewScramble('4x4'));
context.read<SolveBloc>().add(GenerateNewScramble('5x5'));
```

## Comparación con TNoodle Oficial

| Aspecto | TNoodle Oficial | Implementación Cuber |
|---------|----------------|----------------------|
| Lenguaje | Java/Kotlin | Dart |
| Algoritmo | Kociemba + otros | Kociemba |
| Plataforma | JAR/Servidor | Flutter nativo |
| Uso WCA | ✅ Oficial | ❌ No oficial |
| Calidad | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Integración | Compleja | Simple |

## Notas Importantes

⚠️ **Para competencias oficiales**: Solo se debe usar TNoodle oficial descargado desde https://www.worldcubeassociation.org/regulations/scrambles/ <mcreference link="https://github.com/thewca/tnoodle" index="3">3</mcreference>

✅ **Para práctica**: Esta implementación es excelente para entrenamiento y uso personal

## Futuras Mejoras

1. **Integración directa con TNoodle**: Explorar uso de TNoodle como servicio externo
2. **Más tipos de cubo**: Pyraminx, Megaminx, etc.
3. **Scrambles visuales**: Representación gráfica del scramble
4. **Validación WCA**: Verificar que los scrambles cumplan todos los criterios WCA

## Referencias

- [TNoodle GitHub](https://github.com/thewca/tnoodle)
- [Cuber Package](https://pub.dev/packages/cuber)
- [WCA Scramble Regulations](https://www.worldcubeassociation.org/regulations/scrambles/)
- [Kociemba Algorithm](https://en.wikipedia.org/wiki/Optimal_solutions_for_Rubik%27s_Cube#Kociemba's_algorithm)