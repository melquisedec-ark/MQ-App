# Wireframe 01 — Pantalla Principal (Home)

> **Pantalla:** Landing al abrir la app
> **Archivo destino (Flutter):** `lib/presentation/views_personal/home/home_screen.dart`
> **Versión:** MQ App v1.0
> **Referencia:** `nuevaidea.md` §3 (Pantalla Principal) + revisiones v1.0–v1.4
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

## 11. Preguntas abiertas para el usuario

> Estas preguntas las dejo planteadas para que se resuelvan **antes** de implementar:

1. **¿La card de versículo debe tener animación de entrada?** (slide-up vs fade-in vs ninguna).
2. **¿El versículo se actualiza en background** cada X horas aunque la app esté abierta? (Sugerencia: no, solo en cold start o tap en refresh).
3. **¿Qué pasa si el usuario presiona `[*]` y el versículo YA está en favoritos?** Sugerencia: confirmar con snackbar "Ya está en tus favoritos" o quitarlo sin pedir confirmación. Decisión de UX.
4. **¿La card de versículo debe ser un "mini-reader"** (mostrar 1 versículo con scroll) o solo el preview? (Spec dice preview — confirmado).
5. **¿El bottom nav (Historial, Favoritos, Notas) entra en v1.0 o se difiere?** Spec dice "only for v1.0" pero el cuerpo del spec no lo desarrolla — confirmar.

---

*Wireframe creado por @design — pendiente revisión de @arqui y del usuario antes de implementar.*
