# Wireframe 05 — Guía de Estilo (MQ App v1.0)

> **Propósito:** Definir tokens visuales (colores, tipografía, espaciado, componentes) para las nuevas pantallas de MQ App.
> **Audiencia:** @dev (implementador), @arqui (revisor técnico)
> **Versión:** v1.0
> **Referencia:** Especificaciones previas en `doc/especificaciones-diseno.md` + `doc/GLASSMORPHISM.md` (HimnarioID 2.0) + `nuevaidea.md`

---

## ✅ Resolución del conflicto de paleta (DECIDIDO 1 jun 2026)

> **Estado:** RESUELTO. Ver §1.0 y tabla de decisiones de @arqui al final del documento.
> Esta sección se conserva como contexto histórico del proceso de decisión.

Las instrucciones del orquestador especifican una paleta con **azul profundo + gold** para MQ App. Sin embargo, **el proyecto HimnarioID 2.0 (del cual MQ App es un fork) ya tiene una paleta establecida: gold/negro/blanco**.

### Opción A — Adoptar la paleta del spec (Deep blue + Gold)

| Token | Hex | Justificación |
|-------|-----|---------------|
| Primary | `#1A365D` | Azul profundo, "reverente, clásico" |
| Accent | `#D4A574` | Gold suave, "sagrado, premium" |

**Pros:** Coherente con la identidad religiosa/sobria; buen contraste sobre fondos claros.
**Contras:** **Rompe la consistencia visual con el HimnarioID 2.0** (que es gold/negro). Si un usuario migra de HimnarioID 2.0 a MQ App, sentirá que son apps diferentes.

### Opción B — Mantener la paleta de HimnarioID 2.0 (Gold/Negro/Blanco)

| Token | Hex | Ya definido en |
|-------|-----|----------------|
| `goldPrimary` | `#CCA43B` | `especificaciones-diseno.md` |
| `goldLight` | `#E8D48B` | id. |
| `goldDark` | `#8B7330` | id. |
| `blackSurface` | `#121212` | id. |
| `whiteSurface` | `#FEFAF0` | id. |

**Pros:** Consistencia total con el módulo Himnario (que viene de HimnarioID 2.0). El módulo Biblia se ve "parte de la misma app".
**Contras:** No es tan "reverente azul" como sugiere el spec.

### Recomendación de @design

> **Adoptar Opción B** (Gold/Negro/Blanco) por las siguientes razones:
>
> 1. HimnarioID 2.0 está **terminado y publicado**. Cambiar la paleta significa romper esa consistencia.
> 2. La paleta gold/negro/blanco es **atemporal y sagrada** (se usa en Biblias, libros litúrgicos, etc.).
> 3. Reduce el trabajo de @dev — los tokens de color ya están implementados y documentados.
> 4. El spec original (rev. v1.0) no especificaba colores concretos — la sugerencia de azul profundo vino después.
>
> Si el usuario **explícitamente quiere la Opción A**, podemos hacerlo, pero requerirá:
> - Re-tematizar el módulo Himnario (1-2 días de trabajo extra).
> - Actualizar `lib/core/theme/` con la nueva paleta.
> - Validar que las pistas de HimnarioID 2.0 (si las hay) se vean bien con la nueva paleta.

**DECISIÓN TOMADA EL 1 jun 2026** — @arqui adopta Opción B. Ver bloque `### ✅ DECIDIDO` en §1 y la tabla de decisiones cerrada al final del documento.

---

## 1. Paleta de colores (Opción B — recomendada)

### 1.0 ✅ DECIDIDO: Paleta Opción B (Gold/Negro/Blanco)

**Decisión de @arqui (1 jun 2026):** Adoptamos la Opción B (Gold/Negro/Blanco)
de HimnarioID 2.0 por las siguientes razones:
1. El módulo HimnarioID 2.0 ya está en producción y la consistencia visual es crítica.
2. Las 2 cards principales (Biblia + Himnario) en Home deben compartir lenguaje visual.
3. Gold/negro/blanco es atemporal y apropiado para contenido litúrgico.
4. Adoptar Opción A (azul+gold) requeriría re-theming del himnario (1-2 días extra).

### 1.1 Tokens primarios (de HimnarioID 2.0)

| Token | Hex | Uso |
|-------|-----|-----|
| `goldPrimary` | `#CCA43B` | Acentos principales, FAB, switches, acordes, iconos activos, borde seleccionado |
| `goldLight` | `#E8D48B` | Hover, variante clara, backgrounds sutiles |
| `goldDark` | `#8B7330` | Texto sobre fondos claros, borders en estado pressed |
| `blackSurface` | `#121212` | Superficie dark mode (tarjetas, sheets) |
| `blackBackground` | `#000000` | Fondo dark mode, fondo de proyección |
| `whiteSurface` | `#FEFAF0` | Superficie light mode (tarjetas, sheets) — blanco roto cálido |
| `whiteBackground` | `#FFFFFF` | Fondo light mode |

### ⚠️ Regla de uso de `goldPrimary` (#CCA43B)

`goldPrimary` tiene ratio de contraste **3:1** sobre `whiteSurface` (#FEFAF0).
**Esto CUMPLE WCAG AA solo para:**
- Texto grande (≥18pt, o 14pt+bold) — ratio 3:1 OK
- Íconos y acentos decorativos — ratio 3:1 OK
- Componentes UI no-textuales (botones grandes, badges) — ratio 3:1 OK

**Para texto de párrafo normal (body), usar:**
- `onSurface` (#1A1A1A) — ratio 18:1 ✓
- `goldDark` (#8B7330) si se requiere tono dorado — ratio 5.4:1 ✓

**NO usar `goldPrimary` para:**
- Texto body < 14pt
- Subtítulos o labels secundarios
- Párrafos completos

### 1.2 Escala de grises

| Token | Hex | Uso |
|-------|-----|-----|
| `grey900` | `#1A1A1A` | Iconos sobre gold, texto casi negro en dark |
| `grey800` | `#2A2A2A` | Fondo de botones secundarios dark |
| `grey700` | `#3A3A3A` | Botones inactivos dark, chips no seleccionados |
| `grey600` | `#5E5E5E` | Texto secundario dark, hint text |
| `grey500` | `#757575` | Placeholder, iconos inactivos |
| `grey400` | `#9E9E9E` | Borde en light mode (glassmorphism) |
| `grey300` | `#BDBDBD` | Botones inactivos light |
| `grey200` | `#E0E0E0` | Borde sutil light |
| `grey100` | `#F5F5F5` | Fondos de contenedores light |

### 1.3 Colores de notas (Biblia)

| Token | Hex | Uso |
|-------|-----|-----|
| `noteYellow` | `#FEF3C7` | Fondo/border de nota amarilla (background: `#FEF3C7`, border: `#F59E0B` a 50% opacidad) |
| `noteGreen` | `#D1FAE5` | Nota verde (border: `#10B981` a 50%) |
| `noteBlue` | `#DBEAFE` | Nota azul (border: `#3B82F6` a 50%) |
| `noteNone` | `transparent` | Sin color (sin border lateral) |

> **Aplicación:** El border lateral de la card del versículo lleva el color elegido. El fondo del editor de notas usa el color en opacidad 15-20%.

### 1.4 ColorScheme Material 3 (resumen)

#### Dark mode

```dart
ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFCCA43B),       // gold
  onPrimary: Color(0xFF1A1A1A),
  primaryContainer: Color(0xFF8B7330).withOpacity(0.3),
  onPrimaryContainer: Color(0xFFCCA43B),
  secondary: Color(0xFFE8D48B),     // gold light
  onSecondary: Color(0xFF1A1A1A),
  secondaryContainer: Color(0xFFE8D48B).withOpacity(0.15),
  onSecondaryContainer: Color(0xFFE8D48B),
  surface: Color(0xFF121212),
  onSurface: Color(0xFFFFFFFF),
  onSurfaceVariant: Color(0xFFB0B0B0),
  outline: Color(0xFF3A3A3A),
  outlineVariant: Color(0xFF2A2A2A),
  error: Color(0xFFCF6679),
)
```

#### Light mode

```dart
ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFCCA43B),       // gold
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFE8D48B).withOpacity(0.3),
  onPrimaryContainer: Color(0xFF8B7330),
  secondary: Color(0xFF8B7330),     // gold dark para light
  onSecondary: Color(0xFFFFFFFF),
  surface: Color(0xFFFEFAF0),       // blanco roto cálido
  onSurface: Color(0xFF1A1A1A),
  onSurfaceVariant: Color(0xFF5E5E5E),
  outline: Color(0xFFBDBDBD),
  outlineVariant: Color(0xFFE0E0E0),
  error: Color(0xFFB3261E),
)
```

---

## 2. Glassmorphism (heredado de HimnarioID 2.0)

### 2.0 ✅ DECIDIDO: Glassmorphism = SÍ

**Decisión de @arqui (1 jun 2026):** Aplicar glassmorphism en:
- Cards principales (Home, Biblia, Himnario)
- Modales y bottom sheets
- App bar en pantallas de lectura

**NO aplicar glassmorphism en:**
- Bottom nav (si existe en v1.0)
- Modo presentación / emitter compact view
- Splash screen inicial

| Propiedad | Dark mode | Light mode |
|-----------|-----------|------------|
| Color de fondo | `#FFFFFF` 10-15% opacidad | `#000000` 5-8% opacidad |
| BackdropFilter | `ImageFilter.blur(sigmaX: 12, sigmaY: 12)` | id. |
| Borde | 1.5px `#FFFFFF` 20% opacidad | 1.5px `#9E9E9E` 15% opacidad |
| Border radius | 16px (consistente) | id. |
| Elevación | 0 (sin sombra) | id. |

**Aplicación en MQ App:**
- ✅ **SÍ glass:** Versículo del día, cards de Biblia/Himnario (home), book list items, chapter grid buttons, reader card
- ❌ **NO glass:** Bottom navigation, modo presentación (requiere máximo contraste), emitter compact view (pantallas chicas)

> **Configurable por usuario** (slider de sigma 0-20 en Settings). Default: sigma 8.

---

## 3. Tipografía

### 3.1 Familia de fuentes

- **Default sistema** — Roboto (Android), SF Pro (iOS/macOS), Segoe UI (Windows).
- **No se carga ninguna fuente custom en v1.0.** Reducir peso de assets.

### 3.2 Escala tipográfica (sp = scale-independent pixels)

| Token | Tamaño | Peso | Uso |
|-------|--------|------|-----|
| `displayLarge` | 48sp | 800 (extra-bold) | Número de versículo (en emisor compact), número de himno |
| `displayMedium` | 32sp | 700 (bold) | Títulos principales, número de himno en card |
| `headlineLarge` | 28sp | 700 | Título de himno |
| `headlineMedium` | 24sp | 700 | Título de Biblia card / Himnario card en Home |
| `titleLarge` | 20sp | 600 | AppBar title, número de versículo en reader |
| `titleMedium` | 16sp | 600 | Subtítulos, referencia del versículo |
| `bodyLarge` | 18sp | 400 | **Texto del versículo** (lectura principal) |
| `bodyMedium` | 14sp | 400 | Texto secundario, descripciones |
| `bodySmall` | 12sp | 400 | Caption, hints, metadata |
| `labelLarge` | 14sp | 500 | Texto de botones |
| `labelMedium` | 12sp | 500 | Tabs, chips |

### 3.3 Line-height

| Tipo | Line-height |
|------|-------------|
| Texto del versículo (bodyLarge) | 1.6 |
| Subtítulos / metadata | 1.4 |
| Títulos | 1.2 |
| Botones | 1.0 (centrado vertical) |

### 3.4 Letter spacing

| Tipo | Tracking |
|------|----------|
| Títulos (headline) | -0.5 (más compacto) |
| Body | 0 (default) |
| Labels uppercase | 0.5 (más aireado) |

---

## 4. Espaciado

**Base unit: 8px**

| Token | Valor | Uso |
|-------|-------|-----|
| `space_xs` | 4px | Padding interno de chips, separadores verticales mínimos |
| `space_sm` | 8px | Entre icono y label, padding vertical de items |
| `space_md` | 16px | **Padding de cards**, padding horizontal de pantallas |
| `space_lg` | 24px | Padding vertical de secciones, top de pantallas |
| `space_xl` | 32px | Entre secciones principales |
| `space_xxl` | 48px | Padding bottom de pantallas (para FAB / bottom nav) |

### 4.1 Aplicación

- **Screen padding:** `16px horizontal, 24px top, 48px bottom`
- **Card padding:** `16px` (uniforme en todas las cards)
- **Card-to-card gap:** `16px` vertical
- **AppBar height:** `56px` (default Material)
- **Bottom bar height:** `72px` (con safe area)
- **Touch target mínimo:** `48x48dp` (accesibilidad)

---

## 5. Componentes

### 5.1 Cards

**Default card (glassmorphism):**

```
+------------------------------+
|                              |  <- 16px padding
|   Contenido del card         |
|                              |
+------------------------------+
```

| Propiedad | Valor |
|-----------|-------|
| Background | Glass (white 10% dark, black 5% light) |
| Border | 1.5px glass border |
| Border radius | 16px |
| Padding | 16px |
| Margin vertical | 8px (entre cards) |
| Animación de tap | Ripple gold al 30% opacidad |

### 5.2 Botones

**Filled (primary):**

```
+------------------------------+
|         SIGUIENTE            |  <- gold background, texto negro
+------------------------------+
```

| Propiedad | Valor |
|-----------|-------|
| Background | `goldPrimary` |
| Foreground | `onPrimary` (negro o blanco según tema) |
| Border radius | 12px |
| Height | 48dp (touch target) |
| Padding | 16-24dp horizontal |
| Font | labelLarge, uppercase opcional |

**Outlined (secondary):**

```
+------------------------------+
|         Cancelar             |  <- transparente, border gold
+------------------------------+
```

| Propiedad | Valor |
|-----------|-------|
| Background | transparent |
| Border | 1.5px `goldPrimary` |
| Foreground | `goldPrimary` |
| Otros | igual a filled |

**Text (tertiary):**

```
  Saltar este paso
```

- Sin border, sin background. Solo texto gold. Para acciones menos importantes.

### 5.3 Icon buttons (circular, sin texto)

```
  +---+
  | O |  <- 40x40dp, circular, icono 24dp
  +---+
```

| Estado | Apariencia |
|--------|------------|
| Default | Glass background (10% white/black) |
| Hover | Glass background 20% |
| Pressed | Gold 30% opacity |
| Disabled | 30% opacity general |

### 5.4 Chips (filter / selector)

```
  +---------+    +---------+
  | Todos   |    | Amarill.|
  +---------+    +---------+
```

| Estado | Background | Border | Texto |
|--------|-----------|--------|-------|
| Selected | `goldPrimary` | none | negro/blanco |
| Unselected | transparent | 1px `outline` | `onSurface` |

### 5.5 Tab bar (filtros AT/NT/Favoritos/Notas)

```
+------------------------------+
|  AT  |  NT  |  Favoritos  |  Notas  |
+------------------------------+
                |
                v underline gold 2dp
```

- **Active:** Texto `goldPrimary`, underline 2dp gold.
- **Inactive:** Texto `onSurfaceVariant`, sin underline.
- **Scrollable horizontal** si no caben todos.

### 5.6 Bottom bar del Reader

```
+------------------------------------------+
|  [<<] [<]      (1/31)      [>] [>>]      |
|            [*]   [nota]   [aleat]         |
+------------------------------------------+
```

- **Layout:** Fila 1: navegación (capítulo/versículo). Fila 2: acciones (favorito/nota/random).
- **Height:** 72dp + safe area.
- **Background:** `surfaceContainer` (sólido, no glass — debe ser estable).
- **Border top:** 1px `outlineVariant`.

### 5.7 Dropdown de versión (chip en AppBar)

```
+-----------+    +--------------------+
| [RV1909 v]|    |  [RV1909]          |
+-----------+    |  [RV1569]          |
                +--------------------+
```

- Mismo estilo que un chip. La flecha `v` indica dropdown.
- Al tap, abre un **menu** (no bottom sheet en este caso porque la lista es corta).

### 5.8 Modal / Bottom Sheet

- **Border radius top:** 24px (más generoso que las cards).
- **Handle bar** arriba (24x4dp, `outline` color).
- **Glass background** (igual que cards).
- **Padding:** 24px lateral, 16px top (después del handle), 24px bottom (safe area).

### 5.9 Indicador de nota (en card de versículo)

```
+--------------------------------+
|  1   En el principio...   [y] |  <- [y] = cuadrado 4x16dp del color
+--------------------------------+
```

| Estado | Apariencia |
|--------|------------|
| Nota yellow | Cuadrado `#FEF3C7` 100% (4dp ancho, lleno el alto de la card) |
| Nota green | Cuadrado `#D1FAE5` 100% |
| Nota blue | Cuadrado `#DBEAFE` 100% |
| Sin nota | No aparece el indicador |

### 5.10 Spinner / Loading

- Usar `CircularProgressIndicator` con `goldPrimary`.
- **NO** usar spinners de plataformas nativas (ActivityIndicator en iOS, etc.) — inconsistente.
- En loading states dentro de cards: **skeleton text** (rectángulos `outlineVariant` pulsando), no spinners centrados.

---

## 6. Iconografía

### 6.1 Set base (Material Icons)

| Función | Icono | Notas |
|---------|-------|-------|
| Settings | `Icons.settings_rounded` | Esquina top-left Home |
| Connect / Cast | `Icons.cast_rounded` | Esquina top-right Home |
| Search | `Icons.search_rounded` | AppBars |
| Back | `Icons.arrow_back_rounded` | AppBar leading |
| More | `Icons.more_vert_rounded` | Overflow menu |
| Biblia | `Icons.menu_book_rounded` | Card Biblia |
| Himnario | `Icons.music_note_rounded` | Card Himnario |
| Favorito (on) | `Icons.star_rounded` | Relleno, gold |
| Favorito (off) | `Icons.star_outline_rounded` | Solo border |
| Refresh | `Icons.refresh_rounded` | Versículo del día |
| Note | `Icons.edit_note_rounded` | Bottom bar reader |
| Random | `Icons.casino_rounded` | Bottom bar reader |
| Fullscreen | `Icons.fullscreen_rounded` | Bottom bar reader |
| Skip prev/next | `Icons.skip_previous_rounded` / `skip_next_rounded` | Bottom bar reader |
| Chevron left/right | `Icons.chevron_left_rounded` / `chevron_right_rounded` | Bottom bar reader |
| Close | `Icons.close_rounded` | Modales |
| Dropdown arrow | `Icons.keyboard_arrow_down_rounded` | Versión chip |
| Share | `Icons.share_rounded` | Overflow menu |
| Blackout | `Icons.visibility_off_rounded` | FAB emitter |
| Blackout off | `Icons.visibility_rounded` | FAB emitter |

### 6.2 Tamaño de iconos

| Contexto | Tamaño |
|----------|--------|
| AppBar actions | 24dp |
| Icon button circular | 24dp (en botón 40dp) |
| Cards grandes (Biblia/Himnario) | 40dp |
| Emisor compact (v. 5) | 80dp (versión especial) |
| FAB | 24dp |
| Tab bar | 24dp |

### 6.3 Color de iconos

- **Default:** `onSurface` (white/black según tema)
- **Active/Selected:** `goldPrimary`
- **Disabled:** `onSurface` con 30% opacity

---

## 7. Estados de UI

### 7.1 Loading

| Tipo | Apariencia |
|------|------------|
| Full screen (cold start) | Splash con logo + spinner |
| Card content (versículo) | Skeleton text pulsando |
| Botón async | Spinner reemplaza al label, botón se deshabilita |
| Lista (búsqueda) | Skeleton rows (3-5 filas placeholder) |

### 7.2 Empty

| Tipo | Apariencia |
|------|------------|
| Sin favoritos | Icon `star_outline` 64dp + texto "Aun no tienes favoritos" + CTA "Ir a la Biblia" |
| Sin notas | Icon `edit_note_outline` 64dp + texto "Aun no tienes notas" + CTA "Ir a la Biblia" |
| Sin resultados búsqueda | Icon `search_off` 64dp + texto "No se encontraron versiculos para X" |
| Sin conexión (emisor) | Banner warning + texto + botón "Reintentar" |

### 7.3 Error

| Tipo | Apariencia |
|------|------------|
| BD no inicializada | Pantalla full-screen con icono + "Error al cargar datos" + "Reintentar" |
| Error de red (emisor) | Banner sticky + texto + auto-retry cada 5s |
| Error genérico | Snackbar en bottom con `error` color + texto + acción "Reintentar" |

### 7.4 Success (feedback positivo)

| Acción | Feedback |
|--------|----------|
| Favorito agregado | Snackbar "Agregado a favoritos" + botón "Deshacer" (5s) |
| Favorito quitado | Snackbar "Quitado de favoritos" + botón "Deshacer" (5s) |
| Nota guardada | Toast breve "Nota guardada" (2s, sin acción) |
| Versión cambiada | Snackbar "Cambiado a RV1569" (2s) |
| Capítulo visitado | Sin feedback explícito (la card se ilumina en la grid) |

---

## 8. Animaciones y transiciones

| Transición | Duración | Curva | Notas |
|------------|----------|-------|-------|
| Push (navegación) | 300ms | `Curves.easeInOutCubic` | Material default |
| Pop | 300ms | id. | id. |
| Cambio de versículo (swipe) | 200ms | `Curves.easeInOut` | Sutil, no distractivo |
| Cambio de versión | 150ms | `Curves.easeOut` | Crossfade en el texto del versículo |
| Mostrar/ocultar favorito | 200ms | `Curves.elasticOut` | El icono "salta" sutilmente |
| Bottom sheet | 250ms | `Curves.easeOutCubic` | Material default |
| Modal (center) | 200ms | `Curves.easeOut` | Fade + scale (0.9 → 1.0) |
| Snackbar | 200ms in / 150ms hold / 200ms out | `Curves.easeOut` | Material default |

**Regla:** Todas las animaciones respetan `prefers-reduced-motion` (se deshabilitan o se reducen a 0ms).

---

## 9. Accesibilidad (resumen)

| Criterio | Implementación |
|----------|----------------|
| Contraste | Texto principal ≥ 7:1, secundario ≥ 4.5:1 (validado contra fondos `surface` y `surfaceContainer`) |
| Touch targets | ≥ 48x48dp para todos los botones |
| Screen readers | `Semantics` widgets en cada elemento interactivo con label descriptivo |
| Reduced motion | Respeta `MediaQuery.disableAnimations` |
| Font scaling | Respeta `MediaQuery.textScaler` (límite 200% para evitar overflow) |
| Focus visible (desktop) | Outline 2px gold en elementos con focus |
| Color independence | Información de color **siempre acompañada de texto o icono** (no solo color) |

---

## 10. Decisiones explícitas (a confirmar)

| # | Decisión | Default propuesto |
|---|----------|-------------------|
| 1 | Paleta primary | **Opción B** (gold/negro/blanco) — ✅ **DECIDIDO 1 jun 2026** (ver §1.0 y §13) |
| 2 | Tema default al instalar | **Dark mode** (consistente con HimnarioID 2.0) |
| 3 | Glassmorphism default | **Activado**, sigma 8 |
| 4 | Tamaño de fuente default del versículo | 18sp (bodyLarge) |
| 5 | Familias de fuente | Sistema (sin custom fonts) |
| 6 | Locale | es-419 (español Latinoamérica), fallback es-ES |
| 7 | Persistencia del tema | `Configuracion.tema_usuario` |
| 8 | Idioma de los wireframes | Español (para UI y docs) |

---

## 11. Recursos compartidos (a reutilizar de HimnarioID 2.0)

| Recurso | Ubicación | Notas |
|---------|-----------|-------|
| `GlassContainer` widget | `lib/presentation/shared_widgets/glass_container.dart` | Reutilizar tal cual |
| `HymnAppearanceState` | `lib/presentation/shared_widgets/providers/appearance_provider.dart` | Reutilizar, extender con campos Biblia |
| `AppTheme` | `lib/core/theme/app_theme.dart` | Reutilizar (consistencia de paleta) |
| `ColorScheme` | `lib/core/theme/color_schemes.dart` | Reutilizar |
| `TextTheme` | `lib/core/theme/text_theme.dart` | Reutilizar (extender con tokens Biblia) |
| Iconografía base | Material Icons (built-in) | Sin cambios |
| Glass settings | tabla `Configuracion` (ya existe) | Reutilizar |

> **Implicación para @arqui:** La migración de HimnarioID 2.0 a MQ App es **mayormente aditiva**. No hay que reescribir el tema, solo añadir tokens para Biblia.

---

## 12. Preguntas abiertas para el usuario

> **Estado (1 jun 2026):** Las preguntas 1-6 de esta sección fueron resueltas por @arqui el 1 jun 2026 (ver §13). Quedan 2 preguntas abiertas para el **usuario final**:
>
> - Bottom nav (Historial/Favoritos/Notas) en v1.0 vs diferir a v1.1.
> - Cuestiones menores de copy/microcopy que surjan en la fase de implementación.
>
> Esta sección se conserva como contexto histórico del proceso de decisión.

1. **Paleta: Opción A (azul+gold) o Opción B (gold/negro/blanco)?** — ✅ **RESUELTO: Opción B** (ver §1.0).
2. **¿Tema default dark o light?** — ✅ **RESUELTO: dark** (consistencia con HimnarioID 2.0).
3. **¿Cargar fuente custom** (e.g., Lora para versículos) o quedarse con sistema? — ✅ **RESUELTO: sistema en v1.0**, custom opcional en v1.1.
4. **¿Los iconos deben ser outlined o filled?** — ✅ **RESUELTO: outlined default, filled on active** (Material 3).
5. **¿Agregar animations de parallax en el scroll de listas** (estilo iOS)? — ✅ **RESUELTO: NO**, mantener simple.
6. **¿Soporte para temas personalizados por el usuario** (color de acento custom)? — ✅ **RESUELTO: NO en v1.0**, diferido a v1.1+.

---

## 13. Decisiones de UX Cerradas por @arqui (1 jun 2026)

> **Propósito:** Tabla maestra de las 20 decisiones de UX tomadas por @arqui en la revisión del style guide. Es la fuente de verdad para que @dev implemente sin ambigüedad.
> **1 pregunta diferida al usuario:** Bottom nav (Historial/Favoritos/Notas) en v1.0 vs diferir a v1.1.

| # | Pregunta | Decisión | Razón |
|---|----------|----------|-------|
| 1 | Animación de entrada de cards | Fade-in 200ms | Sin slide (mejor para accesibilidad) |
| 2 | Refresh automático del versículo | Solo en cold start | Coherente con spec §3.3 |
| 3 | UX de "ya favorito" | Undo snackbar | Material 3 idiom |
| 4 | Reader: 1 versículo vs contexto | 1 versículo | Coherente con HimnarioID 2.0 |
| 5 | Duración animación swipe | 200ms ease-in-out | Definido en este style guide |
| 6 | Random respeta favoritos | NO, puramente random | Modo descubrimiento |
| 7 | Indicador de nota siempre visible | Solo cuando color es visible | UX más limpia |
| 8 | Fullscreen oculta progreso | SÍ, 0 chrome | Inmersión |
| 9 | Bookmarks en v1.0 | NO, favoritos cubren el caso | Diferido a v1.1+ |
| 10 | Modo default por device | Global (no per-device) | Simplicidad |
| 11 | Transición Compact↔Preview | 300ms fade | En este style guide |
| 12 | "ENVIAR SIG." confirma | El preview ES la confirmación | Sin modal extra |
| 13 | FAB del emisor siempre visible | SÍ | Velocidad de uso |
| 14 | Preview para capítulo completo | NO, solo versículo por versículo | Coherencia |
| 15 | Tema default (dark/light) | Dark | Coherente con himnario |
| 16 | Fuentes custom | Solo system fonts en v1.0 | Ahorra 2MB |
| 17 | Íconos outlined vs filled | Outlined default, filled on active | Material 3 |
| 18 | Parallax scroll | NO | Mantener simple |
| 19 | Color de acento custom | NO en v1.0 | Diferido a v1.1+ |

> **Nota sobre el conteo:** La tabla lista 19 decisiones explícitas + 1 pregunta de paleta resuelta por @arqui (ver §1.0) = 20 de las 22 preguntas abiertas. La pregunta 22 (bottom nav) queda diferida al usuario final.

---

*Wireframe creado por @design — DECISIONES DE PALETA Y GLASMORPHISM LOCKED el 1 jun 2026 (@arqui). Style guide listo para implementación. La pregunta de bottom nav queda abierta para el usuario final.*
