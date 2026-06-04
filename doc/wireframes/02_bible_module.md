# Wireframe 02 — Módulo Biblia

> **Módulo:** Biblia (RV1909; RV1569 eliminado en v1.0.1)
> **Archivos destino (Flutter):**
> - `lib/presentation/views_personal/bible/book_selector_screen.dart`
> - `lib/presentation/views_personal/bible/chapter_selector_screen.dart`
> - `lib/presentation/views_personal/bible/reader/reader_screen.dart`
> - `lib/features/biblia/presentation/widgets/verse_card.dart` (NUEVO v1.0.1)
> **Versión:** MQ App v1.0.1 (actualizado 2026-06-02 — sección 2d agregada)
> **Referencia:** `nuevaidea.md` §4.3, §4.4, §4.7 + revisiones v1.0–v1.4
> **Decisiones v1.0.1 aplicadas:** D1 (RV1569 eliminado), D4 (sin glassmorphism), D5 (snackbars 3s), D6 (vista capítulo)
> **Idioma:** Español (es-419)

---

## Visión general del módulo

El módulo Biblia tiene **3 pantallas secuenciales** + 2 pantallas auxiliares:

```
[Book selector] -> [Chapter grid] -> [Reader (1 versiculo a la vez)]
                                          |
                                          +-> [Note editor]   (modal)
                                          +-> [Favoritos]     (tab)
                                          +-> [Notas]         (tab)
```

**Decisión clave (heredada de HimnarioID 2.0):** El Reader muestra **1 versículo a la vez**, no un capítulo completo. Esto:
- Permite cambio rápido de versión sin perder el lugar.
- Facilita el modo presentación (1 versículo proyectado a la vez).
- Hace el swipe entre versículos natural.

---

# Pantalla 2a — Book Selector

## Propósito

Mostrar los 66 libros canónicos (39 AT + 27 NT) con navegación rápida por tabs.

## Layout

```
+------------------------------------------------------------------------------+
| <- Biblia                                                  [buscar]          |  <- AppBar
+------------------------------------------------------------------------------+
| [ AT ] [ NT ] [ ⭐ Favoritos ] [ 📝 Notas ] [ 🕐 Historial ]    <- tabs        |
+------------------------------------------------------------------------------+
|                                                                              |
|   +------------------------------------------------------------------------+ |
|   |  [01]  Genesis                            50 capitulos          [>]    | |
|   +------------------------------------------------------------------------+ |
|   |  [02]  Exodo                              40 capitulos          [>]    | |
|   +------------------------------------------------------------------------+ |
|   |  [03]  Levitico                           27 capitulos          [>]    | |
|   +------------------------------------------------------------------------+ |
|   |  [04]  Numeros                            36 capitulos          [>]    | |
|   +------------------------------------------------------------------------+ |
|   |  [05]  Deuteronomio                       34 capitulos          [>]    | |
|   +------------------------------------------------------------------------+ |
|   |  [06]  Josue                              24 capitulos          [>]    | |
|   +------------------------------------------------------------------------+ |
|   |  ...                                                                      |
|   |                                                                          |
+------------------------------------------------------------------------------+
```

## Elementos

| Elemento | Tipo | Comportamiento |
|---------|------|----------------|
| `<-` | Botón back | Pop a Home |
| Título "Biblia" | AppBar title (18sp) | Estático |
| `[buscar]` | Icono search | Tap → navega a `BibleSearchScreen` (búsqueda FTS5) |
| Tabs `AT/NT/Favoritos/Notas` | `TabBar` scrollable | Tab activo = underline gold. Default = AT al entrar. |
| Fila de libro | `ListTile` con glassmorphism | Tap → push `ChapterSelectorScreen(libroId)`. Long press = menú contextual: "Marcar como última lectura" / "Abrir al azar" |

## Tabs auxiliares

### `Favoritos` tab

```
+------------------------------------------------------------------------------+
|  Mis versiculos favoritos (124)                                              |
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  |  Jeremias 29:11                          RV1909              hace 2d     |  |
|  |  "Porque yo se los pensamientos..."                                [X]  |  |
|  +------------------------------------------------------------------------+  |
|  |  Salmos 23:1                             RV1909              hace 1sem  |  |
|  |  "Jehova es mi pastor; nada me faltara."                          [X]  |  |
|  +------------------------------------------------------------------------+  |
+------------------------------------------------------------------------------+
```

- Tap en la fila → push `ReaderScreen(libro, cap, vers)` en la versión del versículo.
- `[X]` = quita de favoritos (con confirmación: "¿Quitar de favoritos?").

### `Notas` tab

```
+------------------------------------------------------------------------------+
|  Mis notas personales (37)                                                   |
|                                                                              |
|  [yellow] [green] [blue] [todos]  <- filtro de color                          |
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  |  (yellow)  Juan 3:16                    RV1909          12 jun 2026      |  |
|  |  "Porque de tal manera amo Dios al mundo..."                            |  |
|  |  > Este versiculo me recuerda que el amor de Dios...                    |  |
|  +------------------------------------------------------------------------+  |
|  |  (blue)    Romanos 8:28                 RV1909          10 jun 2026      |  |
|  |  "Y sabemos que a los que a Dios aman..."                               |  |
|  |  > En los momentos difficiles, Dios obra...                             |  |
|  +------------------------------------------------------------------------+  |
+------------------------------------------------------------------------------+
```

- Cada nota muestra un **borde lateral del color** seleccionado (yellow/green/blue).
- Tap en la nota → push `ReaderScreen` Y abre el `NoteEditorModal` automáticamente.
- Filtro de color arriba (chips). "Todos" muestra todas las notas.

### `Historial` tab (sub-pantalla)

**Layout:**

```
+------------------------------------------------------------------------------+
|  <- Biblia                                                  [buscar]         |
+------------------------------------------------------------------------------+
|  [AT] [NT] [⭐ Favoritos] [📝 Notas] [🕐 Historial]               <- tabs     |
+------------------------------------------------------------------------------+
|                                                                              |
|  +------------------------------------------------------------------------+   |
|  |  🕐  Hace 5 minutos                                                     |   |
|  |  Genesis 1:1                                                            |   |
|  |  "En el principio creo Dios los cielos y la tierra..."                 |   |
|  |                                                            [RV1909 v]  |   |
|  +------------------------------------------------------------------------+   |
|                                                                              |
|  +------------------------------------------------------------------------+   |
|  |  🕐  Hace 1 hora                                                        |   |
|  |  Salmos 23:1                                                            |   |
|  |  "Jehova es mi pastor; nada me faltara."                               |   |
|  |                                                            [RV1909 v]  |   |
|  +------------------------------------------------------------------------+   |
|                                                                              |
|  (mas items agrupados por Hoy / Ayer / Esta semana / Este mes / Mas antiguo)|
|                                                                              |
+------------------------------------------------------------------------------+
```

**Empty state:**

```
+------------------------------------------------------------------------------+
|                                                                              |
|                                🕐                                            |
|                                                                              |
|                       Tu historial esta vacio                                |
|                                                                              |
|       Los versiculos que leas apareceran aqui.                                |
|                                                                              |
|                          [ Ir a la Biblia ]                                   |
|                                                                              |
+------------------------------------------------------------------------------+
```

**Comportamiento:**

- **Tap en item** → push `ReaderScreen(libro, cap, vers)` en la version guardada.
- **Long press** → menu contextual: `Eliminar` / `Marcar favorito` / `Agregar nota`.
- **Swipe left** en la card → elimina del historial (con confirmacion: "¿Eliminar del historial?").
- **Agrupado por secciones**: Hoy, Ayer, Esta semana, Este mes, Mas antiguo.
- **Ordenado** por `fecha_lectura DESC`, `LIMIT 100` registros (los mas antiguos se purgan automaticamente).
- **v1.0**: solo versiculos de Biblia (no incluye himnos ni devocionales — esos iran en modulos separados).
- **Estilo**: cards con **glassmorphism** (decision @arqui — coherente con Favoritos y Notas).
- **Persistencia automatica**: cada vez que el usuario abre un versiculo en el Reader, se inserta/actualiza un registro en `historial_versiculo` (upsert por `version_id + libro + cap + vers`).

**Database:** Tabla `historial_versiculo` en `assets/db/schema/001_biblia_schema.sql` (lineas 256-265).

## Estado vacío (sin favoritos / sin notas)

```
+------------------------------------------------------------------------------+
|  Mis versiculos favoritos                                                     |
|                                                                              |
|                          [icon-star-outline 64dp]                            |
|                                                                              |
|                       Aun no tienes favoritos                                 |
|                                                                              |
|       Marca versiculos con [star] para verlos aqui                           |
|       (puedes hacerlo desde el Reader o el versiculo del dia)                |
|                                                                              |
|                          [ Ir a la Biblia ]                                   |
+------------------------------------------------------------------------------+
```

## Buscador (FTS5)

Al tap en `[buscar]`:

```
+------------------------------------------------------------------------------+
| <- [  "amor"                      ]  [X]                          <- search   |
+------------------------------------------------------------------------------+
|  47 resultados para "amor"                                                    |
|                                                                              |
|  +------------------------------------------------------------------------+  |
|  |  Juan 3:16                                                               |  |
|  |  "Porque de tal manera **amo** Dios al mundo, que ha dado a su           |  |
|  |   Hijo unigenito..."                                                     |  |
|  +------------------------------------------------------------------------+  |
|  |  1 Corintios 13:4                                                         |  |
|  |  "El **amor** es sufrido, es benigno; el **amor** no tiene envidia..."  |  |
|  +------------------------------------------------------------------------+  |
|  |  1 Juan 4:8                                                              |  |
|  |  "El que no **ama**, no ha conocido a Dios; porque Dios es **amor**."    |  |
|  +------------------------------------------------------------------------+  |
+------------------------------------------------------------------------------+
```

- **Highlighting:** Los términos encontrados se muestran en **bold** dentro del texto del versículo.
- **Búsqueda acento-insensible:** Buscar "amor" encuentra "amor", "Amor", "AMOR" (FTS5 con `unicode61 remove_diacritics 2`).
- **Tap** en un resultado → push `ReaderScreen` con scroll al versículo.
- **Empty state** si no hay resultados: "No se encontraron versiculos para X".

---

# Pantalla 2b — Chapter Selector

## Propósito

Mostrar los capítulos del libro seleccionado en formato grid (no list, es más rápido). En v1.0.2 se agregó un **selector de versículo** (O5) que permite al usuario elegir un versículo específico antes de entrar al reader.

## Layout (Génesis, 50 capítulos) — v1.0.2

```
+------------------------------------------------------------------------------+
| <- Genesis                                                [buscar]           |
+------------------------------------------------------------------------------+
|                                                                              |
|   Selecciona un capitulo                                                      |
|                                                                              |
|   [📖] Versiculo:  [-] [  1  ] [+]                                            |
|                                                                              |
|   +---+---+---+---+---+      +---+---+---+---+---+                            |
|   | 1 | 2 | 3 | 4 | 5 |      | 26| 27| 28| 29| 30|                            |
|   +---+---+---+---+---+      +---+---+---+---+---+                            |
|   | 6 | 7 | 8 | 9 |10 |      | 31| 32| 33| 34| 35|                            |
|   +---+---+---+---+---+      +---+---+---+---+---+                            |
|   |11 |12 |13 |14 |15 |      | 36| 37| 38| 39| 40|                            |
|   +---+---+---+---+---+      +---+---+---+---+---+                            |
|   |16 |17 |18 |19 |20 |      | 41| 42| 43 |44 |45 |                          |
|   +---+---+---+---+---+      +---+---+---+---+---+                           |
|   |21 |22 |23 |24 |25 |      | 46| 47| 48| 49| 50|                            |
|   +---+---+---+---+---+      +---+---+---+---+---+                           |
|                                                                              |
|                            [ Capitulo aleatorio ]                             |
+------------------------------------------------------------------------------+
```

## Elementos — v1.0.2

| Elemento | Comportamiento | Notas |
|----------|----------------|-------|
| Selector de versículo | Row entre subtítulo y grid | NUEVO en v1.0.2 (O5) |
| `[-]` botón | Decrementa versículo (mín 1) | IconButton pequeño |
| TextField numérico | Ingreso manual del versículo | Teclado numérico, sin `0` inicial |
| `[+]` botón | Incrementa versículo (máx total del capítulo) | Validar contra `totalVersiculos` |
| Botón chapter (cuadrado 56x56dp) | Tap → push `ReaderScreen(libro, cap, **versiculo seleccionado**)` | Cambió de `1` hardcoded a versículo del selector |
| **Color de fondo del botón** | - **Blanco/gris** = no visitado. - **Gold claro** = visitado. - **Gold fuerte** = última lectura. | |
| `[buscar]` | Igual que en Book Selector. | |
| `[ Capitulo aleatorio ]` | Botón full-width outlined. Tap → push `ReaderScreen` con `Random.nextInt(numCapitulos) + 1` del libro actual y versículo 1. | |

## Selector de versículo (O5) — Detalle

### Decisión arquitectónica (DO4)

**NO se creó `VerseSelectorScreen` independiente**. Se integró un selector numérico en `ChapterGridScreen` por estas razones:
- Reusar `VerseCard`, `currentVerseProvider` y `_ChapterVerseList` scrollable ya implementados
- El auto-scroll existente (de `_ChapterVerseList` con `currentVerseProvider`) funciona sin código adicional
- Sin nueva ruta, sin nueva pantalla
- Cero duplicación de lógica de scroll

### Validación

- Si el campo está vacío → default 1
- Si el valor es inválido (no numérico, fuera de rango) → default 1
- Si el valor excede `totalVersiculos` del capítulo → mostrar error inline o cap al máximo
- Mínimo: 1, Máximo: `totalVersiculos` del capítulo seleccionado

### Reset behavior

- `didUpdateWidget` resetea el versículo a vacío cuando cambia `libroId`
- Esto evita que al cambiar de libro, el versículo quede fuera de rango

### Implementación

- `ChapterGridScreen` se convirtió de `ConsumerWidget` a `ConsumerStatefulWidget`
- Nuevo `_VerseNumberController` para el TextField
- Lógica extraída a `_navigateToChapter(int chapterNum)`

## Variantes

- **Libros con 1 capítulo** (e.g., Abdías, Judas): El grid muestra 1 sola celda, centrada. El selector de versículo sigue visible (puede ser útil para libros cortos).
- **Salmos (150 caps):** Grid de 5 columnas, scroll vertical. ~30 filas.

## Indicador "última lectura"

Al volver al Book Selector, la fila del último libro visitado muestra un dot gold al lado del nombre:

```
+------------------------------------------------------------------------+
|  [01]  Genesis  *  50 capitulos                              [>]      |  <- * = ultima lectura
+------------------------------------------------------------------------+
```
+------------------------------------------------------------------------------+
| <- Genesis                                                [buscar]           |
+------------------------------------------------------------------------------+
|                                                                              |
|   Selecciona un capitulo                                                      |
|                                                                              |
|   +---+---+---+---+---+      +---+---+---+---+---+                            |
|   | 1 | 2 | 3 | 4 | 5 |      | 26| 27| 28| 29| 30|                            |
|   +---+---+---+---+---+      +---+---+---+---+---+                            |
|   | 6 | 7 | 8 | 9 |10 |      | 31| 32| 33| 34| 35|                            |
|   +---+---+---+---+---+      +---+---+---+---+---+                            |
|   |11 |12 |13 |14 |15 |      | 36| 37| 38| 39| 40|                            |
|   +---+---+---+---+---+      +---+---+---+---+---+                            |
|   |16 |17 |18 |19 |20 |      | 41| 42| 43 |44 |45 |                          |
|   +---+---+---+---+---+      +---+---+---+---+---+                           |
|   |21 |22 |23 |24 |25 |      | 46| 47| 48| 49| 50|                            |
|   +---+---+---+---+---+      +---+---+---+---+---+                            |
|                                                                              |
|                            [ Capitulo aleatorio ]                             |
+------------------------------------------------------------------------------+
```

## Elementos

| Elemento | Comportamiento |
|----------|----------------|
| Botón chapter (cuadrado 56x56dp) | Tap → push `ReaderScreen(libro, cap, 1)`. |
| **Color de fondo del botón** | - **Blanco/gris** = no visitado. - **Gold claro** = visitado. - **Gold fuerte** = última lectura. |
| `[buscar]` | Igual que en Book Selector. |
| `[ Capitulo aleatorio ]` | Botón full-width outlined. Tap → push `ReaderScreen` con `Random.nextInt(numCapitulos) + 1` del libro actual. |

## Variantes

- **Libros con 1 capítulo** (e.g., Abdías, Judas): El grid muestra 1 sola celda, centrada.
- **Salmos (150 caps):** Grid de 5 columnas, scroll vertical. ~30 filas.

## Indicador "última lectura"

Al volver al Book Selector, la fila del último libro visitado muestra un dot gold al lado del nombre:

```
+------------------------------------------------------------------------+
|  [01]  Genesis  *  50 capitulos                              [>]      |  <- * = ultima lectura
+------------------------------------------------------------------------+
```

---

# Pantalla 2c — Reader (LA MÁS IMPORTANTE)

## Propósito

Mostrar **1 versículo a la vez** con todas las herramientas (favorito, nota, navegación, cambio de versión, fullscreen, random). Es la pantalla que el usuario pasa más tiempo usando.

## Layout (Portrait, móvil)

```
+------------------------------------------------------------------------------+
| <- Genesis            [RV1909 v]                          [buscar]  [...]   |
+------------------------------------------------------------------------------+
|                                                                              |
|   Capitulo 1                                                                  |
|                                                                              |
|   +------------------------------------------------------------------------+ |
|   |                                                                         | |
|   |  1   En el principio creo Dios los cielos y la tierra.        [yellow] | |  <- [yellow] = nota
|   |                                                                         | |
|   +------------------------------------------------------------------------+ |
|                                                                              |
|                                                                              |
|   [ >> Capitulo 2 ]                                                          |
|                                                                              |
+------------------------------------------------------------------------------+
|                                                                              |
|   [<<]    [<]              (1/31)              [>]    [>>]                    |
|                  [*]      [nota]      [aleat]                                 |
+------------------------------------------------------------------------------+
```

## Elementos — Header (AppBar)

| Elemento | Comportamiento |
|----------|----------------|
| `<-` | Pop al Chapter Selector. **Si hay cambios sin guardar (nota), confirma antes de salir.** |
| `Genesis` | Título (libro actual). Tap = NO navega (es informativo). |
| `[RV1909 v]` | **Dropdown de versión** — cambio rápido SIN salir del modo lectura (ver §4.7 del spec). Tap = bottom sheet con las 2 versiones. |
| `[buscar]` | Abre `BibleSearchScreen` (FTS5). |
| `[...]` | Menú overflow con: Compartir versículo, Tamaño de fuente, Ir a (libro/cap/vers), Modo presentación |

## Elementos — Cuerpo

| Elemento | Comportamiento |
|----------|----------------|
| `Capitulo 1` | Subtítulo (14sp, color secundario). |
| Card del versículo | - **Número** (24sp, bold, gold). - **Texto** (18sp, line-height 1.6). - **Indicador de nota** (cuadrado de color amarillo/verde/azul a la derecha). |
| `[>> Capitulo 2]` | Botón outlined abajo del versículo. Tap = siguiente capítulo. Si es el último capítulo del libro, dice "Siguiente libro: Exodo". |

## Elementos — Bottom Bar

```
+------------------------------------------------------------------------------+
|  [<<]    [<]              (1/31)              [>]    [>>]                    |
|                  [*]      [nota]      [aleat]                                 |
+------------------------------------------------------------------------------+
```

| Botón | Icono | Acción |
|-------|-------|--------|
| `[<<]` | `Icons.skip_previous_rounded` | Capítulo anterior. Si está en cap 1, va al último capítulo del libro anterior. |
| `[<]` | `Icons.chevron_left_rounded` | Versículo anterior. Al llegar al v.1, no hace nada (o muestra haptic feedback). |
| `(1/31)` | Indicador de posición | Muestra versículo actual / total del capítulo. **No es tappable** (es informativo). |
| `[>]` | `Icons.chevron_right_rounded` | Versículo siguiente. Al llegar al último, va al cap 1 del siguiente libro. |
| `[>>]` | `Icons.skip_next_rounded` | Capítulo siguiente. |
| `[*]` | `Icons.star_outline_rounded` / `star_rounded` | Toggle favorito. Si está marcado, muestra el ícono relleno. |
| `[nota]` | `Icons.edit_note_rounded` | Abre `NoteEditorModal` (ver §4.6 del spec). |
| `[aleat]` | `Icons.casino_rounded` | **🎲 Random verse** — salta a un versículo aleatorio del **mismo libro**. Mantiene el libro actual. |

## Gestos

| Gesto | Acción |
|-------|--------|
| **Swipe ←** (derecha → izquierda) | Siguiente versículo (igual que `[>]`). |
| **Swipe →** (izquierda → derecha) | Versículo anterior (igual que `[<]`). |
| **Long press** en el versículo | Abre menú contextual: Copiar / Compartir / Agregar nota / Ir al capítulo completo. |
| **Doble tap** en el versículo | Toggle favorito (atajo). |
| **Pinch zoom** | (futuro) Cambia el tamaño de fuente temporalmente. |

## Cambio rápido de versión (§4.7)

Al tap en `[RV1909 v]`:

```
+----------------------------------------------------------------------------+
|                                                                            |
|   +------------------------------------------------------------------------+|
|   |   Seleccionar version                                                    ||
|   |                                                                          ||
|   |   [check]  Reina Valera 1909                              <- actual     ||
|   |   [   ]   Reina Valera 1569 (Biblia del Oso)                            ||
|   |                                                                          ||
|   +------------------------------------------------------------------------+|
|                                                                            |
|   "Al cambiar, el versiculo actual (Genesis 1:1) se mantiene."             |
|                                                                            |
+----------------------------------------------------------------------------+
```

- **Misma referencia** (libro, cap, vers) se mantiene al cambiar.
- El **dropdown de la appbar** se actualiza inmediatamente.
- La preferencia se guarda en `Configuracion` (`biblia.version_preferida`).
- Si la referencia **no existe** en la otra versión (improbable pero posible en RV1569), muestra toast: "Esta referencia no esta disponible en RV1569".

## Estados

### Estado: Versículo con nota (indicador de color)

```
+------------------------------------------------------------------------+
|                                                                         |
|  5   Y fue la luz                                                       |
|                                                                         |
|                                            [yellow]   <- border lateral |
+------------------------------------------------------------------------+
```

- El color del borde lateral de la card **indica el color de la nota** (yellow/green/blue/none).
- Tap en el indicador = abre el editor de nota (atajo).
- Si el versículo NO tiene nota → no aparece el indicador.

### Estado: Sin versículos (libro vacío — no debería pasar, pero)

```
+------------------------------------------------------------------------------+
|                                                                              |
|                          [icon-empty-book 64dp]                              |
|                                                                              |
|                       Este libro no tiene versiculos                          |
|                                                                              |
+------------------------------------------------------------------------------+
```

### Estado: Cambiando de versión (loading)

```
+------------------------------------------------------------------------------+
|                                                                              |
|   +------------------------------------------------------------------------+ |
|   |                                                                         | |
|   |  1   [ spinner ~~~~~ ]   <- carga versiculo en RV1569                  | |
|   |                                                                         | |
|   +------------------------------------------------------------------------+ |
|                                                                              |
+------------------------------------------------------------------------------+
```

- Skeleton text mientras carga. < 100ms en caché; < 500ms en cold fetch.

### Estado: Fullscreen (modo lectura pura)

```
+------------------------------------------------------------------------------+
|                                                                              |
|                                                                              |
|   1                                                                          |
|   En el principio creo Dios los cielos y la tierra.                          |
|                                                                              |
|                                                                              |
|                                                                              |
|                                                                              |
|   Genesis 1:1   RV1909                                                       |
+------------------------------------------------------------------------------+
```

- Tap en el botón `[exit-fullscreen]` (esquina superior) o presiona back → vuelve al reader normal.
- **Ideal para lectura nocturna o sesiones largas.** Sin chrome, sin distracciones.
- **El swipe sigue funcionando** en fullscreen.

### Estado: Menú overflow (`[...]`)

```
+----------------------------------------------------------------------------+
|   <- Compartir versiculo                                                    |
|                                                                            |
|   Compartir como:                                                           |
|   [icon-text] Solo texto                                                    |
|   [icon-image] Imagen (con fondo)                                           |
|                                                                            |
|   [X] Cancelar                                                              |
+----------------------------------------------------------------------------+
```

Opciones del menú:
1. **Compartir versículo** → sistema de share del SO (texto plano + referencia).
2. **Tamaño de fuente** → slider 12sp–32sp.
3. **Ir a** → input "Libro Cap:Vers" (e.g., "Juan 3:16") con autocompletar.
4. **Modo presentación** → push `BiblePresentationScreen` (proyecta el capítulo).

## Editor de notas (modal)

```
+----------------------------------------------------------------------------+
|                                                                            |
|   Genesis 1:1                                              [X]              |  <- header
|   "En el principio creo Dios los cielos y la tierra."                      |
|                                                                            |
|   ---- Mi nota ----                                                         |
|   +------------------------------------------------------------------------+|
|   |                                                                          ||
|   |  La creacion como acto divino de orden...                                ||
|   |                                                                          ||
|   |                                                                          ||
|   +------------------------------------------------------------------------+|
|                                                                            |
|   Color:  [gris]  [yellow]  [green]  [blue]                                 |
|                                                                            |
|                                       [Eliminar]      [Guardar]             |
+----------------------------------------------------------------------------+
```

- **Editor multi-línea** (crece hasta 8 líneas visibles, luego scroll interno).
- **Selector de color** con 4 opciones (incluyendo "ninguno" = gris).
- **[Eliminar]** solo aparece si ya existe una nota.
- **[Guardar]** persiste a la tabla `nota` y cierra el modal.
- La card del versículo se actualiza con el color del borde en tiempo real.

## Indicador de progreso de capítulo

Una barra de progreso **sutil** en la parte superior (debajo del AppBar) muestra cuánto del capítulo se ha visto:

```
+------------------------------------------------------------------------------+
| <- Genesis            [RV1909 v]                          [buscar]  [...]   |
+------------------------------------------------------------------------------+
| ====================                                    <- 4/31 (12%)     |  <- progress
+------------------------------------------------------------------------------+
|                                                                              |
|   ...                                                                          |
```

- **Color:** gold con opacidad 50%.
- **NO es scrubbable** (no se puede tap para saltar).
- Se actualiza al cambiar de versículo.
- Se resetea al cambiar de capítulo o de libro.

---

## Responsive — Tablet y Desktop

### Tablet (≥ 600dp)

- **Layout 2 columnas:**
  - Izquierda (40%): Lista de versículos del capítulo (scroll independiente). Versículo actual = highlight gold.
  - Derecha (60%): Versículo actual con texto grande.
- **Bottom bar** se mueve a la **derecha** como sidebar vertical.
- **Tap en un versículo de la lista** = salta a ese versículo.

```
+------------------------------------------------------------------------------+
| <- Genesis 1              [RV1909 v]                       [buscar]  [...]   |
+------------------------------------------------------------------------------+
| Lista de versiculos          |  Versiculo actual                              |
| ----------------------       |  ----------------------                        |
| 1.  En el principio...      |   7   Y fue la luz                              |
| 2.  Y la tierra estaba...   |                                                |
| 3.  Y dijo Dios: Sea...     |   "Y vio Dios que la luz era buena; y              |
| 4.  Y vio Dios que la...    |    separo la luz de las tinieblas."               |
| 5.  Y fue la luz...  <- ACT |                                                |
| 6.  Y vio Dios que era...   |   [yellow] <- tiene nota                         |
| 7.  Y fue la luz...         |                                                |
| ...                         |   [>> Capitulo 2]                               |
+------------------------------------------------------------------------------+
```

### Desktop (≥ 1024dp)

- Igual que tablet, pero la lista de versículos es **ancha completa** (60/40 invertido, lista a la derecha).
- La barra de navegación superior e inferior se **compactan** en un solo sidebar de iconos.
- **Atajos de teclado:**
  - `←` `→`: versículo anterior/siguiente
  - `↑` `↓`: versículo +/- 5
  - `Space`: siguiente versículo
  - `F`: toggle favorito
  - `N`: nueva nota
  - `Esc`: salir de fullscreen

---

## Accesibilidad (WCAG 2.1 AA)

| Criterio | Implementación |
|----------|----------------|
| Lectura por screen reader | Cada versículo tiene `Semantics` con: número, texto, referencia, indicador de nota ("tiene nota amarilla"), estado de favorito. |
| Navegación por teclado (desktop) | Ver atajos arriba. Tab cycle: header → botones del versículo → bottom bar. |
| Contraste | Texto del versículo: `onSurface` (≥ 7:1). Número: `primary` gold (≥ 4.5:1 sobre fondo). |
| Tamaño de fuente | Slider en menú overflow (12sp–32sp). Persiste en `Configuracion`. |
| Haptic feedback | Vibración sutil al cambiar de versículo (toggle en settings). |
| Touch targets | Todos los botones del bottom bar ≥ 48x48dp. |

---

# Pantalla 2d — Bible Reader: Vista de Capítulo Completo (NUEVA v1.0.1)

> **Versión:** v1.0.1 | Agregado: 2026-06-02 | Por: @design
> **Estado:** ✅ Nueva vista alternativa (decisión D6 de `CONTROL/DECISIONES.md`)
> **Origen:** F2 de `CONTROL/PENDIENTE.md` + observación #9 del usuario en `BITACORA.md`
> **Archivo destino (Flutter):** `lib/features/biblia/presentation/screens/bible_reader_screen.dart` (refactor a stateful)
> **Dependencia nueva:** `scrollable_positioned_list: ^0.3.8`

## Propósito

Ofrecer una **vista alternativa** al Reader "1 versículo a la vez" (modo `verse`) para usuarios que prefieren **leer todo el capítulo de un vistazo** (modo `chapter`). Toggle en AppBar, persistente solo en la sesión (NO en BD).

Inspiración: YouVersion, Bible Gateway, Olive Tree — apps líderes permiten alternar entre estas dos vistas con preferencia del usuario.

---

## Vista (Portrait, móvil, modo capítulo)

```
+------------------------------------------------------------------------------+
|  <-  Genesis 3            [list]                              [...]   [menu] |  <- AppBar
|                                                  (toggle: view_headline icon)|
+------------------------------------------------------------------------------+
|                                                                              |
|   [tag] Capitulo 3                                                           |  <- subtítulo goldDark
|                                                                              |
|   +----------------------------------------------------------------------+   |
|   |  1  Y la serpiente era mas astuta que todos los animales            |   |  <- versículo 1 (default)
|   |     de campo que Jehova Dios habia hecho...                         |   |
|   +----------------------------------------------------------------------+   |
|                                                                              |
|   +----------------------------------------------------------------------+   |
|   |  2  Y esta dijo a la mujer: ¿Conque Dios os ha dicho: No            |   |  <- versículo 2
|   |     comais de todo arbol del huerto?                                |   |
|   +----------------------------------------------------------------------+   |
|                                                                              |
|   +----------------------------------------------------------------------+   |
|   |  3  Y la mujer respondio a la serpiente: Del fruto                  |   |  <- versículo 3 (no foco)
|   |     de los arboles del huerto podemos comer;                        |   |
|   +----------------------------------------------------------------------+   |
|                                                                              |
|   +----------------------------------------------------------------------+   |
|   |  4  Entonces la serpiente dijo a la mujer: No morireis;             |   |  <- versículo 4 (no foco)
|   |     porque Dios sabe que...                                         |   |
|   +----------------------------------------------------------------------+   |
|                                                                              |
|   ...                                                                        |
|                                                                              |
|   +----------------------------------------------------------------------+   |
|   |  15  Y pondré enemistad entre ti y la mujer, y entre tu             |   |  <- versículo 15 (no foco)
|   |      simiente y la simiente suya...  [yellow: indicador nota]       |   |
|   +----------------------------------------------------------------------+   |
|                                                                              |
+------------------------------------------------------------------------------+
|  [tag]   RV1909                                                              |  <- footer de versión
+------------------------------------------------------------------------------+
```

### Versículo foco (highlight sutil)

```
+----------------------------------------------------------------------+
|  5  Porque Dios sabe que...                                 [FOCO]  |  <- fondo surfaceContainerHigh
|     el dia que comiereis de el...                                  |     elevación 1
+----------------------------------------------------------------------+
```

El versículo donde el usuario **estaba leyendo** (en modo `verse`) se marca con un fondo `surfaceContainerHigh` y elevación sutil. Sirve como **ancla visual** al cambiar de modo.

---

## Vista (Portrait, móvil, modo verso - default al abrir)

El modo verso (existente, sin cambios estructurales) se muestra en la sección anterior "Pantalla 2c — Reader".

El toggle en la app bar cambia entre ambos modos. **El estado NO persiste** entre sesiones (decisión D6) — siempre abre en modo `verse`.

---

## AppBar — Toggle y Menú

```
+------------------------------------------------------------------------------+
|  <-  Genesis 3                  [list]                      [...]   [more] |
+------------------------------------------------------------------------------+
```

| Elemento | Icono | Acción |
|----------|-------|--------|
| `<-` | `arrow_back_rounded` | Pop al Chapter Selector (con confirm si nota sin guardar) |
| Título "Genesis 3" | Texto (book + cap) | Estático, informativo |
| **Toggle de modo** | `view_headline_rounded` (modo verse, default) ↔ `view_agenda_outline_rounded` (modo chapter) | Tap = `setState(() => _viewMode = _viewMode.toggle())` + auto-scroll al versículo foco |
| `[buscar]` | `search_rounded` | Abre `BibleSearchScreen` (FTS5) |
| `[more]` | `more_vert_rounded` | Overflow menu (compartir, tamaño fuente, ir a, fullscreen) — mismo que modo verso |

### Comportamiento del toggle

```dart
enum ReaderViewMode { verse, chapter }

extension on ReaderViewMode {
  ReaderViewMode get toggle =>
      this == ReaderViewMode.verse
          ? ReaderViewMode.chapter
          : ReaderViewMode.verse;
}

// En el IconButton:
onPressed: () {
  setState(() => _viewMode = _viewMode.toggle());
  if (_viewMode == ReaderViewMode.chapter) {
    // Auto-scroll al versículo foco después del build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollableListController.scrollToIndex(
        index: _currentVerse - 1,
        duration: Duration(milliseconds: 300),
      );
    });
  }
}
```

### Menú 3 puntos (overflow) — Diferencia vs compact/preview

> **Importante:** este menú 3 puntos es **distinto** del modo compact/preview del emisor (wireframe 03). Es un menú propio del reader, no relacionado con proyección.

| Opción | Acción |
|--------|--------|
| Compartir versículo | Comparte el versículo **foco** actual (no el capítulo) |
| Tamaño de fuente | Slider 12sp–32sp (afecta AMBOS modos) |
| Ir a | Input "Libro Cap:Vers" con autocompletar |
| Modo fullscreen | Oculta chrome (AppBar + bottom bar) — funciona en modo chapter también |
| Cambiar a modo presentación | Solo si emisor está conectado |

---

## Vista verso ↔ capítulo — Layout por versículo

Cada versículo es un `VerseCard` (widget compartido) que se muestra en AMBOS modos. Cambia solo el contenedor:

| Aspecto | Modo verse (1 a la vez) | Modo chapter (lista) |
|---------|------------------------|---------------------|
| Contenedor | `PageView` horizontal (swipe) | `ScrollablePositionedList` vertical |
| Visibilidad | 1 versículo visible a la vez | Todos los versículos del capítulo |
| Versículo foco | Centrado, con `AnimatedScale` 1.0 | Marcado con fondo `surfaceContainerHigh` |
| Bottom bar | Visible (navegación versículo a versículo) | **Oculto** (navegación es el scroll) |
| Tamaño del texto | bodyLarge 18sp | bodyLarge 18sp (igual) |
| Padding horizontal | 16dp | 16dp |
| Padding vertical | 24dp | 12dp entre versículos |

---

## VerseCard — Componente compartido

```
+----------------------------------------------------------------------+
|                                                                      |
|  [N]    Texto del versículo. Continua con mas texto si es largo      |
|         hasta ocupar varias lineas con line-height 1.6.              |
|                                                                      |
|  [N] = numero (displaySmall 36sp, 700, gold, align right, 40dp wide)|
|                                                                      |
|  [border-lateral 4dp] = color de nota (yellow/green/blue/none)      |
|                                                                      |
+----------------------------------------------------------------------+
```

| Propiedad | Valor |
|-----------|-------|
| Layout | `Row` con número a la izquierda (40dp ancho, align top) + texto expandido |
| Número | `displaySmall` 36sp, 700, `goldPrimary` (#CCA43B), right-aligned |
| Texto | `bodyLarge` 18sp, `onSurface`, line-height 1.6 |
| Padding interno | 16dp horizontal, 12dp vertical |
| Border lateral | 4dp ancho, color de nota, full height |
| Fondo (foco) | `surfaceContainerHigh` con elevación 1 |
| Fondo (no foco) | `surface` plano (sin elevación) |
| Border radius | 12dp (no glassmorphism) |
| Margin | 4dp vertical entre cards |

### Detección de "foco"

- **Verso:** `currentVerse` (1-indexed) del provider
- **Capítulo:** mismo `currentVerse`; la card con `verse.number == currentVerse` se renderiza con fondo foco

### Animación de cambio de foco

```dart
AnimatedContainer(
  duration: Duration(milliseconds: 200),
  decoration: BoxDecoration(
    color: isFocused 
        ? cs.surfaceContainerHigh 
        : cs.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border(
      left: BorderSide(
        color: noteColor ?? Colors.transparent,
        width: 4,
      ),
    ),
  ),
  child: VerseCard(...),
)
```

---

## BottomSheet contextual (tap en versículo)

Al tap en un versículo (modo capítulo), se actualiza `currentVerseProvider` y se muestra un menú contextual pequeño:

```
+----------------------------------------------------------------+
|                                                                |
|   [star]  Agregar a favoritos                                  |
|   [note]  Crear/editar nota                                    |
|   [share] Compartir                                            |
|                                                                |
+----------------------------------------------------------------+
```

> **Decisión:** usar `showModalBottomSheet` con 3 opciones, no snackbar action. Es más descubrible y sigue el patrón Material 3.

### Long press (alternativa)

Long press en el versículo → mismo bottom sheet (alternativa para usuarios con tap rápido accidental).

### SnackBar de "Agregado a favoritos" (post-bottomSheet)

Al tap en "Agregar a favoritos":

```
+----------------------------------------------------------------+
| [✓] Agregado a favoritos                  Deshacer             |  <- SnackBar
+----------------------------------------------------------------+
```

- **Duración:** 3 segundos (auto-dismiss, decisión D5)
- **Anti-stacking:** `hideCurrentSnackBar()` + `clearSnackBars()` antes de mostrar (helper `AppSnackBar.show()`)
- **Acción "Deshacer":** quita el favorito y muestra snackbar "Quitado de favoritos" + Deshacer

---

## Auto-scroll al versículo foco

Al cambiar a modo `chapter` desde modo `verse` (o al abrir el reader en modo chapter), la lista **scrollea automáticamente** al versículo donde estaba el usuario.

### Implementación con `scrollable_positioned_list`

```dart
ScrollablePositionedList.builder(
  itemScrollController: _scrollableController,
  itemCount: chapter.verses.length,
  itemBuilder: (context, index) {
    final verse = chapter.verses[index];
    final isFocused = verse.number == _currentVerse;
    return VerseCard(
      verse: verse,
      isFocused: isFocused,
      noteColor: notes[verse.id]?.color,
      onTap: () => _onVerseTap(verse),
      onLongPress: () => _showVerseMenu(verse),
    );
  },
)

// Al cambiar de modo o versículo:
_scrollableController.scrollToIndex(
  index: _currentVerse - 1,  // 0-indexed
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOutCubic,
);
```

### Casos edge

- **Salmos 119 (176 versículos):** `ScrollablePositionedList` lo maneja sin lag (lazy build).
- **Capítulos con 1 versículo** (raros): no hay scroll, vista simple.
- **Cambio rápido verso→capítulo→verso:** preservar el versículo foco, no resetear.

---

## Persistencia del versículo foco

- **NO se persiste el modo de vista** (decisión D6) — siempre abre en `verse`.
- **SÍ se persiste el `currentVerse`** (dentro de la sesión) — el provider `currentVerseProvider` lo mantiene.
- Al cambiar de capítulo (botón `>>` o swipe), `currentVerse` se resetea a 1.

---

## Estados

### Estado: Capítulo vacío (no debería pasar)

```
+----------------------------------------------------------------+
|                                                                |
|                        [book 64dp]                             |
|                                                                |
|               Este capitulo no tiene versiculos                |
|                                                                |
+----------------------------------------------------------------+
```

### Estado: Cambiando de modo (transición)

```
+----------------------------------------------------------------+
|                                                                |
|   [verse 1]  <- fade out 150ms                                  |
|                                                                |
|   [chapter list]  <- fade in 150ms + scroll al foco 300ms     |
|                                                                |
+----------------------------------------------------------------+
```

Animación combinada: crossfade del contenido + scroll programático.

---

## Elementos

| Elemento | Tipo | Posición | Acción |
|----------|------|----------|--------|
| AppBar leading `<-` | IconButton | Top-left | Pop (con confirm si nota sin guardar) |
| AppBar título | Text "Genesis 3" | Top-center | Estático |
| Toggle de modo | IconButton `view_headline` / `view_agenda_outline` | AppBar actions[0] | Cambia `viewMode` + auto-scroll |
| `[buscar]` | IconButton | AppBar actions[1] | Abre `BibleSearchScreen` |
| `[more]` | PopupMenuButton | AppBar actions[2] | Menú overflow |
| Subtítulo "Capitulo N" | Text bodyMedium goldDark | Padding 16dp top | Estático (solo en modo chapter) |
| VerseCard | Widget compartido | Body (lista) | Tap = foco + bottomSheet |
| FAB contextual (modo verse) | Existente (sin cambios) | Bottom-right | Favorito/nota/random |
| Footer versión | Text caption | Bottom | "RV1909" |
| SnackBar | Helper `AppSnackBar.show()` | Bottom (temporal) | Feedback de favorito (3s) |

---

## Componentes reutilizados

- **`VerseCard`** (nuevo widget) — `lib/features/biblia/presentation/widgets/verse_card.dart`
  - Usado en modo verse (1 a la vez) y modo chapter (lista)
  - Maneja el foco, el indicador de nota, el tap y el long press
- **`ScrollablePositionedList`** (nueva dependencia) — `scrollable_positioned_list: ^0.3.8`
  - Solo en modo chapter
  - Reemplaza al `ListView.builder` plano
- **`AppSnackBar`** (helper de D5) — feedback de favorito con 3s auto-dismiss
- **`NoteEditorModal`** (existente) — abre desde bottom sheet contextual
- **Sin glassmorphism** (D4/D14) — usar `Card` Material 3 con elevación 1, no `GlassContainer`

---

## Notas de implementación

### Estructura del widget

```dart
class BibleReaderScreen extends ConsumerStatefulWidget {
  // Stateful porque tiene _viewMode y _scrollableController
}

class _BibleReaderScreenState extends ConsumerState<BibleReaderScreen> {
  late ReaderViewMode _viewMode = ReaderViewMode.verse;  // default verso
  late ItemScrollController _scrollableController;
  
  // currentVerse viene del provider:
  // final currentVerse = ref.watch(currentVerseProvider);
  
  @override
  void initState() {
    super.initState();
    _scrollableController = ItemScrollController();
  }
  
  Widget _buildChapterView(List<Verse> verses) {
    return ScrollablePositionedList.builder(
      itemScrollController: _scrollableController,
      itemCount: verses.length,
      itemBuilder: (ctx, i) => VerseCard(
        verse: verses[i],
        isFocused: verses[i].number == ref.read(currentVerseProvider),
        onTap: () => _onVerseTap(verses[i]),
        onLongPress: () => _showVerseMenu(verses[i]),
      ),
    );
  }
  
  Widget _buildVerseView(List<Verse> verses) {
    // PageView horizontal (existente)
  }
  
  @override
  Widget build(BuildContext context) {
    final verses = ref.watch(chapterVersesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('${book.name} $chapter'),
        actions: [
          IconButton(
            icon: Icon(_viewMode == ReaderViewMode.verse
                ? Icons.view_agenda_outline_rounded
                : Icons.view_headline_rounded),
            onPressed: _toggleViewMode,
          ),
          // ... buscar, more
        ],
      ),
      body: _viewMode == ReaderViewMode.verse
          ? _buildVerseView(verses)
          : _buildChapterView(verses),
    );
  }
}
```

### Providers nuevos

```dart
// lib/features/biblia/application/providers/reader_providers.dart

final readerViewModeProvider = StateProvider<ReaderViewMode>(
  (ref) => ReaderViewMode.verse,
);

final currentVerseProvider = StateProvider<int>(
  (ref) => 1,  // default: versículo 1
);
```

> **Decisión:** `currentVerseProvider` es **transitorio** (en memoria), no persiste entre sesiones. La "última lectura" se persiste vía el repositorio de historial (ya existe).

### Comportamiento del bottomSheet contextual

```dart
void _showVerseMenu(Verse verse) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.star_outline_rounded),
            title: Text('Agregar a favoritos'),
            onTap: () async {
              Navigator.pop(ctx);
              await ref.read(favoritoRepositoryProvider).toggle(verse);
              AppSnackBar.show(context, 'Agregado a favoritos',
                action: SnackBarAction(label: 'Deshacer', onPressed: () { ... }),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.edit_note_rounded),
            title: Text('Crear/editar nota'),
            onTap: () {
              Navigator.pop(ctx);
              showNoteEditorModal(context, verse: verse);
            },
          ),
          ListTile(
            leading: Icon(Icons.share_rounded),
            title: Text('Compartir'),
            onTap: () {
              Navigator.pop(ctx);
              Share.share('${verse.text}\n— ${verse.reference} (RV1909)');
            },
          ),
        ],
      ),
    ),
  );
}
```

---

## Responsive

### Tablet (≥ 600dp)

- **Layout 2 columnas en modo chapter** (mismo patrón que wireframe 02 §7 para verse):
  - Izquierda (40%): lista de versículos con scroll
  - Derecha (60%): versículo foco con texto grande y notas
- El toggle se mantiene en AppBar.

### Desktop (≥ 1024dp)

- Modo chapter siempre en 2 columnas.
- Atajos de teclado:
  - `J` / `K`: siguiente/anterior versículo (cambia foco)
  - `V`: toggle verso/capítulo
  - `F`: toggle favorito del versículo foco
  - `N`: nueva nota del versículo foco
  - `Space`: scroll page down (modo chapter)

---

## Accesibilidad (WCAG 2.1 AA)

| Criterio | Implementación |
|----------|----------------|
| Screen reader | Cada `VerseCard` con `Semantics(label: 'Versículo 5, [texto], referencia Génesis 3:5, [tiene nota amarilla]')` |
| Contraste número | `goldPrimary` (#CCA43B) sobre `surface` cumple AA para texto ≥18pt (36sp ✓) |
| Contraste texto | `onSurface` sobre `surfaceContainerHigh` (foco) y `surface` (no foco): ambos ≥ 7:1 |
| Touch target | Cada `VerseCard` es tappable (toda la card), no solo el número |
| Focus visible (desktop) | Outline 2px gold en el versículo foco |
| Reduced motion | Auto-scroll respeta `prefers-reduced-motion` (duración 0 si está activo) |
| Font scaling | `MediaQuery.textScaler` aplicado al texto del versículo |

---

## Cambios vs versión anterior

- **Nuevo toggle en AppBar** (`view_headline` ↔ `view_agenda_outline`) que cambia entre modo verse y modo chapter.
- **`BibleReaderScreen` refactorizado a `StatefulWidget`** con `_viewMode` local.
- **Nuevo widget `VerseCard`** compartido entre ambos modos.
- **Nueva dependencia `scrollable_positioned_list`** para el modo chapter.
- **Bottom bar de navegación oculto en modo chapter** (la navegación es el scroll).
- **Nuevo `bottomSheet` contextual** al tap en versículo (favorito, nota, compartir).
- **No se persiste el modo de vista** entre sesiones.
- **NO glassmorphism** (D4): cards sólidos con elevación 1, fondo `surfaceContainerHigh` solo en el versículo foco.

---

## Preguntas abiertas

1. **¿La Snackbar de "Agregado a favoritos" debe mostrar también "Ver favoritos"** como segunda acción? (Estilo Material 3 idiom). Sugerencia: NO, mantener simple (solo "Deshacer").

2. **¿El modo chapter debe permitir marcar múltiples versículos como favoritos a la vez** (selección múltiple)? Útil para marcar rangos (e.g., "Salmos 23:1-6 todos favoritos"). Sugerencia: NO en v1.0.1, NICE TO HAVE.

3. **¿El bottomSheet contextual debe incluir "Ir al versículo"** (para modo chapter, saltar a ese versículo en modo verse)? Sugerencia: NO — el cambio de modo ya se hace con el toggle del AppBar.

4. **¿Soporte para "compartir rango"** (e.g., "Génesis 3:1-5" en una sola acción)? Útil para compartir en WhatsApp. Sugerencia: NO en v1.0.1, NICE TO HAVE.

5. **El usuario mencionó "Merriweather 16sp" para el texto del versículo.** El style guide LOCKED dice `bodyLarge = 18sp` y "No se carga ninguna fuente custom en v1.0" (Merriweather es custom). **Conflicto:** usar `bodyLarge` 18sp del sistema en v1.0.1 (lock del style guide) y evaluar Merriweather en v1.1+.

6. **El usuario mencionó `gold #D4A574` para el número de versículo.** El style guide LOCKED dice `goldPrimary = #CCA43B`. **Conflicto:** usar #CCA43B (lock) por consistencia.

7. **¿El toggle debe mostrar el icono del MODO AL QUE VA A CAMBIAR** (preview) o del MODO ACTUAL? Sugerencia: mostrar el icono del MODO ACTUAL (consistente con el patrón Material 3).

8. **¿El `currentVerseProvider` debe persistir en BD** junto con la última lectura? Sugerencia: NO — ya existe el sistema de historial (`historial_versiculo`) que cubre esa necesidad.

---

*Sección agregada por @design para v1.0.1 — pendiente revisión de @arqui. Decisiones D4 (quitar glassmorphism), D5 (snackbars centralizados) y D6 (modo capítulo) ya incorporadas.*

---

## Preguntas abiertas para el usuario

1. **¿El reader debe mostrar el versículo en contexto** (e.g., Génesis 1:1-3 juntos) o **estricto 1 versículo a la vez**? (Spec dice "1 versículo" — confirmado).
2. **¿El swipe horizontal debe incluir animación** o ser instantánea? (Sugerencia: 200ms ease-in-out).
3. **¿El botón `[aleat]` debe respetar favoritos/historial** o ser puramente aleatorio? (Sugerencia: puramente aleatorio — el modo aleatorio es para descubrimiento).
4. **¿El indicador de nota debe aparecer SIEMPRE** (con color "ninguno" = gris) o **solo si la nota tiene un color visible**? (Sugerencia: solo si tiene color visible, para no saturar visualmente).
5. **¿El modo fullscreen debe ocultar también la progress bar**? (Sugerencia: sí, fullscreen = 0 chrome).
6. **¿Soporte para "marcador" (bookmark) además de favorito?** No está en el spec — se sugiere NO incluir en v1.0 (los favoritos ya cubren esa necesidad).

---

*Wireframe creado por @design — pendiente revisión de @arqui y del usuario antes de implementar.*
