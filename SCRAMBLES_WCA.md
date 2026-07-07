# Scrambles estilo WCA (WCA-style)

## Resumen

Salta Rubik genera scrambles **estilo WCA** ("WCA-style"): imitan la notación,
la longitud y la estructura de los scrambles oficiales, pero **no** usan
TNoodle, el único programa de scrambles oficial de la WCA. Son aptos para
práctica y uso personal; no para competencias oficiales.

- 3x3 (y variantes OH/BF/FMC): en mobile/desktop se usa el paquete Dart
  [`cuber`](https://pub.dev/packages/cuber) (algoritmo de dos fases de
  Kociemba): se genera un estado aleatorio, se resuelve y se invierte la
  solución. En web se usa el generador aleatorio válido (el solve de Kociemba
  es síncrono y congelaría el único thread del navegador).
- Resto de los eventos: generadores propios con validación de movimientos.
- Fallback seguro: si `cuber` falla o devuelve una solución corta, se usa el
  generador aleatorio válido de 20-25 movimientos.

## Qué genera cada evento

| Evento | Longitud | Notas |
|--------|----------|-------|
| 2x2 | 9-10 | Solo R/U/F, anti-patrones (no repite cara, corta alternancias) |
| 3x3 / OH / BF / FMC | 20-25 | Kociemba invertido (mobile) o aleatorio válido (web) |
| 4x4 / 444bf | 40 | Bloque inicial tipo 3x3 (solo caras externas) y luego wides; **nunca** emite `Dw`/`Lw`/`Bw` (FIX-017) |
| 5x5 / 555bf | 60 | Outer + los seis wides de 2 capas |
| 6x6 | 80 | Outer + wides 2 capas + `3Rw`/`3Uw`/`3Fw` (sin `3Lw`/`3Dw`/`3Bw`, como TNoodle) |
| 7x7 | 100 | Igual que 6x6 |
| Pyraminx | 11 + tips | R/L/U/B con tips minúscula opcionales |
| Megaminx | 7 líneas | Formato Pochmann: `R++/R-- D++/D--` ×10 + `U`/`U'` por línea |
| Skewb | 7-9 | R/U/L/B con `'` |
| Clock | 15 | Orden fijo de pins con `y2`; `6` y `0` siempre con `+` |
| Square-1 | 12 pares | Con tracking de forma: cada `/` es físicamente ejecutable, nunca `(0,0)` |

## Reglas de validación comunes

- No repetir la misma cara base consecutivamente (`R Rw` inválido).
- No encadenar tres movimientos del mismo eje (`R L R` inválido).
- Wide moves solo en los cubos grandes que los usan oficialmente.

Cobertura de regresión en
[test/domain/usecases/generate_scramble_test.dart](test/domain/usecases/generate_scramble_test.dart).

## Comparación con TNoodle oficial

| Aspecto | TNoodle oficial | Salta Rubik (WCA-style) |
|---------|-----------------|--------------------------|
| Lenguaje | Java/Kotlin | Dart |
| Algoritmo 3x3 | Random state + Kociemba | Random state + Kociemba (`cuber`) en mobile; random-move en web |
| Otros eventos | Random state por evento | Random move con validación |
| Uso en competencia WCA | ✅ Oficial | ❌ No oficial |

⚠️ **Para competencias oficiales** solo debe usarse TNoodle descargado desde
<https://www.worldcubeassociation.org/regulations/scrambles/>.

## Referencias

- [TNoodle GitHub](https://github.com/thewca/tnoodle)
- [Cuber Package](https://pub.dev/packages/cuber)
- [WCA Scramble Regulations](https://www.worldcubeassociation.org/regulations/scrambles/)
- [Kociemba Algorithm](https://en.wikipedia.org/wiki/Optimal_solutions_for_Rubik%27s_Cube#Kociemba's_algorithm)
