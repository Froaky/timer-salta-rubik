# Story Patterns

Use these templates to keep backlog items consistent and implementation-ready.

## Epic template

- `EPIC-XXX | <nombre corto>`
- Objetivo:
  - `<resultado de negocio o producto>`
- Alcance:
  - `<que entra>`
- Fuera de alcance:
  - `<que no entra>`
- Riesgos:
  - `<riesgos de producto o integracion>`

## Feature story template

- `US-XXX | Como <persona>, quiero <capacidad>, para <valor>.`
- Acceptance criteria:
  - `<criterio observable 1>`
  - `<criterio observable 2>`
  - `<criterio observable 3>`
- Guardrails:
  - `<comportamientos existentes que no se deben romper>`

## Fix story template

- `FIX-XXX | Como <persona afectada>, quiero que <comportamiento corregido>, para <resultado esperado>.`
- Problema actual:
  - `<que falla hoy>`
- Acceptance criteria:
  - `<resultado esperado>`
  - `<caso de regresion cubierto>`
- Guardrails:
  - `<invariantes del dominio a preservar>`

## Release or Play Store task template

- `PS-XXX | <accion concreta de release>`
- Done criteria:
  - `<evidencia o entregable>`
  - `<validacion minima>`
- Dependencias:
  - `<si aplica>`

## Slicing heuristics

- Si una historia mezcla UI, persistencia, y reglas nuevas con riesgo alto, probablemente son varias historias.
- Si un item no puede validarse sin "y tambien", probablemente esta sobredimensionado.
- Si el valor no cambia para el usuario ni para release, probablemente no es una user story sino una tarea tecnica.

## Repo-specific reminders

- Timer:
  - no romper `idle`, `holdPending`, `armed`, `inspection`, `running`, `stopped`
  - el stop debe congelar el tiempo exacto al toque
- Sessions and solves:
  - cambiar sesion o cubo debe mantener scramble, historial y stats alineados
- Compete mode:
  - mantener restricciones de acceso y semantica de carriles
- Launch:
  - revisar `lib/TODO.TXT` antes de agregar nuevos items `PS-*`
