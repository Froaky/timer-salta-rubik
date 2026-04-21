# Salta Rubik Context

Este archivo resume lo indispensable para continuar el desarrollo de este repo sin tener que reabrir muchos archivos.

## 0. Como mantener este archivo

- Este archivo es la memoria compartida del repo para futuras IAs.
- Toda tarea no trivial deberia dejar este archivo mejor de lo que lo encontro.
- Cuando se cierre, descubra o cambie algo importante, actualizar:
  - la seccion mas relevante existente,
  - el bloque `Pendiente inmediato` si cambia la prioridad de arranque,
  - el `Context Journal` al final.
- Que vale la pena agregar:
  - invariantes del negocio,
  - archivos clave de un flujo,
  - bugs encontrados y causa real,
  - decisiones de implementacion,
  - limites conocidos,
  - validacion ya corrida,
  - proximo paso recomendado.
- Que NO vale la pena agregar:
  - logs crudos,
  - pensamiento descartado,
  - ruido temporal,
  - listas enormes de archivos irrelevantes.

## 1. Que es este repo

- App Flutter de timer para speedcubing.
- Tiene sesiones, scrambles WCA, historial de solves, estadisticas y modo competencia/versus.
- La arquitectura esta separada en `lib/core`, `lib/data`, `lib/domain` y `lib/presentation`.
- El estado de UI usa `flutter_bloc`.
- La DI se arma a mano con `get_it` en `lib/injection_container.dart`.
- Persistencia principal: `sqflite`.
- Dependencia clave de scrambles/3x3 oracle: `cuber`.

## 2. Entry points y archivos base

- App root: [lib/main.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/main.dart)
- DI: [lib/injection_container.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/injection_container.dart)
- Pantalla principal: [lib/presentation/pages/timer_page.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/presentation/pages/timer_page.dart)
- Modo competencia: [lib/presentation/pages/compete_page.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/presentation/pages/compete_page.dart)
- Tema: [lib/presentation/theme/app_theme.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/presentation/theme/app_theme.dart)
- Backlog vivo: [lib/TODO.TXT](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/TODO.TXT)

## 3. BLoCs principales

- `TimerBloc`
  - Estados/flujo del timer.
  - Semantica a preservar: `idle`, `holdPending`, `armed`, `inspection`, `running`, `stopped`.
  - Riesgo alto: cualquier cambio en press/release/start/stop.

- `SolveBloc`
  - Carga solves, agrega, actualiza, elimina, genera scrambles y refresca estadisticas.
  - Riesgo alto: mantener alineado `sessionId`, `cubeType`, scramble actual y refresh de stats.

- `SessionBloc`
  - Maneja sesiones y seleccion actual.
  - Cambiar sesion no debe romper scramble/historial/stats.

- `CompeteBloc`
  - Maneja rondas vs, lanes, marcador y scrambles de competencia.
  - Riesgo alto: start/stop por carril, empates y congelado exacto del tiempo final.

## 4. Archivos importantes por feature

### Timer normal
- Page: [timer_page.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/presentation/pages/timer_page.dart)
- Display del timer: [timer_display.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/presentation/widgets/timer/timer_display.dart)
- Scramble en texto: [scramble_display.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/presentation/widgets/scramble_display.dart)
- Selector de sesion: [session_selector.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/presentation/widgets/session_selector.dart)
- Historial/lista: [solve_list.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/presentation/widgets/solve_list.dart)

### Scramble preview visual
- Widget principal: [scramble_preview.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/presentation/widgets/scramble_preview.dart)
- Motor del cubo NxN: [cube_preview_engine.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/presentation/widgets/cube_preview_engine.dart)

### Dominio / persistencia solves
- DB local: [local_database.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/data/datasources/local_database.dart)
- Impl mobile SQLite: [local_database_sqflite.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/data/datasources/local_database_sqflite.dart)
- Impl web navegador: [local_database_browser.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/data/datasources/local_database_browser.dart)
- Datasource solves: [solve_local_datasource.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/data/datasources/solve_local_datasource.dart)
- Repo solves: [solve_repository_impl.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/data/repositories/solve_repository_impl.dart)
- Use case borrado masivo: [delete_solves_by_session.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/lib/domain/usecases/delete_solves_by_session.dart)

## 5. Comportamientos que NO se deben romper

- El timer debe iniciar al mantener presionado el tiempo requerido y soltar. No con un toque extra.
- El timer debe detenerse exactamente al toque de stop. Nada visual o asincrono debe sumar tiempo.
- Cambiar sesion o tipo de cubo debe mantener historial, estadisticas y scramble alineados.
- En competencia:
  - el scramble se oculta mientras la ronda esta activa,
  - el siguiente scramble aparece recien al cerrar la ronda,
  - el tiempo final debe congelarse antes de cualquier refresh,
  - los empates no suman punto.
- Penalidades soportadas: `none`, `plus2`, `dnf`.
- `lane`: `0` single, `1-2` competencia.
- El historial y stats deben refrescar despues de add/update/delete.

## 6. Cambios ya implementados importantes

### Backlog cerrado
- `US-001` a `US-010` estan hechos en `lib/TODO.TXT`.
- `FIX-011` a `FIX-013` estan hechos.
- `FIX-014` y `FIX-015` estan hechos.

### Lo mas relevante de esos cambios
- Competencia:
  - el scramble desaparece durante la ronda activa,
  - el siguiente scramble no aparece hasta cerrar ambos carriles,
  - el tiempo final se captura antes del refresh de scramble.
- Timer normal:
  - los handlers de press/release/cancel ahora leen el estado vivo del `TimerBloc`, no una foto vieja del `build`,
  - soltar despues de quedar `armed` arranca en el primer intento aunque el widget aun no se haya reconstruido,
  - el stop sigue usando un `stoppedAt` capturado en el toque real y la UI mantiene un latch visual para no mostrar ticks extra.
  - no conviene entrar a layout inmersivo durante `holdPending` o `armed`: si el arbol cambia mientras el dedo sigue apoyado, Flutter puede cancelar el gesto y el timer no llega a arrancar al soltar.
  - para minimizar delay de stop/start, la superficie del timer usa eventos crudos de puntero (`Listener`) en vez de `GestureDetector` tap callbacks; el recognizer de tap puede introducir latencia perceptible antes de entregar `onTapDown`.
  - el texto visible del timer ya no depende solo del `Timer.periodic` del bloc mientras corre; `TimerDisplay` usa `startTime` con un ticker local por frame para reducir el desfase visual que hacia saltar centesimas al detener.
  - si existe un latch de stop, `TimerDisplay` debe respetarlo y dejar de usar elapsed vivo aunque el bloc siga un frame en `running`; si no, el numero puede avanzar 2-3 centesimas durante el zoom out final.
  - para que no haya salto entre el numero visible al toque y el tiempo final guardado, el stop del timer normal usa el ultimo `elapsedMs` efectivamente pintado por `TimerDisplay` como override del cierre final.
- Clock:
  - en scrambles de `clock`, el valor `6` debe salir siempre como `6+`; `6-` es invalido para este generador.
- Sesiones:
  - tocar la sesion actual ya no regenera scramble.
- Historial:
  - hay borrado masivo por sesion.
- Navegacion:
  - tocar el header principal vuelve al inicio.
- Scramble preview:
  - cerrar tocando afuera,
  - back del sistema cierra el modal primero,
  - zoom adaptado para que quepa completo,
  - scramble de la home vuelve a estar arriba del timer.
- Scramble display principal:
  - ya no usa una franja fija alta en `timer_page.dart`; el card del scramble mide su alto segun el texto real y queda compacto por default.
  - `2x2` y scrambles cortos usan menos alto, mientras scrambles largos/NxN reducen tipografia y pueden crecer hasta un maximo controlado.
- Web / Railway:
  - la app ya compila a web con `flutter build web --no-pub`.
  - `LocalDatabase` quedo separado por plataforma via conditional export:
    - mobile/desktop sigue con SQLite,
    - web usa `localStorage` del navegador.
  - `firebase_core`, `firebase_auth` y `cloud_firestore` salieron del `pubspec` porque aun no habia login real y estaban rompiendo la compilacion web.
  - hay path de deploy para Railway con `Dockerfile` multi-stage y `deploy/Caddyfile` para servir `build/web` con fallback SPA.

## 7. Estado actual del motor visual del scramble

- El preview visual de cubos NxN parte de:
  - `U = blanco`
  - `D = amarillo`
  - `F = verde`
  - `B = azul`
  - `R = rojo`
  - `L = naranja`
- La secuencia se aplica de izquierda a derecha como en un cubo real.
- El motor actual fue extraido a `cube_preview_engine.dart`.
- Se corrigio la orientacion de giros y se lo comparo contra `cuber` para:
  - `U`, `R`, `F`, `D`, `L`, `B`
  - la secuencia `R U R' U'`
- Si vuelve a reportarse un mismatch visual:
  1. primero comparar el estado del engine contra `cuber`,
  2. si el engine da bien, revisar render/net/rotacion de caras en `scramble_preview.dart`,
  3. si falla en 4x4+, revisar parsing wide moves.

## 8. Pendiente inmediato

Quedan visibles estos items sin cerrar en `lib/TODO.TXT`:

- ordenado/filtro de tiempos por fecha y tiempo.
- insercion manual de tiempos.
- checklist de salida a Play Store (`PS-001` a `PS-010`).
- roadmap web/Railway (`EPIC-WEB-001` a `EPIC-WEB-004` y `WEB-US-001` a `WEB-US-014`).

## 9. Tests utiles

### Tests que conviene mirar primero
- [test/presentation/bloc/timer_bloc_test.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/test/presentation/bloc/timer_bloc_test.dart)
- [test/presentation/pages/timer_page_test.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/test/presentation/pages/timer_page_test.dart)
- [test/presentation/pages/compete_page_test.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/test/presentation/pages/compete_page_test.dart)
- [test/presentation/bloc/compete_bloc_test.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/test/presentation/bloc/compete_bloc_test.dart)
- [test/presentation/widgets/scramble_preview_test.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/test/presentation/widgets/scramble_preview_test.dart)
- [test/presentation/widgets/cube_preview_engine_test.dart](C:/Users/MateoCoca/Documents/REPOS/timer-salta-rubik/test/presentation/widgets/cube_preview_engine_test.dart)

### Tests agregados en esta etapa de trabajo
- `cube_preview_engine_test.dart`
- `session_selector_test.dart`
- `solve_list_test.dart`
- `timer_display_test.dart`
- extensiones a tests de timer page, compete page, solve bloc y compete bloc

## 10. Comandos de validacion

Usar normalmente:

```powershell
dart format lib test
flutter analyze
flutter test
```

Notas:
- `flutter test` estaba pasando completo al cierre de esta tanda.
- `flutter analyze` sigue con warnings/info viejos del repo; no todos vienen de los ultimos cambios.
- para este slice web, la validacion importante fue `flutter build web --no-pub`.

## 11. Convenciones de trabajo de este repo

- Siempre editar con cambios chicos y enfocados.
- Si se agrega una dependencia nueva, hacerlo solo si es realmente necesaria.
- No tocar archivos generados manualmente.
- Si se agrega un datasource, repository, use case o bloc nuevo, actualizar `injection_container.dart`.
- Si se cierra un item del backlog, actualizar `lib/TODO.TXT`.
- Hay un skill local en `.agents/skills/epic-story-writer` para convertir ideas de producto, bugs, feedback de testers o trabajo de release en epicas e historias de usuario bien cortadas para este repo.
- Hay skills locales para el roadmap web:
  - `.agents/skills/flutter-web-railway` para habilitar Flutter Web y deploy en Railway sin romper Android.
  - `.agents/skills/cross-platform-storage` para abstraer persistencia entre mobile y web.
  - `.agents/skills/auth-sync-readiness` para preparar login/sync futuro sin romper el modo local-first actual.
- Para web/Railway, separar claramente:
  - soporte de runtime web + deploy,
  - persistencia local compatible con navegador,
  - y sync/cuenta remota futura.
- No asumir que "subir a Railway" obliga a cambiar la UX mobile actual; Android debe conservar su vista y flujo mientras se habilita web.
- Regla explicita: cualquier ajuste de UX/layout/inputs para web o desktop debe quedar aislado y no cambiar mobile salvo pedido explicito del usuario.
- Si se trabaja en web, preservar las mismas semanticas de timer, sesiones, penalties, scramble y stats entre plataformas.
- En este entorno Windows, `dart pub get` funciona mejor que `flutter pub get` si Developer Mode no esta habilitado; `flutter pub get` puede frenarse por symlinks de plugins.

## 12. Siguiente arranque recomendado

Si retomaras sin contexto adicional, arrancar asi:

1. desplegar el estado actual en Railway usando el `Dockerfile` de raiz.
2. hacer smoke test real en browser: boot, crear sesion, agregar solve, recargar y verificar persistencia.
3. si eso queda bien, decidir que items `WEB-US-001`, `WEB-US-003` y `WEB-US-004` ya pueden marcarse como hechos.
4. despues seguir con filtro/orden del historial, insercion manual de tiempos o el proximo slice de auth/sync.

## 13. Context Journal

Usar este bloque para dejar handoff corto y acumulativo. Formato sugerido:

- `YYYY-MM-DD`
  - cambio o hallazgo durable
  - archivos tocados o relevantes
  - validacion
  - siguiente paso recomendado

Entradas actuales:

- `2026-04-15`
  - se cerro la tanda de `US-001` a `US-010` y `FIX-011` a `FIX-013`
  - se tocaron principalmente `timer_page.dart`, `compete_page.dart`, `solve_list.dart`, `session_selector.dart`, `scramble_preview.dart`, `solve_bloc.dart`, `compete_bloc.dart`, `local_database.dart`
  - `flutter test` completo pasando al cierre de esa tanda
  - siguiente paso: atacar precision de start/stop del timer normal

- `2026-04-16`
  - el motor visual del cubo `NxN` fue separado a `cube_preview_engine.dart` y corregido contra orientacion real
  - se valido contra `cuber` para `U R F D L B` y `R U R' U'`
  - archivos clave: `cube_preview_engine.dart`, `scramble_preview.dart`, `cube_preview_engine_test.dart`
  - `flutter test` completo pasando; `flutter analyze` sigue con warnings/info viejos del repo
  - siguiente paso: resolver `FIX-014` y `FIX-015` en el timer normal

- `2026-04-16`
  - se elimino un artefacto accidental en raiz llamado `CON`; era un archivo basura con codigo Dart mezclado y ademas conflictivo por ser nombre reservado de Windows
  - archivo afectado: `CON` en la raiz del repo
  - validacion: `cmd /c dir /a /x` confirma que ya no existe
  - siguiente paso: seguir con `FIX-014` y `FIX-015`

- `2026-04-16`
  - se cerraron `FIX-014` y `FIX-015` del timer normal moviendo la decision de start/stop a handlers que leen el estado vivo del `TimerBloc` y manteniendo el stop exacto con `stoppedAt`
  - archivos afectados: `lib/presentation/pages/timer_page.dart`, `test/presentation/pages/timer_page_test.dart`, `test/presentation/bloc/timer_bloc_test.dart`, `lib/TODO.TXT`
  - validacion: `flutter test` completo pasando; `flutter analyze` sigue con warnings/info preexistentes ajenos a este cambio
  - siguiente paso: seguir con filtro/orden del historial o carga manual de tiempos

- `2026-04-16`
  - se corrigio una regresion del timer normal: el layout inmersivo durante `holdPending/armed` cortaba el gesto mientras el dedo seguia apoyado y dejaba el timer clavado en rojo
  - archivos afectados: `lib/presentation/pages/timer_page.dart`, `test/presentation/pages/timer_page_test.dart`
  - validacion: `flutter test` completo pasando; `flutter analyze` sigue con warnings/info viejos del repo
  - siguiente paso: retestar manualmente start/stop del timer en dispositivo real

- `2026-04-16`
  - se redujo la latencia perceptible del stop/start del timer normal cambiando la superficie del timer de callbacks de `GestureDetector` a eventos crudos de `Listener`
  - archivos afectados: `lib/presentation/widgets/timer/timer_display.dart`, `test/presentation/widgets/timer_display_test.dart`
  - validacion: `flutter test` completo pasando; `flutter analyze` sigue con warnings/info viejos del repo
  - siguiente paso: retestar en dispositivo real si el stop ya no salta de `0.88` a `0.90`

- `2026-04-16`
  - se ajusto el render del timer en carrera para que use `startTime` con ticker local y no quede atrasado por el `Timer.periodic` del bloc durante zooms o rebuilds; eso apuntala el salto visual de 2-3 centesimas al parar
  - archivos afectados: `lib/presentation/widgets/timer/timer_display.dart`, `test/presentation/widgets/timer_display_test.dart`, `test/presentation/bloc/timer_bloc_test.dart`
  - validacion: `flutter test` completo pasando; `flutter analyze` sigue con warnings/info viejos del repo
  - siguiente paso: retestar en dispositivo real; si aun reproduce, instrumentar logs de `stoppedAt` vs valor visible en el frame previo

- `2026-04-16`
  - se corrigio una regresion del fix anterior: el ticker local del display seguia corriendo aun con latch de stop y podia sumar 2-3 centesimas visibles durante el zoom out final
  - archivos afectados: `lib/presentation/widgets/timer/timer_display.dart`, `lib/presentation/pages/timer_page.dart`, `test/presentation/widgets/timer_display_test.dart`
  - validacion: `flutter test` completo pasando; `flutter analyze` sigue con warnings/info viejos del repo
  - siguiente paso: retestar en dispositivo real; si aun reproduce, instrumentar el valor visible justo antes del stop y compararlo con `stoppedAt`

- `2026-04-16`
  - se alineo el tiempo final del timer normal con el ultimo valor visible en pantalla: `TimerDisplay` reporta el `elapsedMs` pintado y `TimerStop` puede cerrar con `elapsedMsOverride` para evitar que un cierre posterior del reloj cambie `0.15` por `0.17`
  - archivos afectados: `lib/presentation/bloc/timer/timer_event.dart`, `lib/presentation/bloc/timer/timer_bloc.dart`, `lib/presentation/widgets/timer/timer_display.dart`, `lib/presentation/pages/timer_page.dart`, `test/presentation/bloc/timer_bloc_test.dart`, `test/presentation/widgets/timer_display_test.dart`
  - validacion: `flutter test` completo pasando; `flutter analyze` sigue con warnings/info viejos del repo
  - siguiente paso: retestar en dispositivo real; si aun reproduce, instrumentar logs del valor visible reportado, latch y estado final

- `2026-04-16`
  - se corrigio el generador de scrambles de `clock` para que `6` salga siempre con signo `+`; `6-` quedo bloqueado por regla
  - archivos afectados: `lib/domain/usecases/generate_scramble.dart`, `test/domain/usecases/generate_scramble_test.dart`
  - validacion: `flutter test` completo pasando; `flutter analyze` sigue con warnings/info viejos del repo
  - siguiente paso: si aparece otro edge case de notacion en `clock`, endurecer tests por valor y signo

- `2026-04-16`
  - se hizo responsive el card del scramble en la home: se saco la altura fija grande de `timer_page.dart` y `ScrambleDisplay` ahora calcula alto y tipografia segun longitud del scramble, ancho disponible y tipo de cubo
  - archivos afectados: `lib/presentation/pages/timer_page.dart`, `lib/presentation/widgets/scramble_display.dart`, `test/presentation/pages/timer_page_test.dart`, `test/presentation/widgets/scramble_display_test.dart`
  - validacion: `flutter test` completo pasando; `flutter analyze` sigue con warnings/info viejos del repo
  - siguiente paso: si queres seguir puliendo visual, ajustar contraste/espaciado del card del scramble o sumar una transicion mas marcada entre scrambles cortos y largos

- `2026-04-16`
  - se considero al repo en estado MVP y se agrego un checklist de salida a Play Store con signing, release bundle, privacy policy, data safety, store listing y testing de release
  - archivos afectados: `lib/TODO.TXT`, `CONTEXT.md`
  - validacion: sin cambios funcionales; ultimo `flutter test` completo seguia pasando antes de este update documental
  - siguiente paso: cerrar `PS-001` a `PS-010` antes de intentar el primer upload real a Play Console

- `2026-04-21`
  - se agrego el skill local `epic-story-writer` para generar epicas, user stories, fix stories y items de release alineados con `CONTEXT.md` y `lib/TODO.TXT`
  - archivos afectados: `.agents/skills/epic-story-writer/SKILL.md`, `.agents/skills/epic-story-writer/references/story-patterns.md`, `.agents/skills/epic-story-writer/agents/openai.yaml`, `CONTEXT.md`
  - validacion: `quick_validate.py` del skill pasando
  - siguiente paso: usar `epic-story-writer` cuando aparezcan nuevos pedidos de backlog, feedback de testers o trabajo de Play Store

- `2026-04-21`
  - se definio backlog de producto para llevar la app a Railway/Web sin romper Android: primero runtime web + deploy, luego persistencia cross-platform, y mas adelante cuenta/sync para ver sesiones y tiempos en web
  - archivos afectados: `lib/TODO.TXT`, `CONTEXT.md`
  - validacion: sin cambios funcionales; backlog alineado a invariantes actuales de timer, sesiones y stats
  - siguiente paso: arrancar por `EPIC-WEB-001` y `WEB-US-001` a `WEB-US-004` antes de tocar sync o login

- `2026-04-21`
  - se agregaron skills expertos para el roadmap web: `flutter-web-railway`, `cross-platform-storage` y `auth-sync-readiness`, alineados con deploy web, persistencia cross-platform y preparacion de sync/login futuro
  - archivos afectados: `.agents/skills/flutter-web-railway/*`, `.agents/skills/cross-platform-storage/*`, `.agents/skills/auth-sync-readiness/*`, `CONTEXT.md`
  - validacion: `quick_validate.py` pasando en los tres skills
  - siguiente paso: usar `flutter-web-railway` + `implementation-planner` para arrancar `EPIC-WEB-001`

- `2026-04-21`
  - se implemento el primer slice real de `EPIC-WEB-001`: la app compila a web, la persistencia local ya esta separada por plataforma, y el repo tiene `Dockerfile` + `Caddyfile` para deploy en Railway sin cambiar la UX Android
  - archivos afectados: `pubspec.yaml`, `pubspec.lock`, `README.md`, `Dockerfile`, `.dockerignore`, `deploy/Caddyfile`, `lib/data/datasources/local_database*.dart`, archivos generados de plugins desktop, `CONTEXT.md`
  - validacion: `dart pub get`, `flutter test --no-pub`, `flutter build web --no-pub`; `flutter analyze --no-pub` sigue con warnings/info viejos del repo
  - siguiente paso: desplegar en Railway y hacer smoke test real en browser para decidir que stories web ya pueden cerrarse

- `2026-04-21`
  - se ajusto la experiencia desktop/web del timer sin tocar mobile: layout mas estandar para pantallas anchas y atajos de teclado para timer (`Space` para hold/start, cualquier tecla menos `Esc` para stop)
  - archivos afectados: `lib/presentation/pages/timer_page.dart`, `test/presentation/pages/timer_page_test.dart`, `CONTEXT.md`
  - validacion: `flutter test --no-pub test/presentation/pages/timer_page_test.dart`, `flutter test --no-pub`; `flutter analyze --no-pub` sigue con warnings/info viejos del repo
  - siguiente paso: probar en Railway que el flujo de teclado y el layout desktop se sientan bien en browser real antes de seguir con auth/sync
