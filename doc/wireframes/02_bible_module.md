# Wireframe 02 — Módulo Biblia

> **Módulo:** Biblia (RV1909 + RV1569)
> **Archivos destino (Flutter):**
> - `lib/presentation/views_personal/bible/book_selector_screen.dart`
> - `lib/presentation/views_personal/bible/chapter_selector_screen.dart`
> - `lib/presentation/views_personal/bible/reader/reader_screen.dart`
> **Versión:** MQ App v1.0
> **Referencia:** `nuevaidea.md` §4.3, §4.4, §4.7 + revisiones v1.0–v1.4
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

Mostrar los capítulos del libro seleccionado en formato grid (no list, es más rápido).

## Layout (Génesis, 50 capítulos)

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

## Preguntas abiertas para el usuario

1. **¿El reader debe mostrar el versículo en contexto** (e.g., Génesis 1:1-3 juntos) o **estricto 1 versículo a la vez**? (Spec dice "1 versículo" — confirmado).
2. **¿El swipe horizontal debe incluir animación** o ser instantánea? (Sugerencia: 200ms ease-in-out).
3. **¿El botón `[aleat]` debe respetar favoritos/historial** o ser puramente aleatorio? (Sugerencia: puramente aleatorio — el modo aleatorio es para descubrimiento).
4. **¿El indicador de nota debe aparecer SIEMPRE** (con color "ninguno" = gris) o **solo si la nota tiene un color visible**? (Sugerencia: solo si tiene color visible, para no saturar visualmente).
5. **¿El modo fullscreen debe ocultar también la progress bar**? (Sugerencia: sí, fullscreen = 0 chrome).
6. **¿Soporte para "marcador" (bookmark) además de favorito?** No está en el spec — se sugiere NO incluir en v1.0 (los favoritos ya cubren esa necesidad).

---

*Wireframe creado por @design — pendiente revisión de @arqui y del usuario antes de implementar.*
