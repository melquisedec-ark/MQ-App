# `doc/` — Documentación de MQ-App

> **Proyecto:** MQ-App (Biblia RV1909 + RV1569 + Himnario)
> **Stack:** Flutter 3.x / Dart 3.x / Riverpod 2.x / gRPC + mDNS / SQLite (FFI)
> **Plataformas:** Windows · macOS · Linux · Android · iOS
> **Branch activo:** `mq-app-init` (sin remote, 11 commits, working tree limpio)

Este directorio contiene **toda la documentación del proyecto**. Está organizado en
dos bloques:

1. **Bloque Phase 1 (este sprint, cerrado el 1 jun 2026):** los 6 archivos
   listados abajo — reflejan **qué se hizo**, **qué se decidió** y **qué
   sigue**.
2. **Bloque histórico de HimnarioID 2.0:** ~30 archivos `.md` (CONTEXTO,
   ARQUITECTURA_DATOS, ANDROID_BUILD, BUILD_WINDOWS, CONEXION_LAN,
   LECCIONES_MERGE, etc.) que documentan la base que se clonó. Se conservan
   como referencia. **No modificar** — son historia del proyecto base.

---

## 📚 Índice de documentación de Phase 1

| Documento | Propósito | Para quién |
|-----------|-----------|-----------|
| **[README.md](README.md)** | Este índice | Todos |
| **[PHASE_1_REPORT.md](PHASE_1_REPORT.md)** | Reporte ejecutivo: qué se hizo, qué se arregló, qué sigue | Nuevos contribuidores, @user al volver |
| **[ARCHITECTURE_DECISIONS.md](ARCHITECTURE_DECISIONS.md)** | 12 decisiones arquitectónicas con contexto, opciones y rationale | @arqui, @dev, futuros arquitectos |
| **[DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)** | Schema de `biblia.db`: 6 tablas, FTS5, triggers, queries típicas | @dev implementando repositorios en Fase 2 |
| **[GIT_HISTORY.md](GIT_HISTORY.md)** | Estrategia de branch (orphan) y log de los 11 commits | @dev, futura creación de remote |
| **[TODO_PHASE_2.md](TODO_PHASE_2.md)** | Kickoff checklist de Fase 2 (~40 tareas) | @dev, @back, @design en próxima sesión |

---

## 🖼 Wireframes (APROBADOS, no tocar)

`doc/wireframes/` — 5 documentos visuales, **APROBADOS** el 1 jun 2026:

| Archivo | Pantalla | Líneas |
|---------|----------|--------|
| [01_home_screen.md](wireframes/01_home_screen.md) | Home con versículo aleatorio + 2 cards | 356 |
| [02_bible_module.md](wireframes/02_bible_module.md) | Módulo Biblia: book → chapter → reader | 529 |
| [03_emitter_views.md](wireframes/03_emitter_views.md) | Vista del Emisor: COMPACT vs PREVIEW | 423 |
| [04_navigation_flow.md](wireframes/04_navigation_flow.md) | Flujo de navegación completo | 305 |
| [05_style_guide.md](wireframes/05_style_guide.md) | Tokens de color, tipografía, glassmorphism | 625 |

> Total wireframes: **2 238 líneas, ~101 KB** (incluye paletas, ASCII layouts,
> decisiones de UX, contratos de gRPC).

---

## 🗄 Documentación del schema de DB

| Documento | Ubicación | Propósito |
|-----------|-----------|-----------|
| Schema SQL | `assets/db/schema/001_biblia_schema.sql` | DDL puro: 6 tablas + FTS5 + 12 índices + 7 triggers |
| README del schema | `assets/db/schema/README.md` | Decisiones de diseño (FTS5 external content, UNIQUE, schema_version) |
| README de la DB | `assets/db/README.md` | Cómo se distribuye, tamaños esperados, build script |
| README del core DB | `lib/core/database/README.md` | Stack FFI, por qué SQLite 3.46+, diagnóstico |

---

## 📜 Spec maestra del proyecto (NO TOCAR)

`/home/melquisedec/Escritorio/Projects/Personales/MQ App/nuevaidea.md` —

> Documento de concepto y especificación inicial escrito por el usuario.
> 12 secciones, 751 líneas, versión 1.4. Es la **fuente de verdad** del
> producto. Toda la implementación se alinea con este spec. **No modificar.**

---

## 🗂 Estructura completa de `doc/`

```
doc/
├── README.md                       ← (este archivo, índice)
├── PHASE_1_REPORT.md               ← reporte principal de Phase 1
├── ARCHITECTURE_DECISIONS.md       ← 12 decisiones arquitectónicas
├── DATABASE_SCHEMA.md              ← schema docs para Fase 2
├── GIT_HISTORY.md                  ← estrategia de branch + commit log
├── TODO_PHASE_2.md                 ← kickoff checklist de Fase 2
│
├── wireframes/                     ← 5 wireframes APROBADOS
│   ├── 01_home_screen.md
│   ├── 02_bible_module.md
│   ├── 03_emitter_views.md
│   ├── 04_navigation_flow.md
│   └── 05_style_guide.md
│
├── [docs históricos de HimnarioID 2.0 — no modificar]
├── CONTEXTO_PROYECTO.md
├── ARQUITECTURA_DATOS.md
├── GLASSMORPHISM.md
├── CONEXION_LAN.md
├── SISTEMA_BUSQUEDA.md
├── ANDROID_BUILD.md
├── BUILD_WINDOWS.md
├── build-macos-linux.md
├── guia-build-ios.md
├── git-ramas-guia.md
├── PROCESO_RELEASE.md
├── LECCIONES_MERGE.md
├── DB_INIT_BACKUP_RESTORE.md
├── BUG_FONDO_RESET.md
├── PLAN_ARQUITECTONICO_IOS.md
├── PLAN_DE_DELEGACION.md
├── TASKS_DESIGN.md
├── TASKS_DEV.md
├── TASKS_QA.md
├── TASKS_FASE4.md
├── TAREAS_DIFERIDAS.md
├── tareas_pendientes.md
├── especificaciones-diseno.md
├── implementacion.md
├── Interfaz.md
├── acordes.md
├── Version_Web.md
├── windowsdb.md
├── apk-build-guia.md
└── api/
```

---

## 🔍 Búsqueda rápida

- **"¿Qué se hizo en Phase 1?"** → [PHASE_1_REPORT.md](PHASE_1_REPORT.md)
- **"¿Por qué se eligió X?"** → [ARCHITECTURE_DECISIONS.md](ARCHITECTURE_DECISIONS.md)
- **"¿Cómo es el schema de la Biblia?"** → [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)
- **"¿Cuáles son los commits?"** → [GIT_HISTORY.md](GIT_HISTORY.md)
- **"¿Qué sigue?"** → [TODO_PHASE_2.md](TODO_PHASE_2.md)
- **"¿Qué pantallas hay?"** → [doc/wireframes/](wireframes/)
- **"¿Qué quería el usuario originalmente?"** → `../MQ App/nuevaidea.md`
- **"¿Cómo era HimnarioID 2.0?"** → [CONTEXTO_PROYECTO.md](CONTEXTO_PROYECTO.md) (histórico)

---

*Última actualización: 1 de junio de 2026 — cierre de Phase 1*
*Generado por: @documentador*
