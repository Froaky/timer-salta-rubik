# GUÍA DE TRASPASO — Salta Rubik (de 0 a 100)

> Escrita el **2026-10-06** para retomar el proyecto desde **otra cuenta de Claude** (o desde cero, sin memoria).
> Todo lo que dice este archivo fue **verificado en vivo ese día** (git, GitHub, Railway, toolchain, tests), salvo donde se aclara "no verificado".
> No contiene secretos (contraseñas, tokens, client secrets). Donde hace falta uno, se dice **dónde está guardado**.

---

## ÍNDICE

0. [Lo urgente: hacé esto ANTES de perder acceso](#0-lo-urgente-hacé-esto-antes-de-perder-acceso)
1. [Qué es el proyecto](#1-qué-es-el-proyecto)
2. [Mapa de cuentas y accesos (quién es dueño de qué)](#2-mapa-de-cuentas-y-accesos)
3. [Qué se pierde con la cuenta de Claude y qué no](#3-qué-se-pierde-con-la-cuenta-de-claude-y-qué-no)
4. [El código: repo, ramas, stashes, trabajo sin commitear](#4-el-código-repo-ramas-stashes-trabajo-sin-commitear)
5. [Entorno de la máquina (toolchain) y cómo reconstruirlo](#5-entorno-de-la-máquina-y-cómo-reconstruirlo)
6. [Comandos del día a día](#6-comandos-del-día-a-día)
7. [Arquitectura de la app Flutter](#7-arquitectura-de-la-app-flutter)
8. [Reglas de dominio que NO se pueden romper](#8-reglas-de-dominio-que-no-se-pueden-romper)
9. [Scrambles y preview visual](#9-scrambles-y-preview-visual)
10. [Web (Flutter Web)](#10-web-flutter-web)
11. [Backend (API propia)](#11-backend-api-propia)
12. [Login con WCA (flujo completo)](#12-login-con-wca-flujo-completo)
13. [Deploy en Railway (producción)](#13-deploy-en-railway-producción)
14. [Android / Play Store](#14-android--play-store)
15. [Historia: qué hicimos (cronología)](#15-historia-qué-hicimos)
16. [Qué vamos a seguir haciendo (backlog priorizado)](#16-qué-vamos-a-seguir-haciendo)
17. [Archivos de documentación y de IA dentro del repo](#17-archivos-de-documentación-y-de-ia-del-repo)
18. [Cómo arrancar con la cuenta nueva de Claude, paso a paso](#18-cómo-arrancar-con-la-cuenta-nueva-de-claude)
19. [Trampas conocidas (gotchas)](#19-trampas-conocidas)
20. [Glosario](#20-glosario)
21. [Checklist final](#21-checklist-final)

---

## 0. Lo urgente: hacé esto ANTES de perder acceso

Hay cosas que **solo existen en esta máquina** y se pierden si perdés la PC (no solo la cuenta de Claude):

| Qué | Dónde está | Riesgo | Qué hacer |
|---|---|---|---|
| **Trabajo sin commitear** (persistencia de ajustes del timer, pantalla de ajustes rediseñada, splash web, etc. — ver §4.4) | Working tree de `master` en esta PC | **Alto**: no está en GitHub | Commit en una rama y push (comandos abajo) |
| `.codex/agents/*.toml`, `.claude/launch.json`, `tool/serve_web.dart` | Sin trackear en el repo | Medio | Entran en el mismo commit |
| Este archivo `GUIA_TRASPASO.md` | Raíz del repo, sin trackear | Alto | Commitealo también, o mandátelo por mail / guardalo en Drive |
| APKs de beta para testers | `build/app/outputs/flutter-apk/` (`Saltaimer_beta0.8.0.apk`, `beta_ya_no_se_que_version.apk`) | Bajo (se regeneran) | Opcional: copiarlos a Drive |
| Memoria de Claude del proyecto | `C:\Users\MateoCoca\.claude\projects\C--Users-MateoCoca-Documents-REPOS-timer-salta-rubik\memory\` | Bajo: su contenido está copiado en §19 | Nada |
| Stashes de git (`stash@{0}`, `stash@{1}`) | `.git` local | Ninguno: están obsoletos (ver §4.3) | Nada |

**Comandos para salvar el trabajo** (desde la carpeta del repo). Ojo: **no lo pushees directo a `master`**, porque cada push a `master` redeploya producción en Railway automáticamente (§13.3).

```bash
git switch -c wip/settings-persistencia-y-ui-web
```

```bash
git add lib/ test/ web/index.html tool/ .codex/ .claude/launch.json .claude/settings.local.json CONTEXT.md GUIA_TRASPASO.md
```

```bash
git commit -m "WIP: persistencia de ajustes del timer, ajustes rediseñados, splash web, guia de traspaso"
```

```bash
git push -u origin wip/settings-persistencia-y-ui-web
```

> El repo es **PÚBLICO** en GitHub. Este archivo no tiene secretos, pero sí nombres de cuentas, emails personales (que ya aparecen en los commits) e IDs de Railway. Si no querés que esté público, en vez de commitearlo guardalo fuera del repo (Drive / mail a vos mismo).

Ese WIP ya está validado hoy: `flutter analyze` → **0 issues**, `flutter test` → **201/201 pasando**.

---

## 1. Qué es el proyecto

**Salta Rubik** es un **timer de speedcubing** (cronómetro para resolver cubos Rubik y otros puzzles) hecho en **Flutter**, por **Froaky** (Mateo Coca). Pensado primero para **Android (mobile-first)**, también corre en **web** (deployado en Railway) y tiene un **backend propio** para login/sync futuro.

Funcionalidades que **ya existen y funcionan**:

- **Timer** con la mecánica de los timers de speedcubing: mantener presionado → se pone verde → soltar arranca; tocar detiene. Estados: `idle`, `holdPending`, `armed`, `inspection`, `running`, `stopped`.
- **Inspección WCA** opcional (15 s; pasado 15 s → +2; pasado 17 s → DNF).
- **Inicio rápido** (tap-to-start, sin mantener), **ocultar timer** (muestra "RESOLUCIÓN"), **modo competir** (bloquea historial/stats durante un solve).
- **Sesiones** por categoría (3x3, 2x2, 4x4…7x7, OH, BLD, FMC, MBLD, Pyraminx, Megaminx, Skewb, Clock, Square-1). Hay sesión por defecto, se puede renombrar, crear, borrar.
- **Scrambles "estilo WCA"** por categoría (no oficiales; TNoodle no está integrado). Random-state para 3x3/2x2/Pyraminx/Skewb.
- **Preview visual del scramble** (imagen del puzzle mezclado) para todas las categorías.
- **Historial de solves** con penalidades (`+2`, `DNF`), orden por tiempo/fecha, borrado individual y masivo, **alta manual de tiempos**.
- **Estadísticas**: PB, mo3, ao5, ao12, ao25, ao100, ao200, ao500, ao1000 + mejores históricos.
- **Modo competencia / versus**: dos carriles (dos jugadores) en la misma pantalla, marcador, empates, stats sutiles por carril, resultados agrupados por scramble.
- **Web**: corre en navegador, guarda en `localStorage`, atajos de teclado (Espacio para hold/start, cualquier tecla para frenar).
- **Login opcional con WCA** (World Cube Association) **en web**, vía backend propio. En mobile todavía no (faltan deep links).

URLs de producción (verificadas 2026-10-06, responden OK):

- App web: **https://timer-salta-rubik-production.up.railway.app**
- API: **https://timer-api-production.up.railway.app** (`/health` → `{"ok":true,"database":"reachable"}`)

---

## 2. Mapa de cuentas y accesos

### 2.1 GitHub (código)

- **Repo**: https://github.com/Froaky/timer-salta-rubik — **público**, rama por defecto `master`.
- **Cuenta dueña**: `Froaky` (cuenta personal; email `mateococa.job@gmail.com`).
- **Clon local**: `C:\Users\MateoCoca\Documents\REPOS\timer-salta-rubik`
- **Remote**: `origin = https://github.com/Froaky/timer-salta-rubik.git` (HTTPS).
- **GitHub CLI (`gh`)**: v2.93.0 en `C:\Program Files\GitHub CLI\gh.exe`. Logueado como `Froaky` con token guardado en el **keyring de Windows** (Credential Manager). Scopes: `gist`, `read:org`, `repo`, `workflow`. Protocolo git: https.
  - En una PC nueva: `gh auth login` → GitHub.com → HTTPS → login con navegador. Después `gh auth setup-git`.
- **Identidad git global** en esta PC: `user.name=Froaky`, `user.email=mateococa.job@gmail.com`.
  - Historial: 35 commits como `Froaky`, 8 como "Mateo Coca | Advanced Junior Fullstack Develope" (mismo gmail), 3 con el **email corporativo de BMI** (commits viejos). Para lo que viene, usá siempre el gmail.
- **No hay GitHub Actions / CI** en el repo (no existe `.github/`). La validación es local + el build de Railway.

### 2.2 Railway (hosting: web + API + base de datos)

- **Cuenta**: "Mateo Coca", login con **`mateococa.job@gmail.com`** (personal, no depende de Claude).
- **Workspace**: "Mateo Coca's Projects".
- **Proyecto**: **`TIMER SALTA`** — id `f096d6e5-258c-4ff6-9121-27e1d6742539`, creado 2026-04-21.
- **Entorno**: `production` — id `4ed12c62-1f57-44d2-99c3-16f384b7988c` (es el único).
- 3 servicios (detalle en §13): `timer-salta-rubik` (web), `timer-api` (backend), `Postgres`.
- **Railway CLI** v5.43.4 en `C:\Users\MateoCoca\AppData\Local\Programs\railway\railway.exe`, logueado. La carpeta del repo **no está linkeada** (`railway status` dice "No linked project"); para linkear: `railway link` → elegir workspace "Mateo Coca's Projects" → proyecto "TIMER SALTA" → env "production".
- En la misma cuenta hay otros proyectos **que NO son de este repo**: Rancho quilla, Kinnikuapp, obra staff, Gerayse (workspace "Mateo Coca's Projects") y wholesome-essence (workspace "My Projects"). No tocarlos.
- Dashboard: https://railway.com/dashboard

### 2.3 WCA (World Cube Association) — OAuth

- Hay una **aplicación OAuth registrada en la WCA** que usa el backend para "Continuar con WCA".
- Se administra en https://www.worldcubeassociation.org/oauth/applications **logueado con la cuenta WCA que la creó** (presumiblemente tu cuenta WCA personal; **no verificado desde acá** — revisalo).
- Sus credenciales (`WCA_OAUTH_CLIENT_ID`, `WCA_OAUTH_CLIENT_SECRET`) están **solo en Railway** → servicio `timer-api` → Variables.
- El **Redirect URI** registrado en WCA tiene que coincidir con `WCA_OAUTH_REDIRECT_URI` del backend: `https://timer-api-production.up.railway.app/api/v1/auth/wca/callback`.
- Scope pedido: `public`.
- Estado hoy: `GET /api/v1/auth/providers` devuelve `wca` con `configured: true`.

### 2.4 Otras cuentas / servicios

- **Firebase**: **NO se usa**. Estuvo en `pubspec.yaml` (`firebase_core`, `firebase_auth`, `cloud_firestore`) y se sacó en abril 2026 porque rompía el build web. Quedan carpetas viejas en `build/` (basura de compilación). `AGENTS.md` todavía dice que Firebase está en el pubspec: **está desactualizado**.
- **Google Play Console**: **no hay cuenta de developer ni app creada todavía**. Es parte del checklist pendiente (§14).
- **Codex (OpenAI)**: también se usó en este repo (hay `AGENTS.md`, `.agents/skills`, `.codex/agents`). Config global en `C:\Users\MateoCoca\.codex\`. Independiente de Claude.
- **Gemini**: hay un `GEMINI.md` con instrucciones genéricas; poco relevante.

### 2.5 Dónde están los secretos (sin copiarlos acá)

| Secreto | Dónde vive |
|---|---|
| `AUTH_JWT_SECRET` (firma los tokens de Salta Rubik) | Railway → `timer-api` → Variables |
| `WCA_OAUTH_CLIENT_ID` / `WCA_OAUTH_CLIENT_SECRET` | Railway → `timer-api` → Variables (y la app en WCA) |
| `DATABASE_URL` y credenciales de Postgres | Railway → `Postgres` → Variables (el `timer-api` la referencia) |
| Token de GitHub | Keyring de Windows (lo maneja `gh`) |
| Sesión de Railway CLI | `C:\Users\MateoCoca\.railway\config.json` |
| Keystore de Android para Play | **No existe todavía** (el release se firma con la key de debug) |

`backend/.env` **no existe** en esta PC (solo `.env.example`), y está en `.gitignore`.

---

## 3. Qué se pierde con la cuenta de Claude y qué no

**NO depende de Claude (sigue igual):** el repo y su historial en GitHub, Railway (web/API/DB en producción), la app OAuth de WCA, el toolchain instalado en la PC, los archivos de IA versionados en el repo (`AGENTS.md`, `CONTEXT.md`, `.claude/agents/`, `.agents/skills/`).

**Sí se pierde (o queda atado a la cuenta vieja):**

- Las conversaciones/sesiones de Claude (el "contexto" de lo charlado). Lo importante de esas charlas está volcado en `CONTEXT.md` (journal) y en este archivo.
- Artifacts / cosas publicadas en claude.ai con esa cuenta (para este proyecto no había nada crítico).
- Conectores/MCP configurados en la cuenta (por ejemplo el **MCP de Railway** que se usó para consultar el proyecto). En la cuenta nueva hay que volver a conectarlo si lo querés usar (§18).

**Depende de la PC (no de la cuenta):** la carpeta `C:\Users\MateoCoca\.claude\` (settings globales, memoria por proyecto, historial local). Si seguís en la **misma PC** con otra cuenta de Claude Code, esa carpeta sigue ahí y la memoria del proyecto se vuelve a cargar sola. Si cambiás de PC, se pierde (su contenido útil está en §19).

---

## 4. El código: repo, ramas, stashes, trabajo sin commitear

### 4.1 Estado de `master`

- `HEAD` = `80b33f8` — "Production pass pre-release: timer, compete, scrambles, web y seguridad" — 2026-07-07 16:53 (-03).
- `master` local está **al día con `origin/master`** (nada para pullear ni pushear, salvo el WIP).
- Ese commit es exactamente lo que está **deployado hoy** en Railway (web y API).

### 4.2 Ramas remotas (todas en `origin`)

| Rama | Último commit | ¿Está en master? | Qué hacer |
|---|---|---|---|
| `master` | 2026-07-07 `80b33f8` | — | Rama principal y de deploy |
| `random-state-scrambles` | 2026-07-05 `b4df6ec` | Sí, mergeada | Se puede borrar |
| `issues-de-los-testers` | 2025-11-12 `8cd4ac7` | Sí, mergeada | Se puede borrar |
| `local-competition` | 2025-10-31 `c0e4e13` | Sí, mergeada | Se puede borrar |
| `fixes-varios` | 2025-10-29 `0fbe23d` | Sí, mergeada | Se puede borrar |
| `posible-new-ui` | 2026-01-06 `bb68bf1` "cambios en la ui" | **No**: 1 commit propio, 34 commits atrás de master, toca 17 archivos (solve_list, statistics_panel, timer_actions, timer_display…) | Experimento de UI abandonado. Mergearlo hoy daría muchos conflictos. Mirarlo solo como referencia visual o borrarlo |

### 4.3 Stashes locales

- `stash@{0}` "prod-pass-2026-07-07" (2026-07-07 16:12): respaldo de la pasada de producción **antes** del merge. **Ya está incorporado en `80b33f8`** (verificado: archivos clave idénticos). Se puede descartar.
- `stash@{1}` "WIP on master: a3ef503" (2026-07-07 10:07): cambio viejo en `scramble_preview.dart` que quedó **obsoleto** por la reescritura del preview. Se puede descartar.

### 4.4 Trabajo SIN COMMITEAR (lo último que se hizo, ~2026-07-10)

Está en el working tree de `master`. **Validado hoy: analyze 0 issues, 201/201 tests OK.** No está deployado.

**A) Persistencia de los ajustes del timer** (antes se perdían al reiniciar la app o recargar la web):

- Nuevos archivos:
  - `lib/data/datasources/timer_settings_data.dart` — value object `TimerSettingsData` (`inspectionEnabled`, `hideTimerEnabled`, `competeMode`, `tapToStartEnabled`) + `defaults` (todo `false`).
  - `lib/data/datasources/settings_local_datasource.dart` — **export condicional** por plataforma:
    - `settings_local_datasource_web.dart` → `window.localStorage` (dart:html)
    - `settings_local_datasource_io.dart` → `SharedPreferences` (Android/desktop)
    - `settings_local_datasource_stub.dart` → en memoria (plataformas raras)
  - Claves usadas: `salta_rubik.settings.inspection_enabled`, `salta_rubik.settings.hide_timer_enabled`, `salta_rubik.settings.compete_mode`, `salta_rubik.settings.tap_to_start_enabled`.
- `lib/presentation/bloc/timer/timer_event.dart`: nuevo evento `TimerLoadSettings`.
- `lib/presentation/bloc/timer/timer_bloc.dart`: recibe `SettingsLocalDataSource?` opcional; si está, dispara `TimerLoadSettings` al construirse; cada toggle guarda (fire-and-forget con `unawaited`). Si el storage falla, se quedan los defaults sin romper.
- `lib/injection_container.dart`: registra `SettingsLocalDataSource` y crea `TimerBloc(settingsDataSource: sl())`.
- `test/presentation/bloc/timer_bloc_test.dart`: 2 tests nuevos con un fake en memoria ("restores persisted settings on construction" y "persists feature flags to the store when toggled").
- **Por qué no SharedPreferences en web**: se verificó el 2026-07-10 que en el build web de esta app `SharedPreferences` **no persiste** (no tira error, pero al recargar se pierde). Ver §19.

**B) UI más prolija en pantallas anchas (web/desktop) sin cambiar mobile**:

- Nuevo `lib/presentation/widgets/responsive_centered.dart`: limita el ancho y centra (en celular no hace nada porque la pantalla es más angosta que el máximo).
- `solve_list.dart` y `statistics_panel.dart`: envueltos en `ResponsiveCentered(maxWidth: 760)`.
- `settings_page.dart`: **rediseño** con secciones ("Cronómetro": Inspección, Inicio rápido, Ocultar timer; "Competencia": Modo competir), tarjetas con ícono, texto "Se guardan automáticamente en este dispositivo", `maxWidth: 620`.

**C) Web `web/index.html`**: `lang="es"`, meta viewport, `theme-color #020617`, status bar `black-translucent`, y un **splash de carga** con la marca "Salta Rubik" + spinner que se quita al evento `flutter-first-frame` (con fallback a 8 s), para no mostrar pantalla blanca al cargar.

**D) Tooling / config (sin trackear o modificados)**:

- `tool/serve_web.dart`: mini servidor estático (Dart) para servir `build/web` en `localhost` con fallback SPA. Se usa porque `flutter run -d web-server` en debug necesita la extensión Dart Debug del navegador.
- `.claude/launch.json`: configuraciones de preview para Claude Code: `web` (flutter run web-server puerto 8080) y `web-release` (`dart tool/serve_web.dart 8090`). Usan rutas absolutas `C:\nose\flutter\bin\...`.
- `.claude/settings.local.json`: más permisos permitidos para Claude Code (no afecta la app).
- `.codex/agents/*.toml`: los mismos 14 subagentes de `.claude/agents` pero en formato Codex.

**Pendiente de este WIP**: commitearlo (§0), probarlo en un celular real (que los ajustes persistan tras cerrar la app) y en web (tras recargar), y recién ahí mergear a `master` (= deploy). La entrada de journal en `CONTEXT.md` ya quedó escrita (2026-10-06).

### 4.5 Basura / cosas raras en la raíz

- `negros/` — carpeta **vacía** sin sentido. Se puede borrar.
- `test_output.txt` — log viejo de tests (mayo 2026, en UTF-16) **trackeado en git**. Se puede borrar del repo.
- `build/` — salida de compilación (ignorada por git).
- `.idea/`, `salta_rubik.iml` — config de IntelliJ/Android Studio (ignorados).
- `.dart_tool/`, `.flutter-plugins*` — generados (ignorados).

---

## 5. Entorno de la máquina y cómo reconstruirlo

### 5.1 Lo que hay hoy en esta PC (Windows 11 Pro)

| Herramienta | Versión | Ubicación | En el PATH |
|---|---|---|---|
| **Flutter** | **3.29.3 stable** (rev `ea121f8859`, Dart 3.7.2) | `C:\nose\flutter` | **NO** → usar `C:\nose\flutter\bin\flutter.bat` |
| Android SDK | platforms 34 y 35, build-tools 34.0.0 y 35.0.0, NDK, CMake, cmdline-tools | `C:\nose\android-sdk` | — (configurado con `flutter config --android-sdk`) |
| JDK 17 | 17.0.19+10 | `C:\nose\jdk-17.0.19+10` | NO |
| Node.js | v24.19.0 (winget) | `...\WinGet\Packages\OpenJS.NodeJS.LTS...\node-v24.19.0-win-x64` | Sí |
| Git for Windows | — | `C:\Program Files\Git` | Sí |
| GitHub CLI | 2.93.0 | `C:\Program Files\GitHub CLI` | Sí |
| Railway CLI | 5.43.4 | `C:\Users\MateoCoca\AppData\Local\Programs\railway` | Sí |

Notas:
- La carpeta se llama literalmente `C:\nose` ("no sé"). `android/local.properties` apunta ahí (`sdk.dir=C:/nose/android-sdk`, `flutter.sdk=C:\\nose\\flutter`). `local.properties` está ignorado por git.
- `CONTEXT.md` §12 menciona `E:\Android\Sdk` y `E:\Java\jdk-17`: **desactualizado**, el disco E: ya no existe en esta PC.
- `CONTEXT.md` dice "en esta máquina no hay Node.js": **desactualizado**, hoy sí hay (v24).
- La versión de Flutter está **fijada en 3.29.3** a propósito: es la de `.metadata` y la del `Dockerfile` (`ghcr.io/cirruslabs/flutter:3.29.3`). Flutter avisa que hay versión nueva: **no actualizar** sin actualizar también el Dockerfile y re-correr todo.
- El build Android requiere NDK `27.0.12077973` (en `android/app/build.gradle.kts`).

### 5.2 Reconstruir en una PC nueva (de cero)

1. Instalar **Git for Windows** y **GitHub CLI** (`winget install GitHub.cli`). `gh auth login` con la cuenta `Froaky`.
2. Clonar:
   ```bash
   git clone https://github.com/Froaky/timer-salta-rubik.git
   ```
3. Descargar **Flutter 3.29.3 stable** (zip de Windows: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.29.3-stable.zip), descomprimir (por ejemplo en `C:\nose\flutter` para que coincidan las rutas de `.claude/launch.json`) y agregar `...\flutter\bin` al PATH.
4. Para Android: instalar Android SDK (o Android Studio) con platform 35, build-tools 35, NDK 27.0.12077973, y JDK 17. Luego:
   ```bash
   flutter config --android-sdk C:\nose\android-sdk
   ```
   ```bash
   flutter doctor -v
   ```
5. Dependencias Dart (en Windows sin "Modo desarrollador", `dart pub get` anda mejor que `flutter pub get`, que puede trabarse por symlinks de plugins):
   ```bash
   dart pub get
   ```
6. Para el backend: Node 20+ (`winget install OpenJS.NodeJS.LTS`), y dentro de `backend/`: `npm install`.
7. Railway CLI (opcional): `npm i -g @railway/cli` o el instalador; `railway login`.

---

## 6. Comandos del día a día

En esta PC Flutter no está en el PATH: reemplazá `flutter` por `C:\nose\flutter\bin\flutter.bat` y `dart` por `C:\nose\flutter\bin\dart.bat`, o agregá `C:\nose\flutter\bin` al PATH.

Validación (obligatoria después de tocar código, según `AGENTS.md`):

```bash
dart format lib test
```

```bash
flutter analyze --no-pub
```

```bash
flutter test --no-pub
```

Estado de referencia hoy: **analyze 0 issues · 201 tests pasando** (con el WIP). En `master` sin el WIP: 199.

Correr la app:

```bash
flutter run -d chrome
```

```bash
flutter run -d web-server --web-port 8080
```

Build web release y servirlo localmente:

```bash
flutter build web --release --no-pub
```

```bash
dart tool/serve_web.dart 8090
```

Build web apuntando a otra API (por defecto usa la de Railway):

```bash
flutter build web --release --dart-define=SALTA_API_BASE_URL=http://localhost:8081
```

APK para testers (sale en `build/app/outputs/flutter-apk/app-release.apk`; hoy se firma con key de debug):

```bash
flutter build apk --release
```

Backend local (dentro de `backend/`, necesita un Postgres y un `.env` copiado de `.env.example`):

```bash
npm install
```

```bash
npm run prisma:generate
```

```bash
npm run prisma:migrate:deploy
```

```bash
npm run dev
```

(Escucha en `http://localhost:8081`.)

---

## 7. Arquitectura de la app Flutter

### 7.1 Stack

- Flutter 3.29.3 / Dart 3.7.2, `sdk: '>=3.0.0 <4.0.0'`.
- Estado: **`flutter_bloc`** (`*Bloc` / `*Event` / `*State`, estados inmutables con `copyWith`, `equatable`).
- Inyección de dependencias: **`get_it`**, armada a mano en `lib/injection_container.dart` (no hay generadores; `injectable` se sacó).
- Persistencia local-first: **`sqflite`** en mobile/desktop, **`localStorage`** en web.
- Otras deps: `vibration`, `wakelock_plus` (pantalla encendida durante inspección/solve), `cuber` (Kociemba para 3x3), `flutter_svg`, `http`, `shared_preferences`, `url_launcher`, `cupertino_icons`, `flutter_web_plugins`.
- Dev: `flutter_test`, `flutter_lints` 5, `bloc_test`, `mocktail`, `flutter_launcher_icons`.
- `pubspec.yaml`: `name: salta_rubik`, `version: 1.0.0+1`, `publish_to: none`. Assets: `assets/images/`, `assets/icons/` (incluye `app_icon.png`, `wca_logo.svg`) y `assets/icons/categories/` (íconos por categoría: 222, 333, 333bf, 333fm, 333mbf, 333oh, 444, 444bf, 555, 555bf, 666, 777, clock, minx, pyram, skewb, sq1).

### 7.2 Capas (`lib/`)

```
lib/
  main.dart                  ← arranque, rutas, MultiBlocProvider
  injection_container.dart   ← get_it: datasources → repos → use cases → blocs
  TODO.TXT                   ← BACKLOG VIVO del producto
  core/
    auth/auth_callback_parser.dart
    config/app_config.dart   ← SALTA_API_BASE_URL (default API de Railway), callbacks
    constants/timer_thresholds.dart  ← hold: amarillo 150 ms, verde 300 ms
    navigation/web_redirect*.dart    ← redirección en la misma pestaña (web) + stub
    usecases/usecase.dart
  data/
    datasources/  local_database*.dart (export condicional sqflite/browser/stub),
                  session_local_datasource, solve_local_datasource,
                  auth_local_datasource (SharedPreferences + cache en memoria),
                  auth_remote_datasource (http contra el backend),
                  settings_local_datasource* + timer_settings_data (WIP)
    models/       session_model, solve_model, auth_session_model
    repositories/ session_repository_impl, solve_repository_impl, auth_repository_impl
  domain/          ← Dart puro, SIN Flutter
    entities/     session, solve (Penalty none|plus2|dnf), statistics, scramble, auth_session
    repositories/ interfaces
    usecases/     add/update/delete solve, delete_solves_by_session, create/update/delete session,
                  get_sessions, get_solves, get_statistics, generate_scramble,
                  build_wca_login_uri, complete_wca_callback, get_stored_auth_session, clear_auth_session
    puzzles/      simuladores: nxn_cube, pyraminx, skewb, megaminx, clock, square1
    scramble/     random_cube_state, two_by_two_scrambler, pyraminx_scrambler, skewb_scrambler
  presentation/
    bloc/         timer/, solve/, session/, compete/
    pages/        timer_page (principal), compete_page, settings_page, auth_page
    theme/        app_theme.dart (oscuro, fondo #020617)
    widgets/      timer/timer_display, timer/timer_actions, scramble_display, scramble_preview,
                  session_selector, solve_list, statistics_panel, category_icon,
                  responsive_centered (WIP), preview/ (un CustomPainter por puzzle + paletas + fit)
```

### 7.3 BLoCs

- **`TimerBloc`** (factory): máquina de estados del timer, umbrales de hold, inspección (15000/15000/17000 ms), `pendingPenalty` de inspección, flags de ajustes. **Riesgo alto**.
- **`SolveBloc`** (factory): carga/agrega/actualiza/borra solves, genera scrambles, refresca stats. Mantener alineados `sessionId`, `cubeType` y scramble.
- **`SessionBloc`** (factory): sesiones y la seleccionada.
- **`CompeteBloc`**: rondas versus, carriles 1 y 2, marcador, scrambles de competencia. Es **app-scoped** (vive en el `MultiBlocProvider` de `main.dart`).

### 7.4 Rutas (`main.dart`)

- Web usa `usePathUrlStrategy()` (URLs sin `#`).
- La URI del navegador se captura en `main()` **antes** del bootstrap (si no, se pierde la query del callback OAuth).
- `onGenerateRoute` (no un `routes` map) parseando `settings.name` como `Uri`:
  - `/` → `TimerPage`
  - `/auth` → `AuthPage` (perfil/login)
  - `/auth/callback?access_token=...` → `AuthPage` procesando el callback

### 7.5 Persistencia local

- **SQLite** (`local_database_sqflite.dart`): versión de DB **2**; tablas `sessions` y `solves`; la v2 agregó `is_synced` a `solves`.
- **Web** (`local_database_browser.dart`): claves de `localStorage` `salta_rubik.sessions`, `salta_rubik.solves`, `salta_rubik.initialized`. Si el JSON está corrupto, hace backup `.corrupt` y resetea ese blob (no se cuelga la app).
- **Auth**: `salta_rubik.auth_session` en SharedPreferences + cache en memoria (si la sesión guardada está corrupta, se descarta).
- **Entidad `Solve`**: `id`, `sessionId`, `timeMs`, `penalty`, `scramble`, `cubeType`, `lane` (0 single, 1-2 competencia), `createdAt`, `isSynced`.
- **Entidad `Session`**: `id`, `name`, `cubeType`, `createdAt`.

### 7.6 Tests (`test/`)

- `test/domain/` — entidades, simuladores de puzzles (validados contra `cuber`/csTimer), scramblers random-state, `generate_scramble_test.dart`.
- `test/data/` — auth datasource y repo.
- `test/presentation/` — blocs (timer, solve, session, compete), páginas (timer, compete, auth), widgets (scramble display/preview, session selector, solve list, stats panel, timer display).
- `test/support/test_helpers.dart`, `test/widget_test.dart` (smoke test).
- Los primeros a mirar si tocás algo delicado: `timer_bloc_test`, `timer_page_test`, `compete_page_test`, `compete_bloc_test`, `scramble_preview_test`, `test/domain/puzzles/`.

---

## 8. Reglas de dominio que NO se pueden romper

(Resumen de `AGENTS.md` + `CONTEXT.md` §5. Si tocás timer/sesión/scramble/stats/compete, releé esto.)

**Timer**
- Arranca al **mantener el tiempo requerido y soltar**, nunca con un toque extra. Umbrales: amarillo 150 ms, verde 300 ms.
- Se detiene **exactamente** en el toque de stop: nada visual/asíncrono puede sumar tiempo. El stop usa el último `elapsedMs` **pintado** como override (`elapsedMsOverride`) y un latch visual.
- La superficie del timer usa eventos crudos de puntero (`Listener`), no `GestureDetector` (menos latencia).
- No entrar en layout inmersivo durante `holdPending`/`armed` (Flutter cancela el gesto y el timer no arranca).
- El tiempo final en `stopped` queda visible hasta que arranque un solve nuevo. Con "Inicio rápido", cooldown mínimo de **500 ms** post-stop.
- `TimerState.elapsedMs` es siempre el tiempo crudo; la penalidad de inspección viaja en `pendingPenalty`, se consume y limpia en el stop. El DNF por inspección se **guarda** como solve con `Penalty.dnf`.
- Un toque breve durante la inspección vuelve a `inspection` **sin resetear** la cuenta regresiva.
- El listener que guarda solves vive en `timer_page.dart` (`_onTimerStateChanged`), a nivel página (si no, frenar con teclado con el historial abierto perdía el solve).
- Teclado (web/desktop): Espacio = hold/start; cualquier tecla (menos Esc) = stop.

**Sesiones / stats**
- Cambiar de sesión o tipo de cubo mantiene alineados historial, estadísticas y scramble.
- Tocar la sesión actual en el selector **no** regenera el scramble.
- Historial y stats se refrescan después de agregar/editar/borrar.
- Penalidades: solo `none`, `plus2`, `dnf`. `lane`: `0` single, `1`/`2` competencia.

**Competencia (versus)**
- El scramble se **oculta** mientras la ronda está activa y el siguiente aparece recién al cerrar ambos carriles.
- El tiempo final se congela antes de cualquier refresh.
- **Empates no suman punto.** El empate compara exactamente lo que muestra la UI (`toStringAsFixed(2)`, centésimas): 7.000 vs 7.001 es empate.
- No se puede salir a historial durante una ronda (`PopScope`); al re-entrar con una ronda colgada se despacha `AbortCompeteRound` (conserva marcador/scrambles/solves).
- El pill "VS" del centro y las stats por carril son **pasivos** (`IgnorePointer`), no roban toques.
- Resultados: comparativa por ronda/scramble (carril 1 | scramble | carril 2).

**Scrambles / preview**
- Son **"WCA-style"**, nunca decir "WCA oficial" en docs/UI/código. TNoodle no está integrado.
- 4x4/444bf: nunca `Dw`, `Lw`, `Bw`; arranca con bloque tipo 3x3 de caras externas.
- 6x6/7x7: sin `3Lw`/`3Dw`/`3Bw`. Clock: `6` y `0` siempre con `+`.
- IDs canónicos de BLD grandes: `444bf`/`555bf`; el generador también acepta los alias viejos `4x4bf`/`5x5bf` (y `3x3mbf`, `square-1`).
- El preview NxN **tiene** que usar el simulador real; nunca un stub que dibuje el cubo resuelto (ya pasó, hay test que lo cuida).
- En **web no se usa Kociemba** (`cuber`), porque congela el único thread de UI; se usa un scramble aleatorio válido.

**Plataformas**
- Cualquier ajuste de UX para web/desktop tiene que quedar **aislado**: mobile no cambia salvo pedido explícito.
- Mismas semánticas de timer/sesiones/penalties/stats en todas las plataformas.

---

## 9. Scrambles y preview visual

- Generación: `lib/domain/usecases/generate_scramble.dart` (switch por id de categoría: `3x3`, `3x3oh`, `3x3bf`, `3x3fm`, `3x3mbf`, `2x2`, `4x4`, `444bf`/`4x4bf`, `5x5`, `555bf`/`5x5bf`, `6x6`, `7x7`, `pyraminx`, `megaminx`, `skewb`, `clock`, `sq1`/`square-1`).
- **Random-state** ("calidad tipo TNoodle") para 3x3, 2x2, Pyraminx y Skewb en `lib/domain/scramble/` (estado aleatorio + resolución). En web se desactiva la búsqueda pesada.
- Tabla de longitudes y reglas: `SCRAMBLES_WCA.md` (2x2 9-10 movs; 3x3 20-25; 4x4 40; 5x5 60; 6x6 80; 7x7 100; Pyraminx 11 + tips; Megaminx 7 líneas Pochmann; Skewb 7-9; Clock 15; Square-1 12 pares con slices ejecutables).
- **Preview**: simuladores puros en `lib/domain/puzzles/` (ports de csTimer, commit `4718f7a7`, y de `SqCubie` para Square-1) + un painter por puzzle en `lib/presentation/widgets/preview/`. `scramble_preview.dart` es el widget público: normaliza variantes y despacha simulador + painter. **Para agregar un puzzle**: simulador + painter + registrarlo ahí.
- Colores/orientación: NxN blanco arriba, verde al frente (net U / L F R B / D). Pyraminx F verde, L rojo, R azul, D amarillo. Square-1: U amarillo, D blanco. Detalle en `CONTEXT.md` §7.
- Si se reporta una imagen que no coincide: comparar el simulador contra `cuber` (3x3) o csTimer con el mismo scramble; si el simulador está bien, revisar el painter; en 4x4+ revisar el parseo de wide moves.

---

## 10. Web (Flutter Web)

- Compila con `flutter build web --release`. Sirve Caddy en producción (`deploy/Caddyfile`): fallback SPA a `index.html`, gzip/zstd, y **no-cache** para `/`, `/index.html`, `flutter_service_worker.js`, `flutter_bootstrap.js`, `version.json` (para que un redeploy no quede tapado por caché).
- PWA: `web/manifest.json` con metadata real, íconos en `web/icons/`.
- Persistencia web: `localStorage` (ver §7.5). **SharedPreferences no persiste en web** en esta app.
- Layout desktop: sidebar con scroll, atajos de teclado, y (WIP) contenido centrado con ancho máximo.
- Login WCA funciona en web (§12).

---

## 11. Backend (API propia)

Carpeta `backend/`. **Fastify 5 + Prisma 6 + PostgreSQL**, TypeScript (ESM, `module: NodeNext`), Node ≥ 20. Es un servicio **separado** de la app; la app sigue siendo local-first (hoy **no sincroniza** sesiones/solves con el backend; solo lo usa para login).

- Entradas: `src/server.ts` (exige `DATABASE_URL`, puerto `PORT` o 8081, host 0.0.0.0), `src/app.ts` (CORS + rutas).
- Scripts: `dev` (tsx watch), `build` (tsc → `dist/`), `start`, `prisma:generate`, `prisma:migrate:dev`, `prisma:migrate:deploy`.
- `backend/Dockerfile`: build multi-stage con `node:20-alpine`; al arrancar corre `npx prisma migrate deploy && node dist/server.js` (las migraciones se aplican solas en cada deploy). **El build context es la raíz del repo** (copia `backend/...`).
- **Endpoints**:
  - `GET /health` (hace `SELECT 1`)
  - `GET /api/v1/auth/providers`
  - `GET /api/v1/auth/wca/start?platform=web|mobile&redirectUri=...`
  - `GET /api/v1/auth/wca/callback`
  - `GET /api/v1/auth/me` (Bearer token de Salta Rubik)
  - `GET|POST /api/v1/sessions`, `PATCH|DELETE /api/v1/sessions/:id`, `GET /api/v1/sessions/:id/solves`
  - `GET|POST /api/v1/solves`, `PATCH|DELETE /api/v1/solves/:id`
- **Modelo (Prisma)**: `users`, `external_accounts` (cuenta WCA vinculada: wca_id, email, nombre, avatar, país, tokens), `oauth_states` (state OAuth con expiración de 10 min y `consumed_at`), `sessions` y `solves` (con `owner_user_id` opcional y **soft delete** `deleted_at` para sync futura). Enums: `Penalty` (none/plus2/dnf), `AuthProvider` (wca), `OAuthPlatform` (web/mobile).
- **Migraciones**: `20260421170000_init`, `20260421210000_add_external_accounts`, `20260421224500_add_oauth_states`.
- **Variables de entorno** (ver `backend/.env.example`):
  - `DATABASE_URL` (obligatoria), `PORT`
  - `CORS_ALLOWED_ORIGINS` (debe incluir el dominio de la web, si no `/auth/me` falla en el navegador)
  - `AUTH_JWT_SECRET`, `AUTH_TOKEN_TTL_SECONDS` (default 2592000 = 30 días)
  - `AUTH_ALLOWED_REDIRECT_URIS` (allowlist de redirects post-login)
  - `WCA_OAUTH_CLIENT_ID`, `WCA_OAUTH_CLIENT_SECRET`, `WCA_OAUTH_REDIRECT_URI`
- **Token propio**: JWT HS256 hecho a mano (`src/lib/auth_token.ts`) con `sub`, `email`, `name`, `providers`, `iat`, `exp`.
- **Seguridad**: `isAllowedRedirectUri` (`src/lib/auth_redirects.ts`) compara **origin exacto** para http/https y límite de path para esquemas custom (`saltarubik://`). Esto cerró un open-redirect que permitía robar el token. No volver a un `startsWith` crudo.
- **Hoy**: el build del backend **sí está validado en Railway** (deploy SUCCESS del commit `80b33f8`). `CONTEXT.md` todavía lo marca como pendiente: está desactualizado.

---

## 12. Login con WCA (flujo completo)

1. En web, `AuthPage` → botón "Continuar con WCA" → redirección **en la misma pestaña** (`lib/core/navigation/web_redirect_web.dart`, con `url_launcher` solo de fallback) a `API/api/v1/auth/wca/start?platform=web&redirectUri=https://timer-salta-rubik-production.up.railway.app/auth/callback`.
2. El backend valida el `redirectUri` contra la allowlist, guarda un `state` en `oauth_states` y redirige a `https://www.worldcubeassociation.org/oauth/authorize` (scope `public`).
3. El usuario se loguea en la WCA y vuelve a `API/api/v1/auth/wca/callback?code=...&state=...`.
4. El backend valida/consume el `state`, cambia el `code` por token en `/oauth/token`, pide `/api/v0/me`, crea/actualiza `users` + `external_accounts` (prefiere `avatar.thumb_url`), firma **su propio** token y redirige a `https://timer-salta-rubik-production.up.railway.app/auth/callback?access_token=...&token_type=Bearer&provider=wca` (en **query string**, no en `#fragment`).
5. La app captura esa URI en `main()`, la ruta `/auth/callback` la procesa (`CompleteWcaCallback`), llama a `GET /api/v1/auth/me`, guarda la sesión local y limpia el token de la URL **sin** navegar a otra ruta (navegar causaba remounts y volvía a login vacío).
6. El perfil muestra nombre, email, WCA ID, país y avatar (`Image.network` con `errorBuilder`). Desde `TimerPage`, "Perfil" navega a `/auth`. Hay logout.
7. Si algo falla, `AuthPage` muestra un **diagnóstico** sanitizado (URI de callback, `Uri.base`, si había token en query/fragment, si se restauró sesión).

**Mobile**: todavía **no** (la UI avisa). Falta configurar deep links / app links con el esquema `saltarubik://auth/callback` (ya está en la allowlist del backend y en `AppConfig.mobileAuthCallbackUri`). Es `BE-US-014`.

---

## 13. Deploy en Railway (producción)

### 13.1 Servicios (proyecto `TIMER SALTA`, entorno `production`, región `us-east4`)

| Servicio | ID | Fuente / build | Dominio público | Variables |
|---|---|---|---|---|
| `timer-salta-rubik` (web) | `ce05fb59-441c-43e5-bae7-11b342211564` | GitHub `Froaky/timer-salta-rubik`, rama `master`, **`Dockerfile` de la raíz** (Flutter 3.29.3 → `build/web` → Caddy). En el panel figura builder "Railpack" pero Railway detecta y usa el Dockerfile de la raíz | https://timer-salta-rubik-production.up.railway.app (puerto 8080) | **Ninguna** → la app usa la API por defecto compilada en `app_config.dart` |
| `timer-api` (backend) | `852d86b9-c041-4c7b-9ae2-407d51dca022` | Mismo repo, rama `master`, Dockerfile **`/backend/Dockerfile`** | https://timer-api-production.up.railway.app (puerto 8080) | `AUTH_ALLOWED_REDIRECT_URIS`, `AUTH_JWT_SECRET`, `AUTH_TOKEN_TTL_SECONDS`, `CORS_ALLOWED_ORIGINS`, `DATABASE_URL`, `WCA_OAUTH_CLIENT_ID`, `WCA_OAUTH_CLIENT_SECRET`, `WCA_OAUTH_REDIRECT_URI` |
| `Postgres` | `92749a5e-aac6-4c7a-9ea4-a4c648315877` | Imagen `ghcr.io/railwayapp-templates/postgres-ssl:18`, volumen `postgres-volume` de 5 GB en `/var/lib/postgresql/data`, auto-updates por vulnerabilidades | Privado: host `postgres` (red interna). Tiene además un **TCP proxy público** (ver Railway → Postgres → Settings → Networking) | Las estándar (`DATABASE_URL`, `DATABASE_PUBLIC_URL`, `PG*`, `POSTGRES_*`…) |

### 13.2 Estado al 2026-10-06

- Los 3 servicios **online**, 1 réplica cada uno, sin crashes.
- Último deploy de web y API: **2026-07-07**, commit `80b33f8`, **SUCCESS**.
- Postgres: auto-update 2026-08-23 SUCCESS; el panel muestra **2 warnings** (no críticos, no investigados).
- `/health` OK con base alcanzable; `/api/v1/auth/providers` → `wca configured: true`, redirects permitidos: `https://timer-salta-rubik-production.up.railway.app/auth/callback` y `saltarubik://auth/callback`.

### 13.3 Cómo se deploya

- **Automático**: cada `push` a `master` en GitHub dispara un redeploy de **web y API** a la vez. No hay staging. Por eso: trabajar en ramas y mergear a `master` solo lo que está validado.
- Manual: desde el dashboard (Redeploy / Rollback — hay rollback habilitado en los deploys recientes) o con `railway up` / `railway redeploy` tras `railway link`.
- Para que la web apunte a otra API: setear la variable `SALTA_API_BASE_URL` en el servicio web (el `Dockerfile` la toma como build arg).
- Si agregás otro dominio para la web, actualizar en `timer-api`: `CORS_ALLOWED_ORIGINS` y `AUTH_ALLOWED_REDIRECT_URIS`.

---

## 14. Android / Play Store

- `applicationId` y `namespace`: **`com.example.salta_rubik`** (placeholder; **hay que cambiarlo antes de publicar**, y una vez publicado no se puede cambiar).
- Nombre visible: "Salta Rubik". Versión: `1.0.0+1`.
- Release firmado con la **key de debug** (no hay keystore ni `key.properties`). No sirve para Play.
- Java/Kotlin target 11, NDK 27.0.12077973, `compileSdk/minSdk/targetSdk` = defaults de Flutter.
- Íconos generados con `flutter_launcher_icons` desde `assets/icons/app_icon.png`.
- Se repartieron APKs a testers (beta 0.8.0 en mayo y otra en julio).
- **Checklist Play pendiente** (`lib/TODO.TXT`, `PS-001` a `PS-010`): applicationId final y versionado; crear y resguardar keystore/upload key (fuera del repo); generar `.aab` firmado; revisar manifest/permisos/logs; Privacy Policy pública; Data safety; ícono, screenshots, descripciones, categoría y email de soporte; smoke test en dispositivos reales; track de testing interno/cerrado; revisar políticas de Google Play.

---

## 15. Historia: qué hicimos

- **2025-08-13** — primer commit.
- **2025-10/11** — arreglos de scrambles (Pyraminx, 2x2 a 5x5), primera versión de competencia local (ramas `fixes-varios`, `local-competition`, `issues-de-los-testers`).
- **2026-01** — feedback de testers; rama experimental `posible-new-ui` (no mergeada).
- **2026-04-14/16** — previews de scramble, fixes de Clock, se declara **MVP** y se arma el checklist de Play Store. Gran tanda de fixes del timer (precisión de start/stop, `Listener`, ticker local, latch de stop, override con el valor pintado), scramble responsive, `US-001` a `US-010`, `FIX-011` a `FIX-015`.
- **2026-04-21** — skills para IA, backlog web/backend, **Flutter Web + Railway** (Dockerfile + Caddy), persistencia por plataforma, layout desktop + teclado, **backend** Fastify/Prisma/Postgres, OAuth WCA en backend (`oauth_states`, allowlist, token propio, `/auth/me`), login WCA en Flutter web.
- **2026-04-22** — estabilización del callback WCA en web (path URL strategy, query string, captura de URI en `main()`, `onGenerateRoute`, CORS, logout, perfil con avatar).
- **2026-04-23** — `PORTFOLIO_PROJECT_BRIEF.md`.
- **2026-04-27** — `FIX-016` a `FIX-020` (tiempo visible tras stop, 4x4 sin Dw/Lw/Bw, resultados de compete por scramble, scramble legible en mobile, stats flotantes).
- **2026-05-05/06** — APK beta 0.8.0 para testers; Pyraminx WCA (`FIX-021`).
- **2026-07-04** — reescritura del **preview** para todos los puzzles (simuladores + painters; `FIX-022`), alta manual de tiempos, bloqueo de historial en versus, Square-1 legal, aliases del generador (`FIX-023`).
- **2026-07-05** — scrambles **random-state** (2x2, Pyraminx, Skewb, 3x3); subagentes en `.claude/agents`.
- **2026-07-07** — **Production pass pre-release** (`PROD-001` a `PROD-010`): penalidad de inspección, DNF persistido, compete robusto, clock/6x6/7x7, Kociemba off en web, localStorage autorecuperable, wakelock, Caddy no-cache, PWA, fix de seguridad del redirect OAuth, analyze en 0, deps muertas fuera, "WCA oficial" → "WCA-style". Se reinstaló Flutter 3.29.3 en `C:\nose\flutter`. **Push y deploy a Railway** (SUCCESS).
- **~2026-07-10** — (sin commitear) persistencia de ajustes del timer, ajustes rediseñados, contenido centrado en pantallas anchas, splash web, `tool/serve_web.dart`, `launch.json`. Descubrimiento: SharedPreferences no persiste en web.
- **2026-10-06** — relevamiento para el traspaso (este archivo). WIP validado: 0 issues, 201/201 tests.

El detalle fino de cada paso está en `CONTEXT.md` §14 (Context Journal) y en `lib/TODO.TXT`.

---

## 16. Qué vamos a seguir haciendo

Orden recomendado:

1. **Asegurar el WIP** (§0): rama + push. Después: probar en celular real que los ajustes persisten al cerrar la app, y en web tras recargar. Mergear a `master` (= deploy).
2. **Smoke test real en producción web** (`WEB-US-001`, lo único que falta para cerrar `EPIC-WEB-001`): abrir la URL, crear sesión, agregar solve, recargar y verificar que persiste; probar teclado; probar login WCA de punta a punta. Si da bien, marcar `WEB-US-001` ✅.
3. **Retest manual en dispositivo real** (Android): inspección con +2/DNF (flujo `pendingPenalty`), wakelock en solves largos, compete completo (abortar ronda al salir/volver).
4. **Play Store** (`PS-001` a `PS-010`, §14). Lo primero: definir `applicationId` real (ej. `com.froaky.saltarubik`), crear keystore y guardarla fuera del repo con backup, configurar `signingConfigs` de release.
5. **Login WCA en mobile** (`BE-US-014`): deep links/app links `saltarubik://auth/callback` en `AndroidManifest.xml` + manejo en la app.
6. **Backend**: `BE-US-006` stats derivadas desde backend (`EPIC-BE-002`).
7. **Sync / cuenta** (`EPIC-WEB-003`, `BE-US-009`, `BE-US-010`, `WEB-US-008` a `WEB-US-010`): identidad remota estable de sesiones/solves, migración de datos locales a cuenta, reglas de sync y conflictos (el backend ya tiene `is_synced`, `deleted_at`, `owner_user_id`).
8. **Web autenticada** (`EPIC-WEB-004`, `WEB-US-011` a `WEB-US-014`): ver sesiones/solves/stats de la cuenta desde web.
9. **`WEB-US-007`**: tests de contrato compartidos entre storage mobile y web.
10. Extensión de `FIX-017`: rotaciones finales (`z' y'`) en scrambles BLD (el simulador ya las soporta).
11. **Limpieza**: borrar `negros/` y `test_output.txt`; descartar los 2 stashes; borrar ramas remotas ya mergeadas; decidir `posible-new-ui`; actualizar `AGENTS.md` (Firebase, "README boilerplate"); revisar los 2 warnings de Postgres en Railway.

Notas del dev que quedaron en el backlog (no son tareas cerradas): sumar alguna librería de navegación más intuitiva (se mencionó GetX o similar); la animación de zoom al empezar/terminar el timer ya está implementada.

---

## 17. Archivos de documentación y de IA del repo

| Archivo | Para qué | Estado |
|---|---|---|
| `AGENTS.md` | Reglas del repo para agentes (Codex y Claude Code lo leen): contexto, reglas de trabajo, guardrails, validación, mantenimiento de `CONTEXT.md`, skills sugeridas | Vigente (con detalles desactualizados: Firebase, README) |
| `CONTEXT.md` | **Memoria compartida del repo** para cualquier IA: archivos clave, invariantes, cambios hechos, motor de preview, pendientes, comandos, convenciones, entorno, **journal** | Vigente; actualizado el 2026-10-06 (entorno, journal del WIP y del traspaso) sin commitear |
| `lib/TODO.TXT` | **Backlog vivo** (✅ = hecho) | Vigente |
| `README.md` | Descripción, stack, validación, deploy Railway, backend, alcance web, scrambles | Vigente |
| `backend/README.md` | Setup, variables, endpoints y deploy del backend | Vigente |
| `SCRAMBLES_WCA.md` | Qué genera cada evento y diferencias con TNoodle | Vigente |
| `PORTFOLIO_PROJECT_BRIEF.md` | Texto para portfolio/CV sin exagerar features | Vigente |
| `GEMINI.md` | Instrucciones genéricas para Gemini | Poco relevante |
| `.claude/agents/*.md` (14, **versionados**) | Subagentes de Claude Code (modelo `opus`): auth-sync-readiness, backlog-finisher, code-quality, cross-platform-storage, docs-sync, epic-story-writer, flutter-bloc-feature, flutter-web-railway, implementation-planner, refactor-safe, repo-onboarding, task-decomposer, test-writer, timer-domain-safety | Se cargan solos en Claude Code |
| `.claude/settings.local.json` (versionado) | Permisos de Claude Code para este repo (`defaultMode: dontAsk`, deny de force-push/reset --hard/clean/rm -rf, `additionalDirectories: C:\`) | Modificado sin commitear |
| `.claude/launch.json` (sin trackear) | Configs de preview (web 8080 y web-release 8090) | En el WIP |
| `.agents/skills/*` (versionado) | Las mismas skills en formato Codex (`SKILL.md` + `agents/openai.yaml` + referencias) | — |
| `.agent/skills/*` (versionado) | Versión anterior/reducida de 7 skills genéricas | Legado |
| `.codex/agents/*.toml` (sin trackear) | Subagentes en formato Codex | En el WIP |

---

## 18. Cómo arrancar con la cuenta nueva de Claude

1. Instalá/abrí **Claude Code** (app de escritorio, pestaña Code, o la CLI `claude`) y logueate con la cuenta nueva.
2. Abrí la carpeta del repo (`C:\Users\MateoCoca\Documents\REPOS\timer-salta-rubik` o donde lo clones).
3. Claude Code va a cargar `AGENTS.md` y los subagentes de `.claude/agents/`. Si en tu versión no levanta `AGENTS.md` automáticamente, creá un `CLAUDE.md` en la raíz con una sola línea: `@AGENTS.md`.
4. La primera vez, aprobá los permisos que pida (o revisá `.claude/settings.local.json`).
5. (Opcional) Conectá el **MCP de Railway** en la cuenta nueva para que Claude pueda ver deploys/logs/variables; o usá la Railway CLI (`railway login`, `railway link`).
6. (Opcional) Recreá la memoria del proyecto: pedile a Claude que guarde como memoria el punto "SharedPreferences no persiste en web" de §19.
7. **Prompt inicial sugerido** (copiar y pegar):

   > Leé `GUIA_TRASPASO.md`, `AGENTS.md`, `CONTEXT.md` y `lib/TODO.TXT` antes de hacer nada. Después verificá el entorno: Flutter 3.29.3 en `C:\nose\flutter\bin` (no está en el PATH), corré `flutter analyze --no-pub` y `flutter test --no-pub`, y mostrame `git status` y la rama actual. Recién ahí proponeme el siguiente paso según la sección 16 de la guía. No pushees a `master` sin preguntarme: cada push a `master` deploya producción en Railway.

---

## 19. Trampas conocidas

- **Flutter no está en el PATH** en esta PC: usar `C:\nose\flutter\bin\flutter.bat`.
- **No actualizar Flutter** (3.29.3) sin actualizar el `Dockerfile` y `.metadata` a la vez.
- **`flutter pub get` puede fallar** en Windows sin Modo desarrollador (symlinks de plugins): usar `dart pub get` y luego los comandos con `--no-pub`.
- **Push a `master` = deploy a producción** (web + API). No hay staging.
- **SharedPreferences no persiste en web** en esta app (verificado 2026-07-10: `setBool` no crea nada en localStorage/IndexedDB, no tira error, al recargar se pierde). Todo estado persistente que tenga que funcionar en web va por `dart:html window.localStorage` con export condicional (patrón de `local_database.dart` y `settings_local_datasource.dart`). SharedPreferences está bien solo para cosas nativas (auth lo usa con cache en memoria).
- **Kociemba (`cuber`) congela la web**: no reactivarlo en web sin moverlo a un worker/isolate.
- **Callback OAuth en web**: no cambiar a `routes` estático, no navegar a `/auth` después del login, no mandar el token en `#fragment`, no leer la URL solo en `initState`. Cada una de esas cosas ya rompió el login.
- **CORS**: si cambia el dominio de la web, actualizar `CORS_ALLOWED_ORIGINS` y `AUTH_ALLOWED_REDIRECT_URIS` en `timer-api`.
- **Allowlist de redirects**: no volver a `startsWith` crudo (open-redirect con robo de token).
- **Preview del cubo**: nunca dejar un stub que dibuje el cubo resuelto.
- **Selector de categorías vs generador**: si agregás una categoría nueva al selector, agregala al `switch` de `GenerateScramble` (si no, cae a 3x3 en silencio; ya pasó con `4x4bf`/`5x5bf`).
- **Layout inmersivo durante `holdPending`/`armed`** cancela el gesto: no.
- **`GestureDetector`** en la superficie del timer agrega latencia: usar `Listener`.
- **Archivos generados** (`GeneratedPluginRegistrant`, registrants de desktop) no se editan a mano.
- **`.metadata`** no se edita a mano.
- **Repo público**: nunca commitear `.env`, keystores ni secretos.
- Fin de línea: git avisa "LF will be replaced by CRLF" en varios archivos; es normal en Windows.

---

## 20. Glosario

- **Speedcubing**: resolver cubos Rubik y puzzles similares lo más rápido posible.
- **WCA**: World Cube Association, la federación oficial (reglamento, competencias, rankings). Tiene API y OAuth.
- **Scramble**: secuencia de movimientos para mezclar el puzzle antes de un intento.
- **TNoodle**: el programa oficial de la WCA para generar scrambles (Java). No lo usamos.
- **Random-state**: generar un estado aleatorio del puzzle y calcular cómo llegar a él (más justo que movimientos al azar).
- **Kociemba**: algoritmo de dos fases para resolver el 3x3; lo trae el paquete Dart `cuber`.
- **csTimer**: timer web de referencia; portamos sus tablas de simulación para el preview.
- **Inspección**: 15 s para mirar el cubo antes de arrancar. >15 s → +2; >17 s → DNF.
- **+2**: penalidad de 2 segundos. **DNF**: Did Not Finish (intento inválido).
- **PB**: mejor single. **mo3**: media de 3. **ao5/ao12/…**: promedio de N quitando el mejor y el peor (con reglas de DNF).
- **OH**: una mano (`3x3oh`). **BLD / bf**: a ciegas (`3x3bf`, `444bf`, `555bf`). **FMC / fm**: menor cantidad de movimientos. **MBLD / mbf**: múltiples a ciegas.
- **Wide move** (`Rw`, `3Rw`): girar varias capas. **Lane / carril**: lado de cada jugador en versus.
- **BLoC**: patrón de estado (eventos → estados). **get_it**: contenedor de dependencias.
- **Railway**: plataforma de hosting (PaaS). **Caddy**: servidor web que sirve la build web. **Prisma**: ORM del backend.
- **Export condicional**: `export 'a.dart' if (dart.library.html) 'b.dart' ...` para elegir implementación por plataforma.

---

## 21. Checklist final

- [ ] WIP commiteado en una rama y pusheado (§0).
- [ ] Esta guía guardada fuera de esta PC (en el repo o en Drive/mail).
- [ ] Acceso confirmado a GitHub `Froaky` desde la cuenta/PC nueva (`gh auth status`).
- [ ] Acceso confirmado a Railway con `mateococa.job@gmail.com` (proyecto "TIMER SALTA").
- [ ] Saber con qué cuenta WCA está registrada la app OAuth (worldcubeassociation.org → OAuth applications).
- [ ] Toolchain OK: `flutter --version` = 3.29.3, `flutter doctor -v`.
- [ ] `flutter analyze --no-pub` = 0 issues y `flutter test --no-pub` en verde.
- [ ] Claude Code en la cuenta nueva leyendo `AGENTS.md` (o `CLAUDE.md` con `@AGENTS.md`).
- [ ] Seguir con §16.
