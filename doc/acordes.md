# Sistema de Renderizado de Acordes — HimnarioID 2.0

> **Documento definitivo.** Recopila toda la historia, decisiones arquitectónicas, bugs, fixes y agentes involucrados en el sistema de renderizado de acordes ChordPro.
> **Última actualización:** 25 de mayo de 2026

---

## Índice

1. [Resumen del Sistema](#1-resumen-del-sistema)
2. [Cronología Completa](#2-cronología-completa)
3. [Arquitectura Actual](#3-arquitectura-actual)
4. [Archivos del Sistema](#4-archivos-del-sistema)
5. [Flujo de Datos (Pipeline)](#5-flujo-de-datos-pipeline)
6. [Bugs y Fixes](#6-bugs-y-fixes)
   - 6.1 [Bug 1 — Desalineación y Fractura de Palabras (obs.md)](#61-bug-1--desalineación-y-fractura-de-palabras)
   - 6.2 [Bug 2 — Caja Ancha y Efecto Ladrillo (correcciones.md)](#62-bug-2--caja-ancha-y-efecto-ladrillo)
7. [Agentes Involucrados](#7-agentes-involucrados)
8. [Archivos Legacy Eliminados](#8-archivos-legacy-eliminados)
9. [Tests](#9-tests)
10. [Referencia Rápida](#10-referencia-rápida)
11. [Archivos Relacionados (Raíz)](#11-archivos-relacionados-raíz)

---

## 1. Resumen del Sistema

El sistema renderiza texto en formato **ChordPro** (ej: `[C]Santo [G]Dios`) mostrando los acordes sobre la letra correspondiente, con diseño **totalmente responsivo** (Wrap nativo de Flutter). No depende de paquetes externos ni de CustomPainter.

### Principios de diseño

| Principio | Descripción |
|-----------|-------------|
| **Responsivo nativo** | Widget `Wrap` de Flutter para reflow automático |
| **Sin CustomPainter** | No mide posiciones con TextPainter ni usa caché LRU |
| **Stack por segmento** | Solo para que el acorde flote sin estirar la columna |
| **Word-level parsing** | Cada palabra es un `ChordSegment` individual para que Wrap pueda cortar en cualquier espacio |
| **Functional-style** | Funciones puras, sin estado mutable, modelos inmutables |
| **Backward compatible** | `parseChordProLine()` no se modificó — el API público sigue igual |

---

## 2. Cronología Completa

### Fase 1 — Sistema Legacy (antes del 25 mayo)
```
chord_overlay_text.dart  →  Stack + Positioned + ChordPainter (caché LRU)
chord_painter.dart       →  Mide posiciones con TextPainter, cachea resultados
stanza_layout_engine.dart →  Decide saltos de línea midiendo ancho de cada línea
```

Problemas del sistema legacy:
- No era responsivo al cambiar el ancho de pantalla
- Stack global con Positioned para cada acorde
- StanzaLayoutEngine requería medir con TextPainter cada línea
- ChordPainter mantenía un caché LRU (64 entradas) con estado mutable

### Fase 2 — Wrap básico (commit `c55a964`)
**Rama:** `feature/renderizador-acordes-responsive`

**Agentes:** @curie (evaluación), @arqui (plan), @dev (core), @design (UI)

**Cambios:**
- Creación de `ChordSegment` (modelo inmutable)
- Creación de `ResponsiveChordWidget` con Wrap nativo
- Extensión del regex para paréntesis: `[C#m7(b5)]`
- Nueva función `parseChordProStanza()` para parseo multilínea
- Eliminación de 3 archivos legacy

**Archivos creados/modificados:**
| Archivo | Acción |
|---------|--------|
| `lib/core/chords/chord_segment.dart` | ✅ Creado |
| `lib/core/chords/chord_parser.dart` | Modificado (regex + parseChordProStanza) |
| `lib/presentation/shared_widgets/responsive_chord_widget.dart` | ✅ Creado |
| `lib/presentation/views_personal/hymn_scroll/hymn_detail_screen.dart` | Modificado |
| `lib/presentation/views_projection/display/live_projection_screen.dart` | Modificado |
| `lib/presentation/shared_widgets/chord_overlay_text.dart` | ❌ Eliminado |
| `lib/core/chords/chord_painter.dart` | ❌ Eliminado |
| `lib/core/utils/stanza_layout_engine.dart` | ❌ Eliminado |
| `test/unit/core/chords/chord_parser_test.dart` | Modificado (+8 tests) |

**Hallazgos de @arqui (ac.md):**
- **M1** (MEDIA): Trailing blank lines en `parseChordProStanza` generan espaciado no deseado
- **M2** (MEDIA): Falta `textAlign` en `ResponsiveChordWidget`
- **L1-L5** (BAJA): Casos borde y cobertura de tests

### Fase 3 — Fix M1 + M2 + textAlign + trailing blanks (commit `56aa50a`)

**Correcciones aplicadas:**
- Trim de trailing `\n` antes del split en `parseChordProStanza`
- Parámetros `TextAlign? textAlign` y `WrapAlignment runAlignment` en el widget
- `textAlign: TextAlign.center` en proyección, `TextAlign.justify` en detalle
- `parseChordProStanza('')` retorna `[]` en vez de lista con segmento vacío
- Tests para ChordSegment model (==, hashCode, toString) y trailing blanks

### Fase 4 — Fix Caja Ancha + Efecto Ladrillo (commit `e114994`)

Motivado por bugs reportados en `obs.md` y `correcciones.md`.

**Agentes:** @curie (evaluación), @arqui (plan), @dev (expandToWordSegments), @design (Stack)

**Bug 1 — Caja Ancha (Stack approach):**
- Cuando un acorde es más ancho que su sílaba (ej: `D/F#` sobre `a`), la Column se estiraba al ancho del acorde
- **Fix:** Stack con `clipBehavior: Clip.none` + `Positioned(left:0, top:0)` + dummy `Text(' ')` transparente
- El acorde flota sin afectar el layout, la letra dicta el ancho real

**Bug 2 — Efecto Ladrillo (word-splitting):**
- `parseChordProLine` agrupaba todo el texto sin acordes en un solo `ChordSegment` gigante
- Wrap no podía dividir ese bloque → layout roto en pantallas pequeñas
- **Fix:** Nueva función `expandToWordSegments()` (NO se modificó `parseChordProLine`)
- Cada palabra se convierte en un `ChordSegment` individual
- Wrap puede cortar líneas en cualquier espacio

**Regresiones de obs.md/correcciones.md que NO se copiaron:**
| Regresión | Peligro | Corrección aplicada |
|-----------|---------|---------------------|
| `const _LineBreakPlaceholder(lineSpacing: 10.0)` | Ignora `lineSpacing` del widget | Usa `lineSpacing` del constructor |
| `chordStyle?.copyWith(height: 1.1)` | Null si chordStyle es null | `_effectiveChordStyle.copyWith()` con fallback |
| `lyricStyle?.copyWith(height: 1.1)` | Variable no existe | `_effectiveTextStyle.copyWith()` |
| `runSpacing: 10.0` | Hardcodeado | `runSpacing: lineSpacing` |
| Falta `TextAlign.right` | Proyección right rota | Mapeado a `WrapAlignment.end` |

### Fase 5 — Merge a main + builds (commit `e114994` → `6dca680`)
- Merge fast-forward a `main`
- APK Android reconstruido desde 0 (`rm -rf build .dart_tool`)
- Windows CI disparado en GitHub Actions
- Contexto actualizado en `doc/tareas_pendientes.md`

---

## 3. Arquitectura Actual

### Diagrama de componentes

```
┌──────────────────────────────────────────────────────┐
│                   ChordPro raw text                   │
│              "[C]Santo [G]Dios\n[Am]Señor"           │
└─────────────────────┬────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────┐
│              parseChordProStanza(text)                │
│  1. Trim trailing \n                                  │
│  2. split('\n') → líneas                              │
│  3. parseChordProLine(line) → List<ChordLine>         │
│  4. expandToWordSegments(chordLines) → List<ChordSegment>│
│  5. Maneja blanks y saltos poéticos                   │
└─────────────────────┬────────────────────────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────┐
│              ResponsiveChordWidget.build()             │
│                                                       │
│  Wrap(                                                │
│    spacing: 0.0,                                      │
│    runSpacing: lineSpacing,                           │
│    alignment: condicional según textAlign,            │
│    crossAxisAlignment: WrapCrossAlignment.end,        │
│    children: [                                        │
│      Column(                                          │
│        crossAxisAlignment: CrossAxisAlignment.start,  │
│        children: [                                    │
│          Stack(                                       │
│            clipBehavior: Clip.none,                   │
│            children: [                                │
│              Text(' ') [transparente, dummy altura],  │
│              Positioned(left:0, top:0) [chord],       │
│            ],                                         │
│          ),                                           │
│          Text(lyric, textAlign: textAlign),           │
│        ],                                             │
│      ),                                               │
│      _LineBreakPlaceholder(lineSpacing),  ← salto    │
│    ],                                                 │
│  )                                                    │
└──────────────────────────────────────────────────────┘
```

### Reglas de layout

| Regla | Valor | Propósito |
|-------|-------|-----------|
| Column `crossAxisAlignment` | `CrossAxisAlignment.start` | Anclar acorde a la primera letra |
| Stack `clipBehavior` | `Clip.none` | Acorde no se recorta si desborda |
| Dummy `Text(' ')` | `color: Colors.transparent` | Reserva altura de línea sin ocupar ancho |
| `Positioned(left: 0, top: 0)` | — | Acorde arranca desde el borde izquierdo |
| Wrap `spacing` | `0.0` | Cero espacio horizontal entre Columnas |
| Wrap `runSpacing` | `lineSpacing` | Espaciado vertical dinámico |
| Wrap `alignment` | Según `textAlign` | `center` → center, `right` → end, default → start |
| Wrap `crossAxisAlignment` | `WrapCrossAlignment.end` | Alineación vertical por la parte inferior |
| Text `height` | `1.1` | Acerca visualmente acorde a letra |

---

## 4. Archivos del Sistema

### Core (lógica de negocio)

| Archivo | Propósito | Líneas |
|---------|-----------|--------|
| `lib/core/chords/chord_segment.dart` | Modelo inmutable: `chord`, `text`, `isLineBreak`. Con `==`, `hashCode`, `toString`. | 34 |
| `lib/core/chords/chord_line.dart` | Modelo legacy preservado: `ChordLine(chord?, text)`. Usado internamente por `parseChordProLine`. | 22 |
| `lib/core/chords/chord_parser.dart` | Funciones: `parseChordProLine()`, `stripChords()`, `chordRegex`, `parseChordProStanza()`, `expandToWordSegments()`. | 162 |

### Presentación (UI)

| Archivo | Propósito | Líneas |
|---------|-----------|--------|
| `lib/presentation/shared_widgets/responsive_chord_widget.dart` | Widget Wrap que renderiza ChordPro. Parámetros: `stanza`, `textStyle`, `chordStyle`, `lineSpacing`, `textAlign`, `runAlignment`, `debug`. | 125 |
| `lib/presentation/views_personal/hymn_scroll/hymn_detail_screen.dart` | Pantalla de detalle de himno. Usa `ResponsiveChordWidget` con `textAlign: TextAlign.justify`. | ~952 |
| `lib/presentation/views_projection/display/live_projection_screen.dart` | Pantalla de proyección en vivo. Usa `ResponsiveChordWidget` con `textAlign: TextAlign.center, runAlignment: WrapAlignment.center`. | ~599 |

### Tests

| Archivo | Tests | Cubre |
|---------|-------|-------|
| `test/unit/core/chords/chord_parser_test.dart` | 45 tests | parseChordProLine (10), stripChords (3), chordRegex (9), parseChordProStanza (10), expandToWordSegments (6), ChordSegment model (7) |

---

## 5. Flujo de Datos (Pipeline)

### Entrada → Salida

```
Texto ChordPro (String):
  "[C]Santo [G]Dios\n[Am]Señor"

  │
  ▼
parseChordProStanza()
  ├── trim trailing \n
  ├── split('\n') → ["[C]Santo [G]Dios", "[Am]Señor"]
  │
  ├── Línea 1: "[C]Santo [G]Dios"
  │   ├── parseChordProLine() → [CL('C','Santo '), CL('G','Dios')]
  │   └── expandToWordSegments() → [CS('C','Santo '), CS('G','Dios')]
  │
  ├── LineBreak entre líneas
  │
  ├── Línea 2: "[Am]Señor"
  │   ├── parseChordProLine() → [CL('Am','Señor')]
  │   └── expandToWordSegments() → [CS('Am','Señor')]
  │
  └── → [CS('C','Santo '), CS('G','Dios'), CS(⏎), CS('Am','Señor')]

  │
  ▼
ResponsiveChordWidget.build()
  └── Wrap(children: [Column(Stack[...], Text[...]), ...])
      └── Renderizado en pantalla
```

### Ejemplo visual

```
ChordPro:  [D]Cerc[D/F#]a   (sin espacio entre "Cerc" y "a")

Parseo:
  parseChordProLine → [CL('D','Cerc'), CL('D/F#','a')]
  expandToWordSegments → [CS('D','Cerc'), CS('D/F#','a')]

Renderizado (con Stack + spacing:0):
       D    D/F#
  ── Cerca ──▶  (Wrap puede cortar aquí si no cabe)

  La "D" flota sobre "Cerc", la "D/F#" flota sobre "a".
  Sin Stack, la "D/F#" estiraría la columna y empujaría "a" → "Cerc  a".
  Con Stack, el acorde flota, la letra dicta el ancho.
```

---

## 6. Bugs y Fixes

### 6.1 Bug 1 — Desalineación y Fractura de Palabras

**Reportado en:** `obs.md` (raíz)
**Gravedad:** Alta

**Síntomas:**
1. El acorde no se ancla a la primera letra de la sílaba. Ej: `[D]Cerc[D/F#]a` → D flota sobre "rc" en vez de "C"
2. Espacios artificiales a mitad de palabra. Ej: "Cerc a" en vez de "Cerca"

**Causa raíz:**
- `Column` sin `crossAxisAlignment` (default = `center`) → acorde centrado, no anclado
- `Padding(right: 4)` en cada segmento → espacio horizontal entre "Cerc" y "a"

**Fix aplicado:**
| Cambio | Archivo | Línea |
|--------|---------|-------|
| `Column(crossAxisAlignment: CrossAxisAlignment.start)` | responsive_chord_widget.dart | 64 |
| Eliminar `Padding(right: 4)` de cada segmento | responsive_chord_widget.dart | — |
| `height: 1.1` en Text styles | responsive_chord_widget.dart | 71-80 |
| `alignment` condicional según textAlign | responsive_chord_widget.dart | 79-83 |

### 6.2 Bug 2 — Caja Ancha y Efecto Ladrillo

**Reportado en:** `correcciones.md` (raíz)
**Gravedad:** Crítica

**Síntomas:**
1. **Caja Ancha:** Acorde más ancho que su letra (ej: `D/F#` sobre `a`) estira la columna → gaps
2. **Efecto Ladrillo:** Texto sin acordes en un solo segmento → Wrap no puede dividir

**Causa raíz:**
- Column se dimensiona al ancho del hijo más ancho → el acorde estira la columna
- `parseChordProLine` produce un solo `ChordLine` con todo el texto sin acordes

**Fix aplicado:**

**Paso 1 — Stack (Caja Ancha):**
```dart
Stack(
  clipBehavior: Clip.none,
  children: [
    Text(' ', style: chordStyle.copyWith(color: Colors.transparent)),
    if (segment.chord != null)
      Positioned(left: 0, top: 0, child: Text(segment.chord!)),
  ],
),
```

**Paso 2 — expandToWordSegments (Efecto Ladrillo):**
```dart
List<ChordSegment> expandToWordSegments(List<ChordLine> lines) {
  final result = <ChordSegment>[];
  for (final line in lines) {
    if (line.text.isEmpty) {
      result.add(ChordSegment(chord: line.chord, text: ''));
      continue;
    }
    final words = line.text.split(' ');
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;
      result.add(ChordSegment(
        chord: i == 0 ? line.chord : null,
        text: word + (i < words.length - 1 ? ' ' : ''),
      ));
    }
  }
  return result;
}
```

**Regresiones evitadas (gracias a @arqui + @curie):**
El código propuesto en `obs.md` y `correcciones.md` por el usuario contenía 5 regresiones que fueron identificadas y corregidas antes de implementar:

| Archivo obs.md/correcciones.md | Regresión | Corrección |
|-------------------------------|-----------|------------|
| `_LineBreakPlaceholder(lineSpacing: 10.0)` | Hardcodeaba 10px | Usa `lineSpacing` del constructor |
| `chordStyle?.copyWith(height: 1.1)` | Null si chordStyle es null | `_effectiveChordStyle.copyWith()` |
| `lyricStyle?.copyWith(height: 1.1)` | Variable incorrecta | `_effectiveTextStyle.copyWith()` |
| `runSpacing: 10.0` | Hardcodeado | `runSpacing: lineSpacing` |
| Falta TextAlign.right | Solo manejaba center/left | Añadido `→ WrapAlignment.end` |

**Lección aprendida:** Los archivos `obs.md` y `correcciones.md` son reportes de bugs escritos por el usuario. Las soluciones propuestas allí pueden contener errores. **Siempre deben pasar por revisión de @arqui antes de implementar.**

---

## 7. Agentes Involucrados

### Por fase

| Fase | Agentes | Rol |
|------|---------|-----|
| **Evaluación inicial** | @curie | Evaluó Wrap vs Stack vs RichText. Recomendó Wrap REFINED con per-stanza. |
| **Plan arquitectónico** | @arqui | Diseñó la arquitectura de 2 capas (core + UI), plan de implementación. |
| **Implementación core** | @dev | `chord_segment.dart`, `chord_parser.dart` (regex + parseChordProStanza), tests. |
| **Implementación UI** | @design | `responsive_chord_widget.dart`, integración en hymn_detail + live_projection. |
| **Revisión Fase 2** | @arqui | Encontró M1 (trailing blanks) y M2 (sin textAlign). Veredicto: aprobado condicional. |
| **Fix M1+M2** | @orquestador | Trim trailing newlines, textAlign param, tests adicionales. |
| **Evaluación Bug 2** | @curie | Detectó que split directo sobre parseChordProLine pierde segmentos vacíos. |
| **Plan Bug 2** | @arqui | Propuso `expandToWordSegments` como función separada (no modificar parseChordProLine). |
| **Fix expandToWordSegments** | @dev | Implementó la función + modificó parseChordProStanza + 6 tests. |
| **Fix Stack** | @design | Implementó Stack+Positioned para que acorde flote sin estirar. |
| **Revisión final** | @arqui | ✅ APROBADO. "Arquitecturalmente sólido, sin riesgo de regresión". |
| **Merge + builds** | @orquestador | Merge a main, APK local, Windows CI, contexto actualizado. |

### Flujo recomendado para futuros bugs

```
Usuario reporta bug en .md
  → @curie evalúa (causa raíz, riesgos)
  → @arqui crea plan (archivos, cambios exactos)
  → @dev implementa core / @design implementa UI
  → @arqui verifica post-implementación
  → @orquestador compila reporte, commit, build, merge
```

---

## 8. Archivos Legacy Eliminados

| Archivo | Líneas | Reemplazado por | Fecha |
|---------|--------|-----------------|-------|
| `lib/presentation/shared_widgets/chord_overlay_text.dart` | 162 | `responsive_chord_widget.dart` | 25 mayo |
| `lib/core/chords/chord_painter.dart` | 159 | Wrap nativo (no necesita medición) | 25 mayo |
| `lib/core/utils/stanza_layout_engine.dart` | 53 | Wrap nativo (no necesita layout engine) | 25 mayo |

**Total eliminado:** ~374 líneas de código legacy.

Los archivos legacy fueron eliminados en el commit `c55a964` después de verificar que no hubiera referencias residuales en `lib/` ni en `test/`.

---

## 9. Tests

### Estado actual: 45 tests, todos pasando

```
test/unit/core/chords/chord_parser_test.dart
  ├── parseChordProLine ........... 10 tests
  ├── stripChords .................. 3 tests
  ├── chordRegex ................... 9 tests
  ├── parseChordProStanza ......... 10 tests
  ├── expandToWordSegments ........ 6 tests
  └── ChordSegment modelo ......... 7 tests
```

### Cobertura de casos borde

| Grupo | Cubre |
|-------|-------|
| parseChordProLine | Vacío, sin acordes, 2 segmentos, trailing chord, adyacentes, texto previo, G/B, Am, G7, paréntesis |
| stripChords | Normal, sin acordes, vacío |
| chordRegex | Simple, sostenido, bemol, bajo, menor7, vacío, inválido H, paréntesis (b5), paréntesis+bajo |
| parseChordProStanza | 2 líneas, vacío, multilínea, trailing blank, múltiples trailing, leading blank, solo blanks, triple blank, paréntesis |
| expandToWordSegments | Línea simple, acorde sin texto, acordes adyacentes, texto pre-acorde, línea sin acordes, vacío |
| ChordSegment | == igual, == diferente chord, == diferente text, hashCode, toString (3 tests) |

### Cómo ejecutar

```bash
# Solo tests de acordes
flutter test test/unit/core/chords/chord_parser_test.dart

# Todos los tests
flutter test
```

---

## 10. Referencia Rápida

### Regex de acordes

```dart
const String chordPatternRaw =
  r'\[([A-G][#b]?[a-zA-Z0-9+#b()]*(?:/[A-G][#b]?)?)\]';
```

Soporta: `[G]`, `[Am]`, `[C#]`, `[Bb]`, `[Dm7]`, `[Gsus]`, `[Cdim]`, `[Caug]`,
`[C#m7(b5)]`, `[F#m7(b5)/B]`, `[G/B]`, `[Am/C]`

### Pipeline completo (de texto a pantalla)

```
1. ResponsiveChordWidget(stanza: chordProText)
2.   → parseChordProStanza(chordProText)
3.     → split('\n') → líneas
4.     → parseChordProLine(linea) → List<ChordLine>
5.     → expandToWordSegments(chordLines) → List<ChordSegment>
6.   → Wrap(children: [Column(Stack[...], Text[...]), ...])
```

### Parámetros del widget

```dart
ResponsiveChordWidget(
  stanza: String,                   // Texto ChordPro (obligatorio)
  textStyle: TextStyle?,            // Estilo de la letra
  chordStyle: TextStyle?,           // Estilo de los acordes
  lineSpacing: 8.0,                 // Espacio vertical entre líneas
  textAlign: TextAlign?,            // Alineación horizontal (null → left)
  runAlignment: WrapAlignment.start,// Alineación de runs en Wrap
  debug: false,                     // Modo depuración
)
```

### Comandos de build

```bash
# JDK 17 obligatorio
export JAVA_HOME=/home/melquisedec/jdk17
export PATH=$JAVA_HOME/bin:$PATH

# Tests
flutter test test/unit/core/chords/chord_parser_test.dart

# Análisis
flutter analyze lib/core/chords/ lib/presentation/shared_widgets/responsive_chord_widget.dart

# APK
./scripts/build_apk.sh
```

---

## 11. Archivos Relacionados (Raíz — Eliminados)

Los siguientes archivos en la raíz del proyecto documentaban bugs y revisiones durante el desarrollo del renderizador de acordes. Fueron **eliminados el 25 de mayo de 2026** por estar completamente obsoletos tras la creación de este documento consolidado (`doc/acordes.md`):

| Archivo | Contenido (histórico) |
|---------|----------------------|
| ~~`ac.md`~~ | Reporte de revisión de @arqui sobre la implementación inicial del Wrap. Hallazgos M1 y M2. |
| ~~`obs.md`~~ | Reporte de bug de desalineación y fractura de palabras. Fix con Stack+Positioned. |
| ~~`correcciones.md`~~ | Reporte de bug de Caja Ancha y Efecto Ladrillo. Fix con expandToWordSegments. |

> Su contenido completo está integrado en las secciones 6, 7 y 8 de este documento. Si encuentras referencias a estos archivos en commits anteriores (c55a964, 56aa50a, e114994), consulta `doc/acordes.md` para el contexto actualizado.

---

*Documento generado por @orquestador — 25 de mayo de 2026*
*Commits clave: `c55a964` (Wrap inicial), `56aa50a` (fix M1+M2), `e114994` (Stack+Word), `6dca680` (merge main)*
*Ramas: `feature/renderizador-acordes-responsive` → `main`*
