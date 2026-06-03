# Wireframe 01 — Pantalla Principal (Home)

> **Pantalla:** Landing al abrir la app
> **Archivo destino (Flutter):** `lib/presentation/views_personal/home/home_screen.dart` + `lib/features/himnario/presentation/screens/himnario_home_screen.dart` (sección 13)
> **Versión:** MQ App v1.0.1 (actualizado 2026-06-02 — FAB temático y card Administrar agregados)
> **Referencia:** `nuevaidea.md` §3 (Pantalla Principal) + revisiones v1.0–v1.4
> **Decisiones v1.0.1 aplicadas:** D3 (FAB temático), D4 (sin glassmorphism), D8 (Administrar himnario)
> **Idioma:** Español (es-419)

---

## 1. Propósito

Es la **primera pantalla** que ve el usuario al abrir la app. Su objetivo es:

1. **Ofrecer acceso rápido** a los dos módulos principales (Biblia + Himnario).
2. **Mostrar inspiración diaria** con un versículo aleatorio distinto en cada apertura.
3. **Centralizar configuración y conectividad** (antes dispersas en HimnarioID 2.0).

No es una pantalla de lectura — es un **hub de navegación**. Cualquier acción directa (leer, buscar, configurar) debe completarse en 1–2 toques desde aquí.

---

## 2. Layout principal (Portrait, móvil)

```
+------------------------------------------------------------------------------+
| [O]                                                                  [R]     |  <- Fila superior
|                                                                              |     O = Configuracion
|                                                                              |     R = Conectar
+------------------------------------------------------------------------------+
|                                                                              |
|                          +========================+                          |
|                          |                        |                          |
|                          |       MQ App           |                          |  <- Logo + tagline
|                          |   Biblia + Himnario    |                          |
|                          |                        |                          |
|                          +========================+                          |
|                                                                              |
|   +----------------------------------------------------------------------------+
|   |   Versiculo del dia                                                        |
|   |                                                                            |
|   |   "Porque yo se los pensamientos que tengo acerca de vosotros,             |
|   |    dice Jehova, pensamientos de paz, y no de mal, para daros              |
|   |    el fin que esperais."                                                   |
|   |                                                                            |
|   |   Jeremias 29:11     [RV1909 v]                              [*]  [<>]   |  <- [*]=favorito
|   |                                                                            |     [<>=]refresh
|   |                            [ Leer este versiculo --> ]                     |
|   +----------------------------------------------------------------------------+
|                                                                              |
|   +------------------------+    +------------------------+                    |
|   |                        |    |                        |                    |
|   |   [B]  BIBLIA          |    |   [M]  HIMNARIO        |                    |  <- 2 cards
|   |       Reina Valera     |    |       [N] himnos       |                    |     50/50
|   |       1909 / 1569      |    |       disponibles      |                    |
|   |                        |    |                        |                    |
|   +------------------------+    +------------------------+                    |
|                                                                              |
+------------------------------------------------------------------------------+
```

### Anotaciones

- **[O] / [R]:** Iconos circulares (40x40). El primero va a Settings; el segundo abre el sheet de conexión mDNS.
- **Logo MQ App:** Bloque centrado, ~120dp ancho. Es solo texto + icono (no usar el `iconoMQ.png` completo, queda grande).
- **Tagline:** Texto pequeño (12sp), debajo del logo, color secundario.
- **Card de versículo:** Card principal (~80% del ancho). Fondo tipo glassmorphism (consistente con HimnarioID 2.0).
- **Card Biblia / Himnario:** Toca cada una → push de la pantalla correspondiente.

---

## 3. Detalle de la card de versículo

```
+----------------------------------------------------------------------------+
|   Versiculo del dia                                                          |
|                                                                              |
|   "Porque yo se los pensamientos que tengo acerca de vosotros,               |
|    dice Jehova, pensamientos de paz, y no de mal, para daros                |
|    el fin que esperais."                                                     |
|                                                                              |
|   Jeremias 29:11     [RV1909 v]                              [*]  [<>]     |
|                                                                              |
|                              [ Leer este versiculo --> ]                     |
+----------------------------------------------------------------------------+
```

### Elementos

| Elemento | Tipo | Comportamiento |
|---------|------|----------------|
| `"Porque yo se..."` | Texto del versículo (18sp, line-height 1.6) | Truncado a 4 líneas con `...` si es muy largo; tap en el card = misma acción que "Leer este versículo" |
| `Jeremias 29:11` | Referencia (14sp, bold, color primario) | Tap = navega a Génesis del Libro (no al versículo — la referencia es puramente informativa) |
| `[RV1909 v]` | Dropdown de versión (chip con flecha) | Tap = muestra bottom sheet con las 2 versiones disponibles. Al cambiar, el texto del versículo se actualiza a la misma referencia en la otra versión |
| `[*]` | Botón favorito (icon star) | Tap = toggle favorito. Si ya está marcado, muestra toast "Quitado de favoritos" |
| `[<>]` | Botón refresh (icon refresh) | Tap = genera **otro** versículo aleatorio (no requiere abrir/cerrar la app) |
| `[ Leer este versiculo --> ]` | Botón outlined, full-width | Tap = navega al Reader screen con esa referencia precargada (libro, capítulo, versículo) |

### Estado: Versículo sin favoritos (cold start)

- Al **abrir la app por primera vez** en la sesión, se genera UN versículo aleatorio.
- El cálculo (de `nuevaidea.md` §3.3) es `Random.nextInt(31102)` sobre la tabla `versiculo` de la versión preferida del usuario.
- Si el usuario **cierra y vuelve a abrir** la app → nuevo versículo aleatorio (no persiste).
- Si el usuario **solo presiona `[*]`** → el versículo se guarda en `favorito_versiculo` con timestamp. Persiste entre sesiones.
- Si el usuario presiona **`[<>]`** → versículo cambia, no se guarda automáticamente.

### Estado: Cargando versículo aleatorio

```
+----------------------------------------------------------------------------+
|   Versiculo del dia                                                          |
|                                                                              |
|                            [ spinner ~~~~~ ]                                 |
|                                                                              |
|                          Cargando versiculo...                               |
|                                                                              |
+----------------------------------------------------------------------------+
```

Tiempo esperado: < 200ms (consulta indexada). Si tarda más, mostrar skeleton text.

### Estado: Error de carga (BD no disponible)

```
+----------------------------------------------------------------------------+
|   Versiculo del dia                                                          |
|                                                                              |
|                          [!] No se pudo cargar                               |
|                                                                              |
|                          [ Reintentar ]                                      |
|                                                                              |
+----------------------------------------------------------------------------+
```

Tap en "Reintentar" dispara la consulta de nuevo. No bloquear las cards de Biblia/Himnario: deben seguir siendo tappables aunque el versículo falle.

---

## 4. Dropdown de versión (Bottom Sheet)

Al tap en `[RV1909 v]`:

```
+----------------------------------------------------------------------------+
|                                                                              |
|   +------------------------------------------------------------------------+|
|   |   Seleccionar version                                                    ||
|   |                                                                          ||
|   |   [check]  Reina Valera 1909                              <- actual     ||
|   |             Dominio Publico                                              ||
|   |                                                                          ||
|   |   [   ]   Reina Valera 1569 (Biblia del Oso)                            ||
|   |             Dominio Publico                                              ||
|   |                                                                          ||
|   +------------------------------------------------------------------------+|
|                                                                              |
|   "Al cambiar, el versiculo actual (Jeremias 29:11) se mantiene."          |
|                                                                              |
+----------------------------------------------------------------------------+
```

- El sheet es **persistente**: el cambio se aplica inmediatamente al cerrar.
- El **checkmark** indica la versión actual.
- Solo se listan las versiones **instaladas** en la BD local. Si RV1569 no se descargó aún, no aparece (futuro: instalador de versiones).

---

## 5. Las 2 cards principales (Biblia / Himnario)

```
+------------------------+    +------------------------+
|                        |    |                        |
|   [B]  BIBLIA          |    |   [M]  HIMNARIO        |
|       Reina Valera     |    |       [N] himnos       |
|       1909 / 1569      |    |       disponibles      |
|                        |    |                        |
+------------------------+    +------------------------+
```

### Biblia card

| Atributo | Valor |
|----------|-------|
| Icono | `Icons.menu_book_rounded` (40dp, gold) |
| Título | "BIBLIA" (24sp, bold) |
| Subtítulo | "Reina Valera 1909 / 1569" (12sp, color secundario) |
| Color de fondo | Glassmorphism (consistente con HymnCard) |
| Acción | Tap → push `BibleHomeScreen` (selector de libros) |
| Long press | (futuro) Mostrar opciones: última lectura, aleatorio directo |

### Himnario card

| Atributo | Valor |
|----------|-------|
| Icono | `Icons.music_note_rounded` (40dp, gold) |
| Título | "HIMNARIO" (24sp, bold) |
| Subtítulo | "[N] himnos disponibles" — se cuenta de la tabla `Himno` (12sp, color secundario) |
| Color de fondo | Glassmorphism |
| Acción | Tap → push `HymnListScreen` (lista A-Z existente en HimnarioID 2.0) |

### Estado: Himnario sin himnos (BD vacía)

```
+------------------------+
|                        |
|   [M]  HIMNARIO        |
|       Sin himnos       |
|       cargados         |
|                        |
+------------------------+
```

Tap debe mostrar mensaje en lugar de navegar.

---

## 6. Fila superior (Settings + Connect)

```
+------------------------------------------------------------------------------+
| [O]                                                                  [R]     |
+------------------------------------------------------------------------------+
```

| Botón | Icono | Posición | Acción |
|-------|-------|----------|--------|
| Configuración | `Icons.settings_rounded` | Top-left | Tap → push `SettingsScreen` (settings: tema, versión default, modo emisor, glass, fondo) |
| Conectar | `Icons.cast_rounded` | Top-right | Tap → push `DiscoverDisplaySheet` (selector Emisor/Receptor + escaneo mDNS — **reusar el widget existente de HimnarioID 2.0**) |

> **Decisión heredada de HimnarioID 2.0:** Los iconos son circulares con fondo glassmorphism sutil. Sin texto, solo icono. Esto ahorra espacio horizontal y se ve limpio en mobile.

---

## 7. Responsive — Tablet y Desktop

### Tablet (≥ 600dp ancho)

```
+------------------------------------------------------------------------------+
| [O]                                                                  [R]     |
+------------------------------------------------------------------------------+
|                                +================+                            |
|                                |    MQ App      |                            |
|                                | Biblia + Himn. |                            |
|                                +================+                            |
|                                                                              |
|   +------------------------------------------------------------------------+ |
|   |   Versiculo del dia                                                      | |
|   |   "Porque yo se..."                                                     | |
|   |   Jeremias 29:11     [RV1909 v]                            [*]  [<>]   | |
|   |                              [ Leer este versiculo --> ]               | |
|   +------------------------------------------------------------------------+ |
|                                                                              |
|   +--------------------+    +--------------------+                           |
|   |  [B] BIBLIA        |    |  [M] HIMNARIO      |                           |
|   +--------------------+    +--------------------+                           |
+------------------------------------------------------------------------------+
```

- Las cards de Biblia/Himnario crecen de ancho pero NO de alto.
- La card de versículo ocupa 70% del ancho, centrado.

### Desktop / Web (≥ 1024dp ancho)

```
+------------------------------------------------------------------------------+
| [O]                                                                  [R]     |
+------------------------------------------------------------------------------+
|                                                                              |
|      +================+    +-----------------------------------------+       |
|      |    MQ App      |    |   Versiculo del dia                      |       |
|      | Biblia + Himn. |    |   "Porque yo se..."                     |       |
|      +================+    |   Jeremias 29:11 [v]  [*]  [<>]        |       |
|                             |   [ Leer este versiculo --> ]          |       |
|                             +-----------------------------------------+       |
|                                                                              |
|      +--------------------+    +--------------------+                         |
|      |  [B] BIBLIA        |    |  [M] HIMNARIO      |                         |
|      +--------------------+    +--------------------+                         |
|                                                                              |
|  [ Presentar ]   <- Solo desktop, abre modo receptor                        |
+------------------------------------------------------------------------------+
```

- El logo + tagline se mueve a la **izquierda** (en columna).
- La card de versículo ocupa la columna derecha.
- Aparece botón flotante **"Presentar"** abajo a la izquierda (solo desktop, oculto en móvil).
- Las 2 cards siguen 50/50, pero ahora en una fila de 2 columnas centradas.

---

## 8. Accesibilidad (WCAG 2.1 AA)

| Criterio | Implementación |
|----------|----------------|
| Contraste de texto | Texto principal ≥ 7:1 sobre fondo. Texto secundario ≥ 4.5:1. Verificar con `onSurface` del tema. |
| Tamaño mínimo de touch target | 48x48dp para todos los botones (Settings, Connect, Favorito, Refresh, Cards). |
| Lectores de pantalla | `Semantics` widget en cada card con label completo: "Biblia, botón. Abre el módulo de Biblia Reina Valera." |
| Reducción de movimiento | El versículo aleatorio NO debe animarse (no slide-in). Solo fade-in de 200ms si lo hay. |
| Modo oscuro | Toda la paleta debe funcionar en dark mode (ver `05_style_guide.md`). |
| Tamaño de fuente | Respeta la preferencia del SO (escala tipográfica). El texto del versículo usa `MediaQuery.textScaler`. |

---

## 9. Estados especiales

### 9.1 Cold start (primera vez, sin datos)

- Si la BD no está inicializada → splash screen primero (gestionado en `bootstrap/`).
- Si la BD falla al cargar → mostrar pantalla de error full-screen, NO la home degradada.

### 9.2 Sin conexión (offline)

- El indicador `[R]` (Conectar) muestra un punto rojo pequeño si no hay dispositivo emparejado.
- La app sigue siendo 100% funcional offline — Biblia e Himnario son locales.
- Solo se deshabilita el botón "Presentar" del receptor si no hay emisor emparejado.

### 9.3 Modo emisor activo

- Cuando el usuario está controlando un receptor, aparece un **banner** sutil arriba de la card de versículo:

```
+------------------------------------------------------------------------------+
| [O]                                                                  [R]     |
+------------------------------------------------------------------------------+
| [i]  Controlando: Sala Principal (192.168.1.42)               [X] Descon.   |  <- Banner
+------------------------------------------------------------------------------+
|   ...                                                                          |
```

- El banner es **dismissable** con `[X]` (cierra la sesión emisor).
- Si el receptor cambia de módulo (Biblia → Himnario), el banner se actualiza (ver wireframe `03_emitter_views.md`).

---

## 10. Métricas de éxito (a validar post-implementación)

- **Tiempo hasta primera acción:** El usuario debe poder navegar a Biblia o Himnario en ≤ 2 toques. ✓ (1 tap desde la card)
- **Versículo aleatorio carga < 200ms** en móvil gama media. ✓ (consulta indexada)
- **0 errores en cold start** (BD no inicializada) — el splash debe manejar esto.

---

## 11. Preguntas abiertas para el usuario (v1.0)

> Estas preguntas las dejo planteadas para que se resuelvan **antes** de implementar:

1. **¿La card de versículo debe tener animación de entrada?** (slide-up vs fade-in vs ninguna).
2. **¿El versículo se actualiza en background** cada X horas aunque la app esté abierta? (Sugerencia: no, solo en cold start o tap en refresh).
3. **¿Qué pasa si el usuario presiona `[*]` y el versículo YA está en favoritos?** Sugerencia: confirmar con snackbar "Ya está en tus favoritos" o quitarlo sin pedir confirmación. Decisión de UX.
4. **¿La card de versículo debe ser un "mini-reader"** (mostrar 1 versículo con scroll) o solo el preview? (Spec dice preview — confirmado).
5. **¿El bottom nav (Historial, Favoritos, Notas) entra en v1.0 o se difiere?** Spec dice "only for v1.0" pero el cuerpo del spec no lo desarrolla — confirmar.

---

# 12. FAB Temático (NUEVO v1.0.1)

> **Versión:** v1.0.1 | Agregado: 2026-06-02 | Por: @design
> **Estado:** ✅ FAB con animación sol/luna (decisión D3 de `CONTROL/DECISIONES.md`)
> **Origen:** F3 de `CONTROL/PENDIENTE.md` + observación #4 del usuario en `BITACORA.md`

## Propósito

Ofrecer un **acceso directo al cambio de tema** desde la pantalla principal, sin necesidad de abrir Configuración. El FAB refleja el estado actual del tema (sol = light, luna = dark, sol+luna = system) y permite el cambio con un solo tap.

## Vista (Portrait, móvil)

```
+------------------------------------------------------------------------------+
| [O]                                                                  [R]     |
+------------------------------------------------------------------------------+
|                                                                              |
|                          +========================+                          |
|                          |       MQ App           |                          |
|                          |   Biblia + Himnario    |                          |
|                          +========================+                          |
|                                                                              |
|   +----------------------------------------------------------------------------+
|   |   Versiculo del dia                                                        |
|   |   "Porque yo se los pensamientos..."                                       |
|   |   Jeremias 29:11     [RV1909 v]                              [*]  [<>]   |
|   |                            [ Leer este versiculo --> ]                     |
|   +----------------------------------------------------------------------------+
|                                                                              |
|   +------------------------+    +------------------------+                    |
|   |   [B]  BIBLIA          |    |   [M]  HIMNARIO        |                    |
|   |       Reina Valera     |    |       250 himnos       |                    |
|   |       1909             |    |       disponibles      |                    |
|   +------------------------+    +------------------------+                    |
|                                                                              |
|                                                                              |
|                                                                              |
|                                                                              |
|                                                                            [O]|  <- FAB (bottom-right)
+------------------------------------------------------------------------------+
```

## Vista detallada del FAB

El FAB es un **circular de 56dp** anclado a la esquina inferior derecha, con safe area:

```
                                                       +----+
                                                       | [] |  <- FAB
                                                       +----+
                                                          ↑
                                            (16dp margin + safeArea bottom)
```

### Apariencia según tema

| Modo | Icono | Color de fondo | Color del icono |
|------|-------|----------------|-----------------|
| **Light** | `Icons.light_mode_rounded` (sol) | `goldPrimary` (#CCA43B) | `onPrimary` negro |
| **Dark** | `Icons.dark_mode_rounded` (luna) | `goldPrimary` (#CCA43B) | `onPrimary` negro |
| **System** | `Icons.brightness_auto_rounded` (auto) | `goldPrimary` (#CCA43B) | `onPrimary` negro |

> **Decisión:** el FAB siempre tiene fondo gold (consistente con la identidad de marca). Solo cambia el icono. Esto lo hace reconocible y consistente.

### Animación de transición (sol ↔ luna)

```dart
AnimatedSwitcher(
  duration: Duration(milliseconds: 250),
  transitionBuilder: (child, anim) {
    return RotationTransition(
      turns: Tween<double>(begin: 0.75, end: 1.0).animate(anim),
      child: FadeTransition(opacity: anim, child: child),
    );
  },
  child: Icon(
    _getIconForMode(themeMode),
    key: ValueKey(themeMode),  // <- importante para que AnimatedSwitcher detecte el cambio
    color: cs.onPrimary,
    size: 24,
  ),
)
```

- **Duración:** 250ms (consistente con el resto de la app)
- **Curva:** `Curves.easeInOutCubic`
- **Rotación:** 270° → 360° (cambio sutil, no mareante)

## Comportamiento

### Tap corto

`cycleMode()` — alterna entre los 3 modos en orden:

```
[System]  --tap-->  [Light]  --tap-->  [Dark]  --tap-->  [System]
```

Implementación:

```dart
extension on ThemeMode {
  ThemeMode get cycle {
    switch (this) {
      case ThemeMode.system: return ThemeMode.light;
      case ThemeMode.light:  return ThemeMode.dark;
      case ThemeMode.dark:   return ThemeMode.system;
    }
  }
}

void _onTap() {
  final current = ref.read(themeModeProvider);
  ref.read(themeModeProvider.notifier).setThemeMode(current.cycle);
}
```

### Long press

Abre un **BottomSheet con las 3 opciones** explícitas (RadioListTile):

```
+----------------------------------------------------------------+
|                                                                |
|   Tema de la aplicacion                                        |  <- título (titleMedium)
|                                                                |
|   [ O ]  Sistema     Sigue la configuracion del dispositivo    |  <- RadioListTile
|   [ O ]  Claro       Fondo blanco, texto oscuro                |
|   [ ● ]  Oscuro      Fondo negro, texto blanco    <- actual    |  <- selected
|                                                                |
+----------------------------------------------------------------+
```

- **Drag handle bar** arriba (24x4dp, `outline` color)
- **Border radius top:** 24px
- **Padding:** 24dp lateral, 16dp top, 24dp bottom (safe area)
- **Tap en una opción:** `setThemeMode(mode)` + cierre automático del sheet
- **Sin glassmorphism** (D4): fondo `surfaceContainer` sólido

### Persistencia

- El cambio de tema se persiste en `Configuracion` (clave `ui.theme_mode`).
- **Provider único consolidado** (D2): `themeModeProvider` en `biblia_config_provider.dart:19` (NO el duplicado de `shared_widgets/providers/`).
- La preferencia se aplica globalmente al `MaterialApp` en `main.dart` (fix de 1 línea que lee del provider vía `Consumer`).

## Visibilidad del FAB

| Pantalla | ¿Visible? | Razón |
|----------|-----------|-------|
| Home Biblia (`home_screen.dart`) | ✅ SÍ | Es una pantalla principal |
| Home Himnario (`himnario_home_screen.dart`) | ✅ SÍ | Es una pantalla principal |
| Bible Reader (modo verso o capítulo) | ❌ NO | Pantalla de lectura, no se cambia tema en medio de la lectura |
| Hymn Detail | ❌ NO | Pantalla de detalle |
| Settings | ❌ NO | El setting de tema está AQUÍ, sería redundante |
| Bible Search | ❌ NO | Pantalla auxiliar |
| Admin Himnario | ❌ NO | Pantalla auxiliar |
| Acerca de | ❌ NO | Pantalla informativa |

**Implementación:** el FAB se renderiza en un wrapper compartido `BottomRightButtons` que solo aparece en las home screens.

## Componente reusable (BottomRightButtons)

```dart
// lib/presentation/shared_widgets/bottom_right_buttons.dart (NUEVO)
class BottomRightButtons extends StatelessWidget {
  final Widget child;
  
  // Stack con:
  // - child (el body de la pantalla)
  // - Positioned (right: 16, bottom: 16 + safeArea)
  //   - Column con ThemeModeToggleButton y otros FABs futuros
}
```

> **Decisión:** extraer este patrón desde `mq_dual_app.dart:98-121` (código a eliminar en D12). Es reusable para futuros FABs (e.g., "compartir" en Bible Reader).

## Elementos

| Elemento | Tipo | Posición | Acción |
|----------|------|----------|--------|
| FAB temático | `FloatingActionButton.small` (56dp) | Bottom-right (16 + safeArea) | Tap = cycle / Long press = bottomSheet |

## Componentes reutilizados

- **`ThemeModeToggleButton`** (existente, `lib/presentation/shared_widgets/theme_mode_toggle_button.dart`) — reusar tal cual, extender con `onLongPress` (decisión D3, ~3 líneas).
- **`themeModeProvider`** (existente en `biblia_config_provider.dart:19`) — consumir vía `ref.watch(themeModeProvider)`. NO crear provider nuevo.
- **`BottomRightButtons`** (nuevo, extraer patrón de `mq_dual_app.dart`) — wrapper de Stack + Positioned + Column.
- **Sin glassmorphism** (D4/D14): FAB Material 3 estándar con fondo `goldPrimary`.

## Accesibilidad (WCAG 2.1 AA)

| Criterio | Implementación |
|----------|----------------|
| Touch target | 56dp (cumple ≥ 48dp) |
| Contraste icono | `onPrimary` (negro #1A1A1A) sobre `goldPrimary` (#CCA43B): ratio 8.6:1 ✓ |
| Semantics | `Semantics(label: 'Cambiar tema, modo actual: ${_labelMode(themeMode)}', button: true, onTap: ..., onLongPress: ...)` |
| Haptic feedback | Vibración sutil al cambiar modo (toggle en settings) |

## Cambios vs versión anterior

- **Nuevo FAB en esquina inferior derecha** del Home Biblia + Home Himnario.
- Reutiliza `ThemeModeToggleButton` existente (NO widget nuevo).
- Nueva dependencia de UI: `BottomRightButtons` wrapper.
- Sincronización con Configuración → Apariencia (ambos leen del mismo provider).

## Preguntas abiertas

1. **¿El FAB debe tener un label extendido** (e.g., "Tema: Oscuro" con `FloatingActionButton.extended`) o solo el icono? Sugerencia: solo icono (más limpio, no compite con el versículo del día). El label está disponible en el bottomSheet de long press.

2. **¿Debe haber un FAB secundario** para "conectar" o "compartir"? Sugerencia: NO en v1.0.1. El `[R]` (Conectar) ya está en el AppBar.

3. **El usuario mencionó `gold #D4A574` para el FAB.** El style guide LOCKED dice `goldPrimary = #CCA43B`. **Conflicto:** usar #CCA43B (lock).

4. **¿El long press debe vibrar** (haptic feedback) para indicar que hay más opciones? Sugerencia: SÍ, coherente con el patrón de FABs en iOS/Material 3.

---

# 13. HimnarioHomeScreen — Card "Administrar himnario" (NUEVO v1.0.1)

> **Versión:** v1.0.1 | Agregado: 2026-06-02 | Por: @design
> **Estado:** ✅ Card de descubrimiento (decisión D8 de `CONTROL/DECISIONES.md`)
> **Origen:** F6 de `CONTROL/PENDIENTE.md` + observación #8 del usuario en `BITACORA.md`
> **Archivo destino (Flutter):** `lib/features/himnario/presentation/screens/himnario_home_screen.dart`

## Propósito

Mover la entrada a "Administrar himnario" desde Configuración a la **pantalla principal del Himnario**, donde el usuario espera encontrarla (coherencia: si el himnario tiene un módulo admin, debe ser accesible desde el himnario, no escondido en Configuración).

## Vista (Portrait, móvil)

```
+------------------------------------------------------------------------------+
|  <-  Himnario                            [buscar]                       [⋮]  |  <- AppBar
+------------------------------------------------------------------------------+
|                                                                              |
|   Ultimo himno:                                                              |
|                                                                              |
|   +----------------------------------------------------------------------+   |
|   |  [45]  Sublime gracia                                                |   |  <- card "último himno" (existente)
|   |        Autor: John Newton                          [continuar →]     |   |
|   +----------------------------------------------------------------------+   |
|                                                                              |
|   Himnos recientes (5)                                                       |
|                                                                              |
|   +----------------------------------------------------------------------+   |
|   |  [45]  Sublime gracia                              [★]         [>]   |   |
|   |  [78]  Alabaré                                    [ ]         [>]   |   |
|   |  [12]  Castillo fuerte                            [★]         [>]   |   |
|   |  [203] Cuán grande es Él                          [ ]         [>]   |   |
|   |  [98]  Cordero de Dios                            [ ]         [>]   |   |
|   +----------------------------------------------------------------------+   |
|                                                                              |
|   +----------------------------------------------------------------------+   |
|   |  [tune]  Administrar himnario                                        |   |  <- NUEVA card
|   |          Himnos, catalogos, importar / exportar          [chev >]   |   |
|   +----------------------------------------------------------------------+   |
|                                                                              |
+------------------------------------------------------------------------------+
|  [O]  <- FAB temático (si la pantalla es Home Himnario, ver §12)            |
+------------------------------------------------------------------------------+
```

## Vista detallada de la card

```
+----------------------------------------------------------------------+
|                                                                      |
|   [tune]   Administrar himnario                                       |
|            Himnos, catalogos, importar / exportar              [>]   |
|                                                                      |
+----------------------------------------------------------------------+
```

| Atributo | Valor |
|----------|-------|
| Icono | `Icons.tune_rounded` (28dp, gold) |
| Título | "Administrar himnario" (bodyLarge, 600, onSurface) |
| Subtítulo | "Himnos, catálogos, importar / exportar" (bodySmall, onSurfaceVariant) |
| Trailing | `Icons.chevron_right_rounded` (20dp, onSurfaceVariant) |
| Color de fondo | `surfaceContainer` con elevación 1, sin glassmorphism (D4) |
| Border radius | 16dp |
| Padding | 16dp interno |
| Margin top | 16dp (separación de "Himnos recientes") |
| Margin horizontal | 16dp |
| Acción (tap) | `context.pushNamed('hymn-admin')` |
| Acción alternativa | `AppBar action: Icons.tune_rounded` (opcional, ver pregunta abierta 1) |

## Comportamiento

### Tap

```dart
ListTile(
  leading: Icon(Icons.tune_rounded, color: cs.primary, size: 28),
  title: Text('Administrar himnario'),
  subtitle: Text('Himnos, catálogos, importar / exportar'),
  trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
  onTap: () => context.pushNamed('hymn-admin'),
)
```

Navega a la pantalla `AdminHimnarioScreen` (ver wireframe `07_admin_himnario.md`).

### Sin glassmorphism (D4)

> **Antes:** la card usaba `GlassContainer` con backdrop blur
> **Después:** `Card` Material 3 estándar con `surfaceContainer` + elevación 1

```dart
Card(
  elevation: 1,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  child: ListTile(...),
)
```

## Acceso alternativo desde Configuración (mantener)

En `lib/features/biblia/presentation/screens/settings_screen.dart`, mantener el `ListTile` "Administrar himnario" como **acceso alternativo** (no eliminar):

```dart
ListTile(
  leading: Icon(Icons.tune_rounded),
  title: Text('Administrar himnario'),
  subtitle: Text('Himnos, catálogos, importar / exportar'),
  trailing: Icon(Icons.chevron_right_rounded),
  onTap: () => context.pushNamed('hymn-admin'),
),
```

> **Razón:** algunos usuarios descubren features desde Configuración. Eliminar la entrada ahí reduciría descubribilidad. La card en el Himnario es **adicional**, no reemplazo.

## Cambios vs versión anterior

- **Nueva card "Administrar himnario"** en `HimnarioHomeScreen`, debajo de "Himnos recientes".
- Acceso desde Configuración se mantiene (entrada duplicada, no redundante).
- Consolida "Administrar himnos" + "Catálogos" en una sola entrada (D8).

## Preguntas abiertas

1. **¿La card debe estar en el AppBar como action** (`Icons.tune_rounded`) o como card en el body? Sugerencia: **preferir la card** (D8 lo confirma) porque es más descubrible. El action en AppBar es opcional y puede agregarse en v1.0.2 si la card no se descubre.

2. **¿La card debe mostrar un badge de "Nuevo"** en v1.0.1? Sugerencia: NO. Es una feature, no un upsell. Los usuarios que llegan desde v1.0 ya entienden.

3. **¿La card debe colapsar** en pantallas chicas (e.g., himnario con muchas cards) o siempre visible? Sugerencia: siempre visible. Es importante y debe estar a 1-2 scrolls.

4. **¿La card debe ser un "header"** (sin padding inferior, pegado a los himnos) o un item independiente? Sugerencia: item independiente con margin top 16dp (más limpio).

5. **¿La card debe mostrar el catálogo activo** como subtítulo? (e.g., "Catálogo: Himnario Adventista"). Sugerencia: NO, el subtítulo actual es más claro y universal. El catálogo activo se ve en Admin → Catálogos.

---

*Wireframe actualizado por @design para v1.0.1 — secciones 12 (FAB temático) y 13 (Administrar himnario) agregadas. Decisiones D3 (FAB), D4 (sin glassmorphism) y D8 (Administrar unificado) ya incorporadas. Pendiente revisión de @arqui.*
