# Especificaciones de Diseno Visual — HimnarioID 2.0

> Documento maestro de diseno para la migracion a paleta corporativa Negro/Dorado/Blanco.
> Creado: 27 de mayo de 2026
> Rol: @design — Frontend UX Engineer
> Destinatario: @dev — Implementador

---

## Indice

1. [Paleta de Colores Exacta](#a-paleta-de-colores-exacta)
2. [Glassmorphism Spec](#b-glassmorphism-spec)
3. [Componente por Componente](#c-componente-por-componente)
   - [3.1 HymnCard](#1-hymncard)
   - [3.2 DraggableScrollableSheet (Brush Sheet)](#2-draggablescrollablesheet-brush-sheet)
   - [3.3 FAB (FloatingActionButton)](#3-fab-floatingactionbutton)
   - [3.4 AppBar](#4-appbar)
   - [3.5 NavigationBar](#5-navigationbar)
   - [3.6 FilterChips (HomeScreen)](#6-filterchips-home_screen)
   - [3.7 Acordes Musicales](#7-acordes-musicales)
   - [3.8 Botones Inactivos/Secundarios](#8-botones-inactivossecundarios)
   - [3.9 Cards de Proyeccion (Projection Theme)](#9-cards-de-proyeccion-projection-theme)
   - [3.10 Modales y Dialogs](#10-modales-y-dialogs)
4. [Transiciones y Micro-interacciones](#d-transiciones-y-micro-interacciones)
5. [Hallazgos Visuales](#hallazgos-visuales-mas-importantes)
6. [Recomendaciones para @dev](#recomendaciones-para-dev)
7. [Riesgos Visuales Identificados](#riesgos-visuales-identificados)

---

## A. Paleta de Colores Exacta

### Colores Corporativos

| Token | Hex | Uso |
|-------|-----|-----|
| `goldPrimary` | `#CCA43B` | Acentos principales, FAB, switches, acordes musicales, iconos activos, borde seleccionado |
| `goldLight` | `#E8D48B` | Hover states, variante clara del dorado, backgrounds sutiles |
| `goldDark` | `#8B7330` | Texto sobre fondos claros, variante oscura del dorado, bordes en estado pressed |
| `blackSurface` | `#121212` | Superficie principal en dark mode (tarjetas, sheets) |
| `blackBackground` | `#000000` | Fondo principal dark mode, fondo de proyeccion |
| `whiteSurface` | `#FEFAF0` | Superficie principal en light mode (tarjetas, sheets) — blanco roto calido |
| `whiteBackground` | `#FFFFFF` | Fondo principal light mode |

### Escala de Grises

| Token | Hex | Uso |
|-------|-----|-----|
| `grey900` | `#1A1A1A` | Iconos sobre gold, texto casi negro en dark mode |
| `grey800` | `#2A2A2A` | Fondo de botones secundarios dark mode |
| `grey700` | `#3A3A3A` | Botones inactivos dark, chips no seleccionados |
| `grey600` | `#5E5E5E` | Texto secundario dark mode, hint text |
| `grey500` | `#757575` | Placeholder, iconos inactivos |
| `grey400` | `#9E9E9E` | Borde en light mode (glassmorphism) |
| `grey300` | `#BDBDBD` | Botones inactivos light mode |
| `grey200` | `#E0E0E0` | Borde sutil en light mode |
| `grey100` | `#F5F5F5` | Fondos de contenedores light mode |

### Colores Funcionales del Tema

#### Modo Oscuro (Dark)

| Token | Color | Equivalente Material |
|-------|-------|---------------------|
| `surface` | `#121212` | surface |
| `surfaceContainer` | `#1E1E1E` | surfaceContainer |
| `surfaceContainerLow` | `#1A1A1A` | surfaceContainerLow |
| `surfaceContainerHigh` | `#2A2A2A` | surfaceContainerHigh |
| `primary` | `#CCA43B` | primary |
| `onPrimary` | `#1A1A1A` | onPrimary (texto sobre dorado) |
| `primaryContainer` | `#8B7330` con opacidad 30% | primaryContainer |
| `onPrimaryContainer` | `#CCA43B` | onPrimaryContainer |
| `secondary` | `#E8D48B` | secondary (gold claro) |
| `onSecondary` | `#1A1A1A` | onSecondary |
| `secondaryContainer` | `#E8D48B` con opacidad 15% | secondaryContainer |
| `onSecondaryContainer` | `#E8D48B` | onSecondaryContainer |
| `tertiary` | `#CCA43B` | tertiary (se usa como gold) |
| `error` | `#CF6679` | error |
| `onSurface` | `#FFFFFF` | onSurface (texto principal) |
| `onSurfaceVariant` | `#B0B0B0` | onSurfaceVariant (texto secundario) |
| `outline` | `#3A3A3A` | outline |
| `outlineVariant` | `#2A2A2A` | outlineVariant |

#### Modo Claro (Light)

| Token | Color | Equivalente Material |
|-------|-------|---------------------|
| `surface` | `#FEFAF0` | surface (blanco roto calido) |
| `surfaceContainer` | `#FFFFFF` | surfaceContainer |
| `surfaceContainerLow` | `#FEFAF0` | surfaceContainerLow |
| `surfaceContainerHigh` | `#FFFFFF` | surfaceContainerHigh |
| `primary` | `#CCA43B` | primary |
| `onPrimary` | `#FFFFFF` | onPrimary (texto negro sobre gold no funciona bien) |
| `primaryContainer` | `#E8D48B` con opacidad 30% | primaryContainer |
| `onPrimaryContainer` | `#8B7330` | onPrimaryContainer |
| `secondary` | `#8B7330` | secondary (gold oscuro para light) |
| `onSecondary` | `#FFFFFF` | onSecondary |
| `error` | `#B3261E` | error |
| `onSurface` | `#1A1A1A` | onSurface (texto principal) |
| `onSurfaceVariant` | `#5E5E5E` | onSurfaceVariant (texto secundario) |
| `outline` | `#BDBDBD` | outline |
| `outlineVariant` | `#E0E0E0` | outlineVariant |

---

## B. Glassmorphism Spec

### Dark Mode
| Propiedad | Valor |
|-----------|-------|
| Color de fondo | `#FFFFFF` con opacidad 10-15% |
| Efecto | BackdropFilter con `ImageFilter.blur(sigmaX: 12, sigmaY: 12)` |
| Blur sigma | 12-16px (consistente) |
| Borde | 1.5px, `#FFFFFF` con opacidad 20% |
| Border radius | 16px (consistente en toda la app) |
| Elevation | 0 (no usar sombra, el glassmorphism reemplaza la profundidad) |

### Light Mode
| Propiedad | Valor |
|-----------|-------|
| Color de fondo | `#000000` con opacidad 5-8% |
| Efecto | BackdropFilter con `ImageFilter.blur(sigmaX: 12, sigmaY: 12)` |
| Blur sigma | 12-16px (consistente) |
| Borde | 1.5px, `#9E9E9E` con opacidad 15% |
| Border radius | 16px (consistente en toda la app) |

### Uso del Glassmorphism
- HymnCard: SI (superficie con blur)
- Brush Sheet: SI (superficie del sheet)
- Detalle de estrofas: SI (cada tarjeta de estrofa en modo personal)
- Modales y Dialogs: SI
- Cards de proyeccion: NO (requieren maximo contraste)
- NavigationBar: NO (usar surfaceContainer solido)

---

## C. Componente por Componente

### 1. HymnCard

#### Modo Oscuro (Dark)

| Propiedad | Valor |
|-----------|-------|
| Fondo | `#FFFFFF` con opacidad 10% + blur 12px |
| Borde | 1.5px, `#FFFFFF` con opacidad 15% |
| Border radius | 16px |
| Sombra | Ninguna (el glassmorphism provee profundidad) |
| | |
| **Numero del himno** | |
| Fondo del badge | `#CCA43B` (goldPrimary) con opacidad 20% |
| Texto del numero | `#CCA43B` (goldPrimary), bold |
| Border radius del badge | 12px |
| | |
| **Titulo** | |
| Color | `#FFFFFF` (onSurface) |
| Tamanio | `titleMedium` (16sp) |
| Peso | `w600` |
| | |
| **Primera linea (subtitulo)** | |
| Color | `#B0B0B0` (onSurfaceVariant) |
| Tamanio | `bodySmall` (14sp) |
| | |
| **Categorias (chips)** | |
| Fondo chip | `#E8D48B` con opacidad 20% |
| Texto chip | `#E8D48B` |
| Border radius chip | 8px |
| | |
| **Icono chevron** | |
| Color | `#B0B0B0` (onSurfaceVariant) |
| | |
| **Hover / Presionado (InkWell)** | |
| Splash | `#CCA43B` con opacidad 15% |
| Highlight | `#FFFFFF` con opacidad 5% |

#### Modo Claro (Light)

| Propiedad | Valor |
|-----------|-------|
| Fondo | `#000000` con opacidad 5% + blur 12px |
| Borde | 1.5px, `#9E9E9E` con opacidad 12% |
| Border radius | 16px |
| | |
| **Numero del himno** | |
| Fondo del badge | `#CCA43B` con opacidad 15% |
| Texto del numero | `#8B7330` (goldDark), bold |
| | |
| **Titulo** | |
| Color | `#1A1A1A` (onSurface) |
| | |
| **Primera linea (subtitulo)** | |
| Color | `#5E5E5E` (onSurfaceVariant) |
| | |
| **Categorias (chips)** | |
| Fondo chip | `#CCA43B` con opacidad 12% |
| Texto chip | `#8B7330` |
| | |
| **Icono chevron** | |
| Color | `#5E5E5E` (onSurfaceVariant) |

---

### 2. DraggableScrollableSheet (Brush Sheet)

#### Handle Bar

| Propiedad | Dark | Light |
|-----------|------|-------|
| Ancho | 40px | 40px |
| Alto | 4px | 4px |
| Color | `#B0B0B0` con opacidad 40% | `#5E5E5E` con opacidad 30% |
| Border radius | 2px | 2px |

#### Superficie del Sheet (modo movil)

| Propiedad | Dark | Light |
|-----------|------|-------|
| Fondo | `#121212` (blackSurface) | `#FEFAF0` (whiteSurface) |
| Efecto | Sin blur (fondo solido para rendimiento) | Sin blur |
| Borde superior | Sin borde (modal sheet nativo) | Sin borde |
| Border radius superior | 20px | 20px |
| Padding interno | 24px laterales, 12px top, 32px bottom | igual |

#### Superficie del Dialog (modo desktop)

| Propiedad | Dark | Light |
|-----------|------|-------|
| Fondo | `#1E1E1E` con opacidad 95% + blur 16px | `#FFFFFF` con opacidad 95% + blur 16px |
| Borde | 1.5px, `#FFFFFF` con opacidad 20% | 1.5px, `#9E9E9E` con opacidad 15% |
| Border radius | 20px | 20px |
| Max width | 500px | 500px |

#### Sliders

| Propiedad | Valor |
|-----------|-------|
| Track (inactivo) | Dark: `#3A3A3A` (grey700), Light: `#BDBDBD` (grey300) |
| Track (activo) | `#CCA43B` (goldPrimary) |
| Thumb | `#CCA43B` (goldPrimary) — 12px diametro |
| Overlay | `#CCA43B` con opacidad 20% |
| Track height | 4px |
| Divisions | segun control (sliders de opacidad: 20; font scale: 11) |

#### Botones de Color (_ColorCircle)

| Propiedad | Valor |
|-----------|-------|
| Tamanio | 44x44px |
| Border radius | 12px |
| Borde no seleccionado | Dark: `#3A3A3A`, Light: `#BDBDBD`, width: 1px |
| Borde seleccionado | `#CCA43B` (goldPrimary), width: 2.5px |
| Icono check | `#CCA43B` (goldPrimary), 20px |
| Opacidad hover | `#FFFFFF` con opacidad 10% overlay (dark) |

#### Lista de Colores Sugeridos para Texto

```
#1A1A1A  (casi negro)   — defecto
#FFFFFF  (blanco)
#B3261E  (rojo)
#1D6F42  (verde)
#1A6B8A  (azul)
#6750A4  (purpura)
```

#### Lista de Colores Sugeridos para Acordes

```
#CCA43B  (DORADO — NUEVO DEFAULT)
#B3261E  (rojo)
#1A6B8A  (azul)
#1D6F42  (verde)
#FF8F00  (naranja)
#E8D48B  (gold claro)
#FFFFFF  (blanco)
```

> NOTA: El color default de acordes CAMBIA de purpura `#6750A4` a DORADO `#CCA43B`.

#### Font Options (_FontOption)

| Propiedad | No seleccionado | Seleccionado |
|-----------|-----------------|--------------|
| Fondo | Dark: `#2A2A2A`, Light: `#F5F5F5` | Dark/Light: gold con opacidad 20% |
| Borde | Dark: `#3A3A3A`, Light: `#E0E0E0` | `#CCA43B`, width: 2px |
| Border radius | 12px | 12px |
| Texto preview | `#CCA43B` (gold) | `#CCA43B` (gold) |
| Icono check | — | `#CCA43B` check_circle |

---

### 3. FAB (FloatingActionButton)

#### FAB Principal (menu expandible en hymn_detail)

| Propiedad | Valor |
|-----------|-------|
| Fondo | `#CCA43B` (goldPrimary) |
| Icono | `#1A1A1A` (grey900 — casi negro para contraste) |
| Sombra | `#000000` con opacidad 30%, blurRadius 8, offset 0,4 |
| Elevation | 6 (normal), 12 (pressed) |
| Tamanio | 56x56 (estandar) |
| Shape | Circular |
| Hover | `#CCA43B` con opacidad 90% (ligeramente mas oscuro) |
| Pressed | `#8B7330` (goldDark) |

#### FAB Opciones Expandidas (_FabOption)

| Propiedad | Valor |
|-----------|-------|
| Fondo del boton small | `#CCA43B` (goldPrimary) |
| Icono del boton small | `#1A1A1A` |
| Label tooltip | Fondo: Dark `#2A2A2A`, Light `#FFFFFF` con sombra sutil |
| Texto del tooltip | `onSurface` del tema |
| Borde del tooltip | opcional: 1px `#CCA43B` con opacidad 30% |
| Separacion entre opciones | 64px |
| Animacion | 250ms, Curves.easeInOut |

#### FAB Extended (PresentButton en HomeScreen)

| Propiedad | Estado Presentar | Estado Detener |
|-----------|-----------------|----------------|
| Fondo | `#CCA43B` (goldPrimary) | `#CF6679` con opacidad 20% (error container) |
| Texto | `#1A1A1A` (onPrimary) | `#CF6679` (error) |
| Icono | `#1A1A1A` (screen_share) | `#CF6679` (stop_screen_share) |
| Border radius | 16px | 16px |
| Elevation | 6 | 6 |

---

### 4. AppBar

| Propiedad | Dark | Light |
|-----------|------|-------|
| Fondo | Transparente (deja ver surface `#121212`) | Transparente (deja ver surface `#FEFAF0`) |
| Elevation | 0 | 0 |
| Borde inferior | 0.5px, `#FFFFFF` con opacidad 10% | 0.5px, `#000000` con opacidad 8% |
| | | |
| **Titulo** | | |
| Color | `#FFFFFF` (onSurface) | `#1A1A1A` (onSurface) |
| Tamanio | titleMedium (16sp) | titleMedium (16sp) |
| Peso | w600 | w600 |
| | | |
| **Iconos de accion** | | |
| Color activo | `#CCA43B` (goldPrimary) | `#CCA43B` (goldPrimary) |
| Color inactivo | `#B0B0B0` (onSurfaceVariant) | `#5E5E5E` (onSurfaceVariant) |
| Hit target | 48x48px minimo | 48x48px minimo |
| Hover | `#FFFFFF` con opacidad 8% | `#000000` con opacidad 5% |

---

### 5. NavigationBar

> NOTA: La app actualmente NO usa NavigationBar (usa FAB + botones), pero se especifica para futura implementacion.

| Propiedad | Dark | Light |
|-----------|------|-------|
| Fondo | `#1E1E1E` (surfaceContainer) | `#FFFFFF` (surfaceContainer) |
| Elevation | 0 (plano, sin sombra) | 0 |
| Borde superior | 0.5px, `#FFFFFF` con opacidad 10% | 0.5px, `#000000` con opacidad 8% |
| Altura | 80px (con safe area) | 80px |
| | | |
| **Icono seleccionado** | `#CCA43B` (goldPrimary) | `#CCA43B` (goldPrimary) |
| **Icono no seleccionado** | `#B0B0B0` (onSurfaceVariant) | `#5E5E5E` (onSurfaceVariant) |
| **Label seleccionado** | `#CCA43B` (goldPrimary) | `#CCA43B` (goldPrimary) |
| **Label no seleccionado** | `#B0B0B0` | `#5E5E5E` |
| **Indicador seleccionado** | `#E8D48B` con opacidad 15% | `#CCA43B` con opacidad 12% |
| **Badge (si aplica)** | `#CCA43B` | `#CCA43B` |

---

### 6. FilterChips (HomeScreen)

#### Filtros de himno (Todos, Oficiales, Inspiradas, Convencion)

| Estado | Dark | Light |
|--------|------|-------|
| **No seleccionado** | | |
| Fondo | `#3A3A3A` (grey700) | `#E0E0E0` (grey200) |
| Texto | `#B0B0B0` (onSurfaceVariant) | `#5E5E5E` (onSurfaceVariant) |
| Borde | `#3A3A3A` (outline) | `#BDBDBD` (outline) |
| | | |
| **Seleccionado** | | |
| Fondo | `#CCA43B` (goldPrimary) | `#CCA43B` (goldPrimary) |
| Texto | `#1A1A1A` (casi negro, alto contraste) | `#1A1A1A` |
| Checkmark | `#1A1A1A` | `#1A1A1A` |
| Borde | `#CCA43B` | `#CCA43B` |
| Peso texto | `w600` | `w600` |
| | | |
| **Hover/Pressed** | gold con opacidad 80% | gold con opacidad 80% |
| **Visual density** | compact | compact |

#### Filtros de ordenamiento (A-Z, Z-A)

Misma especificacion que FilterChips de filtro, pero:
- Fondo seleccionado: `#E8D48B` con opacidad 20% en dark
- Texto seleccionado: `#E8D48B` en dark (goldLight en vez de goldPrimary para diferenciar)

#### Chip de Categoria

Misma spec que chips de filtro, con avatar icon que cambia:
- No seleccionado: icono `arrow_drop_down`
- Seleccionado: icono `close`

---

### 7. Acordes Musicales

#### Color Default (NUEVO)

| Propiedad | Valor |
|-----------|-------|
| Color default | `#CCA43B` (goldPrimary) |
| Color default (light mode) | `#8B7330` (goldDark — mas contraste sobre fondo claro) |

#### Opciones de Color en Brush Sheet

Lista sugerida de colores predefinidos en _chordColors:

```
Color(0xFFCCA43B)  // DORADO (nuevo default, reemplaza purpura)
Color(0xFFB3261E)  // rojo
Color(0xFF1A6B8A)  // azul
Color(0xFF1D6F42)  // verde
Color(0xFFFF8F00)  // naranja
Color(0xFFE8D48B)  // gold claro
Color(0xFFFFFFFF)  // blanco
```

> IMPORTANTE: El orden de la lista importa. El primer elemento debe ser el default visual. El codigo actual tiene `[0] = purpura`. Cambiar a `[0] = Color(0xFFCCA43B)`.

#### Renderizado en pantalla

| Propiedad | Dark | Light |
|-----------|------|-------|
| Color | `#CCA43B` (goldPrimary) | `#8B7330` (goldDark) |
| Peso | bold | bold |
| Tamanio | baseFontSize * 0.6 (entre 8-13sp) | igual |
| Altura de linea | 1.1 | 1.1 |

#### Animacion de Acordes

| Propiedad | Valor |
|-----------|-------|
| Transicion al cambiar color | Crossfade de 200ms |
| Transicion al mostrar/ocultar | AnimatedSwitcher con fade 200ms |
| Scroll suave | AnimatedContainer para hover en selector de color |

---

### 8. Botones Inactivos/Secundarios

#### ElevatedButton / FilledButton (secundario)

| Propiedad | Dark | Light |
|-----------|------|-------|
| Fondo | `#3A3A3A` (grey700) | `#BDBDBD` (grey300) |
| Texto | `#9E9E9E` (grey400) | `#757575` (grey500) |
| Icono | `#9E9E9E` | `#757575` |
| Border radius | 12px | 12px |
| Elevation | 0 | 0 |

#### TextButton (secundario)

| Propiedad | Dark | Light |
|-----------|------|-------|
| Texto | `#B0B0B0` (onSurfaceVariant) | `#5E5E5E` (onSurfaceVariant) |
| Hover | `#FFFFFF` con opacidad 8% | `#000000` con opacidad 5% |
| Pressed | `#FFFFFF` con opacidad 12% | `#000000` con opacidad 8% |

#### OutlinedButton

| Propiedad | Dark | Light |
|-----------|------|-------|
| Borde | `#3A3A3A` (outline) | `#BDBDBD` (outline) |
| Texto | `#B0B0B0` | `#5E5E5E` |
| Hover | gold 8% overlay | gold 5% overlay |

#### Switch (toggle)

| Propiedad | Dark | Light |
|-----------|------|-------|
| Track ON | `#CCA43B` con opacidad 50% | `#CCA43B` con opacidad 50% |
| Thumb ON | `#CCA43B` | `#CCA43B` |
| Track OFF | `#3A3A3A` | `#BDBDBD` |
| Thumb OFF | `#9E9E9E` | `#757575` |

---

### 9. Cards de Proyeccion (Projection Theme)

La ventana de proyeccion NO usa glassmorphism. Requiere maximo contraste para legibilidad en pantalla grande.

| Propiedad | Valor |
|-----------|-------|
| Fondo de scaffold | `#000000` (blackBackground) |
| ColorScheme | Dark manual: primary = white, surface = black |
| | |
| **TitleSlide** | |
| Fondo | `#000000` |
| Texto titulo | `#FFFFFF` (onSurface), displayLarge, bold |
| Texto numero | `#FFFFFF` con opacidad 30% |
| | |
| **LyricsSlide** | |
| Fondo | `#000000` |
| Texto letra | `#FFFFFF` (appearance.textColor definido por usuario) |
| Acordes | `#CCA43B` o el color que el usuario elija en Brush Sheet |
| Label estrofa | `#FFFFFF` con opacidad 60% |
| Progress dots | Activo: `#FFFFFF`, Inactivo: `#FFFFFF` con opacidad 20% |
| | |
| **AmenSlide** | |
| Texto | `#FFFFFF`, fontSize: baseFontSize * 5, bold |
| | |
| **Connection chip** | |
| Fondo | `#000000` con opacidad 50% |
| Borde | `#FFFFFF` con opacidad 15% |
| Texto | `#FFFFFF` con opacidad 60% |
| Indicador | Verde `#4CAF50` (conectado) / Rojo error (desconectado) |
| Border radius | 20px |

---

### 10. Modales y Dialogs

#### ModalBottomSheet (movil)

| Propiedad | Dark | Light |
|-----------|------|-------|
| Fondo | `#121212` (blackSurface) | `#FEFAF0` (whiteSurface) |
| Border radius superior | 20px | 20px |
| Handle bar | 40x4px, `#B0B0B0` opacidad 40% | 40x4px, `#5E5E5E` opacidad 30% |
| Elevation | 0 | 0 |

#### Dialog (desktop)

| Propiedad | Dark | Light |
|-----------|------|-------|
| Fondo | `#1E1E1E` + blur 16px + borde 1.5px `#FFFFFF` 20% | `#FFFFFF` + blur 16px + borde 1.5px `#9E9E9E` 15% |
| Border radius | 20px | 20px |
| Max width | 500px | 500px |
| Max height | 600-700px | 600-700px |
| Shadow | `#000000` opacidad 30%, blurRadius 20, offset 0,8 | igual |
| Overlay trasero | `#000000` con opacidad 50% | `#000000` con opacidad 30% |

#### Search Delegate

| Propiedad | Dark | Light |
|-----------|------|-------|
| Fondo | `#121212` | `#FEFAF0` |
| TextField | OnSurface, hint: onSurfaceVariant | igual |

#### SnackBar

| Propiedad | Dark | Light |
|-----------|------|-------|
| Fondo | `#1E1E1E` con blur 12px | `#FFFFFF` con blur 12px |
| Borde | 1px `#CCA43B` con opacidad 30% | 1px `#CCA43B` con opacidad 20% |
| Texto | `#FFFFFF` | `#1A1A1A` |
| Action | `#CCA43B` | `#CCA43B` |
| Border radius | 12px | 12px |

---

## D. Transiciones y Micro-interacciones

### 1. Toggle entre modo Oscuro/Claro

| Propiedad | Valor |
|-----------|-------|
| Trigger | Desde configuracion o boton dedicado en AppBar |
| Animacion | `AnimatedTheme` con duracion 400ms |
| Curva | `Curves.easeInOut` |
| Efecto | Crossfade entre temas (el scaffold, cards, textos cambian suavemente) |
| Icono | `Icons.dark_mode` / `Icons.light_mode` |
| Color icono | `#CCA43B` (activo siempre visible) |

### 2. Animacion de Tarjetas al Aparecer

| Elemento | Animacion | Duracion | Curva |
|----------|-----------|----------|-------|
| HymnCard al hacer scroll | Fade-in + slide-up (20px offset) | 300ms | `Curves.easeOut` |
| HymnCard al togglear filtro | Fade-out + fade-in | 200ms | `Curves.easeInOut` |
| Estrofas en hymn_detail | Fade-in secuencial (cada 100ms delay) | 300ms | `Curves.easeOut` |
| Chips de filtro | AnimatedContainer (color, borde) | 200ms | `Curves.easeInOut` |

### 3. Animacion de Acordes

| Interaccion | Animacion | Duracion | Curva |
|-------------|-----------|----------|-------|
| Cambiar color de acordes | Crossfade instantaneo | 200ms | `Curves.easeInOut` |
| Mostrar/ocultar acordes | AnimatedSwitcher con fade | 200ms | `Curves.easeInOut` |
| Transicion entre estrofas | AnimatedSwitcher con fade | 300ms | `Curves.easeIn` / `Curves.easeOut` |
| Scroll a estrofa especifica | `Scrollable.ensureVisible` | 150ms | `Curves.easeInOut` |

### 4. FAB Menu

| Propiedad | Valor |
|-----------|-------|
| Apertura | 250ms, `Curves.easeInOut` |
| Cierre | 250ms, `Curves.easeInOut` (reverse) |
| Icono | `AnimatedIcons.menu_close` |
| Haptic | `HapticFeedback.lightImpact()` al abrir |
| Opacidad de fondo | No aplicar overlay oscuro (el menu es compacto) |

### 5. Hover / Active States

| Elemento | Hover | Active/Pressed |
|----------|-------|----------------|
| HymnCard | `#FFFFFF` con opacidad 5% overlay (dark) | `#FFFFFF` con opacidad 10% overlay |
| FilterChip | gold con opacidad 10% | gold con opacidad 20% |
| IconButton | `#FFFFFF` con opacidad 8% (dark) | `#FFFFFF` con opacidad 12% (dark) |
| FAB | gold con opacidad 90% | goldDark `#8B7330` |
| Slider thumb | gold + escala 1.2x | escala normal |

### 6. Transiciones de Pantalla

| Transicion | Duracion | Curva |
|------------|----------|-------|
| Home -> HymnDetail | Slide-up (Push) | 300ms, `Curves.easeInOut` |
| HymnDetail -> Home | Slide-down (Pop) | 300ms, `Curves.easeInOut` |
| Fullscreen mobile | AnimatedSwitcher fade | 300ms, `Curves.easeIn`/`easeOut` |
| Sheet (Brocha/Nota/Solfa) | Slide-up nativo Material | segun plataforma |

---

## Hallazgos Visuales Mas Importantes

1. **Color default de acordes debe cambiar**: Actualmente es purpura `#6750A4` (tanto en `_chordColors` como en `HymnAppearanceState.chordColor`). Debe ser DORADO `#CCA43B`.

2. **Tema actual usa `colorSchemeSeed` con azul**: `app_theme.dart` usa `Color(0xFF1A237E)` como seed. Esto genera paletas automaticas impredecibles. La migracion debe reemplazar esto con un `ColorScheme` completamente manual.

3. **HymnDetailScreen ya usa opacidad para glassmorphism**: Las tarjetas de estrofa usan `Colors.white.withValues(alpha: appearance.cardOpacity)`. Esta es una base solida que solo requiere ajustar el color base y aniadir el `BackdropFilter`.

4. **ProjectionApp tiene su propio tema inline**: En `projection_app.dart` linea 286-292, se crea un `ThemeData` con `ColorScheme.fromSeed(seedColor: Colors.indigo)`. Esto debe sincronizarse con la nueva paleta.

5. **ResponsiveChordWidget tiene color default hardcodeado**: Linea 49: `color: Colors.blue`. Debe cambiarse a `color: Colors.amber.shade700` o `Color(0xFFCCA43B)`.

6. **La paleta de colores de texto y acordes en Brush Sheet estan hardcodeadas**: Las listas `_textColors` y `_chordColors` en `control_sheets.dart` son listas estaticas. Deberian poder definirse centralizadamente desde el tema.

---

## Recomendaciones para @dev

### Prioridad Critica (P0)

1. **Reemplazar `colorSchemeSeed` por `ColorScheme` manual en `app_theme.dart`**: Crear dos `ColorScheme` (light y dark) con los valores exactos especificados en la seccion A de este documento. No usar ningun `fromSeed`.

2. **Cambiar default de `chordColor`**: En `appearance_provider.dart`, linea 28, cambiar `const Color(0xFF6750A4)` por `const Color(0xFFCCA43B)`.

3. **Cambiar default de `_chordColors`**: En `control_sheets.dart`, linea 36-43, reemplazar la lista completa por la nueva especificada en la seccion C.7.

4. **Cambiar color default de acordes en `ResponsiveChordWidget`**: Linea 49, cambiar `Colors.blue` por `const Color(0xFFCCA43B)`.

### Prioridad Alta (P1)

5. **Actualizar `projection_app.dart`**: Reemplazar el tema inline (lineas 286-292) para que use el mismo `ColorScheme.dark` manual, con fondo `Colors.black` y primary `Colors.white`.

6. **Aplicar glassmorphism en HymnCard**: Aniadir `BackdropFilter` con `ImageFilter.blur` y el color de fondo especificado. Mantener `elevation: 0`.

7. **Actualizar PresentButton**: Cambiar `primaryContainer` por `#CCA43B` (goldPrimary) y `errorContainer` por error con opacidad 20%.

8. **Actualizar FabMenu**: Cambiar `tertiaryContainer`/`secondaryContainer` por `#CCA43B` (goldPrimary) para todas las opciones. El icono debe ser `#1A1A1A`.

### Prioridad Media (P2)

9. **Migrar a surface tokens**: Reemplazar usos de `surfaceContainerHighest`, `surfaceContainerLow`, etc., para que coincidan con los valores de la paleta (ver seccion A).

10. **Actualizar FilterChips en HomeScreen**: Cambiar `primaryContainer`/`onPrimaryContainer` por fondo gold y texto negro.

11. **Sincronizar colores de acordes entre personal y proyeccion**: El `live_projection_screen.dart` ya lee `appearance.chordColor` del provider, pero asegurarse de que el valor default sea gold.

12. **Consolidar las listas de colores**: Extraer `_chordColors` y `_textColors` a constantes del tema o a un archivo separado de constantes de diseno.

### Prioridad Baja (P3)

13. **Implementar transiciones**: Aniadir las animaciones especificadas en la seccion D.
14. **Actualizar icono de la AppBar**: El titulo actual es 'MQ App' en HomeScreen. Sugerencia: 'HimnarioID' o un logo.
15. **Crear un widget reutilizable de Glassmorphism**: Para evitar repetir el `ClipRRect + BackdropFilter + Container` en cada componente.

---

## Riesgos Visuales Identificados

### Riesgo 1: Contraste insuficiente del dorado sobre fondos claros
- **Problema**: `#CCA43B` sobre `#FEFAF0` (blanco roto) tiene un contraste de aproximadamente 2.5:1, que NO cumple WCAG AA (4.5:1 para texto normal).
- **Mitigacion**: Para texto sobre light mode, usar `#8B7330` (goldDark) que tiene mejor contraste. Para fondos grandes (botones) usar `#CCA43B` con texto `#FFFFFF` o `#1A1A1A`, no texto dorado sobre fondo claro.

### Riesgo 2: Rendimiento del glassmorphism en dispositivos moviles de gama baja
- **Problema**: `BackdropFilter` con `ImageFilter.blur` es costoso en GPU. Si hay multiples tarjetas con glassmorphism visibles simultaneamente, el framerate puede caer.
- **Mitigacion**: Limitar el glassmorphism a:
  - HymnCard (solo la visible en pantalla — ListView recicla)
  - Sheet activo (solo uno a la vez)
  - No usar en proyeccion
  - Considerar `sigmaX: 8, sigmaY: 8` en dispositivos lentos

### Riesgo 3: Diferencias entre el tema de proyeccion y el tema personal
- **Problema**: Actualmente `projection_app.dart` crea su propio `ThemeData` independiente. Si no se sincroniza, los colores de acordes, texto y fuente pueden diferir entre la vista personal y la proyeccion.
- **Mitigacion**: Centralizar la creacion del `ColorScheme` oscuro en una funcion estatica en `AppTheme` que ambos modos compartan. El tema de proyeccion debe ser una variante del dark theme, no un tema independiente.

### Riesgo 4: Perdida de la jerarquia visual si todo es glassmorphism
- **Problema**: Si todos los contenedores usan el mismo nivel de transparencia y blur, se pierde la distincion entre superficie, contenedor elevado y modal.
- **Mitigacion**: Mantener la jerarquia de opacidad:
  - Fondo: opaco (`#121212` o `#000000`)
  - SurfaceContainer: opaco (`#1E1E1E`)
  - Cards/Sheets: glass 10-15%
  - Dialogs/Modales: glass 15-20% + blur mas fuerte

### Riesgo 5: El dorado puede saturarse visualmente
- **Problema**: Usar `#CCA43B` en FAB, chips seleccionados, switches, iconos activos, acordes, y bordes puede resultar en sobrecarga visual.
- **Mitigacion**: Estrategia de "un dorado a la vez". En la pantalla de detalle del himno:
  - Si los acordes son dorados, el FAB debe ser dorado pero los chips no deben estarlo (usar goldLight `#E8D48B` en su lugar).
  - En HomeScreen, los chips seleccionados pueden usar gold, pero los iconos de la AppBar deben ser onSurfaceVariant (gris), no gold, a menos que esten en estado activo.

### Riesgo 6: Compatibilidad con temas personalizados del usuario
- **Problema**: El usuario puede cambiar colores de texto y acordes desde Brush Sheet. Si el default es gold pero el usuario elige otro color, el tema visual puede perder coherencia.
- **Mitigacion**: No mitigar — es funcionalidad intencional. Solo asegurarse de que el reset (`HymnAppearanceState.reset()`) devuelva todo a los valores gold/corporativos.

---

> Fin del documento de especificaciones de diseno.
> Comunicar a @dev cualquier duda o discrepancia encontrada durante la implementacion.
