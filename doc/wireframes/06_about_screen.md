# Wireframe 06 — Pantalla "Acerca de"

> **Versión:** v1.0.1 | Actualizado: 2026-06-02 | Por: @design
> **Estado:** ✅ Wireframe nuevo (decisión D7 de `CONTROL/DECISIONES.md`)
> **Origen:** F5 de `CONTROL/PENDIENTE.md` + observación #8 del usuario en `BITACORA.md`
> **Archivo destino (Flutter):** `lib/features/biblia/presentation/screens/about_screen.dart`
> **Ruta go_router:** `/acerca-de` (nombre: `about`)
> **Idioma:** Español (es-419)

---

## Propósito

Mostrar **identidad y créditos** de la app en una pantalla estática e informativa:

- Branding (logo + nombre + tagline)
- Versión actual (lectura dinámica vía `package_info_plus`)
- Recursos del proyecto (repo, web, comunidad, licencia)
- Acceso desde Configuración

Es la **puerta de entrada a la comunidad y al código fuente** del proyecto open-source.

---

## Vista (Portrait, móvil)

```
+--------------------------------------------------------------------------+
|  <-                                                     Acerca de       |  <- AppBar
+--------------------------------------------------------------------------+
|                                                                          |
|                                                                          |
|                                                                          |
|                            +------------+                                |
|                            |            |                                |
|                            |   [logo]   |  <- Logo MQ-App 200x200         |
|                            |     MQ     |     (icono central del         |
|                            |            |      himnario/biblia)          |
|                            +------------+                                |
|                                                                          |
|                                                                          |
|                            M Q - A p p                                  |  <- Nombre (displayMedium 28sp, gold)
|                                                                          |
|                            v1.0.1                                       |  <- Versión (caption, onSurfaceVariant)
|                                                                          |
|              Biblia y Himnario en un solo lugar                          |  <- Tagline (bodyMedium, onSurfaceVariant)
|                                                                          |
|                                                                          |
|     +----------------------------------------------------------------+   |
|     |  Informacion                                                   |   |  <- Card "Información" (elevación 1)
|     |  ------------------------------------------------------------  |   |     radius 16dp, padding 16dp
|     |                                                                |   |     SIN glassmorphism (D4)
|     |  [O]  Repositorio                                              |   |
|     |       github.com/melquisedec-ark/MQ-App                        |   |  <- tappable → launchUrl external
|     |                                                                |   |
|     |  [O]  Pagina oficial                                           |   |
|     |       Proximamente                                             |   |  <- deshabilitado (onSurface 30%)
|     |                                                                |   |
|     |  [O]  Comunidad WhatsApp                                       |   |
|     |       Proximamente                                             |   |  <- deshabilitado
|     |                                                                |   |
|     |  [O]  Licencia                                                 |   |
|     |       MIT                                                      |   |  <- no interactivo (chip de solo-lectura)
|     |                                                                |   |
|     +----------------------------------------------------------------+   |
|                                                                          |
|                                                                          |
|     +----------------------------------------------------------------+   |
|     |                                                                |   |
|     |                            Volver                              |   |  <- FilledButton (gold, full width)
|     |                                                                |   |
|     +----------------------------------------------------------------+   |
|                                                                          |
|                                                                          |
+--------------------------------------------------------------------------+
|  [tag]   Hecho con [gold] para la gloria de Dios    <- footer opcional  |
+--------------------------------------------------------------------------+
```

### Anotaciones

- **Logo:** Placeholder visual con la M y Q entrelazadas (estilo monograma), en gold `#CCA43B` sobre fondo transparente. Tamaño 200x200dp centrado.
  - Si no hay asset gráfico todavía, fallback: `Text("MQ")` en `displayLarge` (48sp, 800, gold).
- **Nombre app:** "MQ-App" en `displayMedium` (28sp, 700, gold). Letter-spacing -0.5.
- **Versión:** "v1.0.1" en `bodySmall` (12sp, onSurfaceVariant). Valor leído de `package_info_plus`.
- **Tagline:** "Biblia y Himnario en un solo lugar" en `bodyMedium` (14sp, onSurfaceVariant).
- **Card "Información":** surfaceContainer con elevación 1, radio 16dp, padding interno 16dp. SIN glassmorphism (decisión D4).
- **Botón "Volver":** FilledButton (gold background, onPrimary negro), full width, 48dp de alto. Equivale al botón back del AppBar (redundancia intencional para usuarios que hacen scroll largo).
- **Footer (opcional):** "Hecho con ❤ para la gloria de Dios" en 11sp, goldDark, centrado.

---

## Layout — Items de la card

```
+----------------------------------------------------------------+
|  Informacion                                                   |
|  ------------------------------------------------------------  |
|                                                                |
|  [globe]    Repositorio                                         |
|             github.com/melquisedec-ark/MQ-App                  |
|                                                  [arrow >]     |  <- flecha gold (tappable)
|                                                                |
|  [home]     Pagina oficial                                      |
|             Proximamente                                        |
|                                                  (no flecha)   |  <- disabled (30% opacity)
|                                                                |
|  [chat]     Comunidad WhatsApp                                  |
|             Proximamente                                        |
|                                                  (no flecha)   |  <- disabled
|                                                                |
|  [balance]  Licencia                                            |
|             MIT                                                 |
|                                                  [chip MIT]    |  <- chip de solo-lectura
|                                                                |
+----------------------------------------------------------------+
```

Cada fila es un `ListTile`-like row con:
- **Leading icon:** 24dp, color `primary` (gold) o `onSurface` 30% si está deshabilitado
- **Título:** `bodyLarge` (16sp, 600, onSurface)
- **Subtítulo:** `bodyMedium` (14sp, onSurfaceVariant)
- **Trailing:** Flecha `chevron_right` 20dp gold (solo si es tappable) o chip/nada si deshabilitado

---

## Estados

### Estado: Loading de versión (al abrir)

```
+----------------------------------------------------------------+
|                                                                |
|                            [logo]                              |
|                                                                |
|                            M Q - A p p                          |
|                                                                |
|                          [ skeleton ~~~~ ]                     |  <- línea animada
|                                                                |
|              Biblia y Himnario en un solo lugar                |
|                                                                |
|     [    card "Información" con skeleton rows    ]             |
|                                                                |
|     [          Volver (FilledButton, habilitado)          ]   |
|                                                                |
+----------------------------------------------------------------+
```

> Nota: en la práctica, `package_info_plus` retorna en < 50ms, así que el skeleton es casi imperceptible. El estado se incluye por completitud.

### Estado: Error de `package_info_plus` (defensivo)

Si falla la lectura de versión (caso raro, p.ej. permisos en iOS):

```
+----------------------------------------------------------------+
|                                                                |
|                            M Q - A p p                          |
|                                                                |
|                            v?                                  |  <- muestra "v?" en lugar de versión
|                                                                |
|     [    card "Información" (se muestra igual)    ]             |
|                                                                |
+----------------------------------------------------------------+
```

No se muestra error bloqueante — la pantalla sigue siendo funcional sin número de versión.

---

## Elementos

| Elemento | Tipo | Posición | Acción |
|----------|------|----------|--------|
| `<-` | IconButton | AppBar leading | Pop al Settings (que es el entry point) |
| Título "Acerca de" | AppBar title | AppBar center | Estático |
| Logo MQ-App | Widget custom (`MqLogo` size 200) | Centrado, top del body | Sin acción (decorativo) |
| "MQ-App" | Text `displayMedium` gold | Debajo del logo, centrado | Sin acción |
| "v1.0.1" | Text `bodySmall` variant | Debajo del nombre | Sin acción (dinámico) |
| Tagline | Text `bodyMedium` variant | Debajo de la versión | Sin acción |
| Card "Información" | `Card` elevación 1 | Padding 16dp del body | Sin acción propia (la acción es por fila) |
| Fila "Repositorio" | `InkWell` + `ListTile` | 1ª fila del card | `launchUrl('https://github.com/melquisedec-ark/MQ-App', mode: externalApplication)` |
| Fila "Página oficial" | `ListTile` disabled | 2ª fila | Sin acción (placeholder) |
| Fila "Comunidad WhatsApp" | `ListTile` disabled | 3ª fila | Sin acción (placeholder) |
| Fila "Licencia" | `ListTile` con chip "MIT" | 4ª fila (última) | Sin acción (informativa) |
| Botón "Volver" | `FilledButton` (gold, full width) | Bottom del body | `Navigator.pop(context)` |

---

## Componentes reutilizados

- `MqLogo` (nuevo) o fallback `Text("MQ")` — crear widget dedicado en `lib/presentation/shared_widgets/mq_logo.dart` (reutilizable en splash, about, emitter)
- `GlassCard` se IGNORA — se usa `Card` Material 3 estándar con elevación 1 (D4 quitó glassmorphism)
- `AppSnackBar` (helper nuevo de D5) — no necesario en esta pantalla (no hay feedback de acción)
- `package_info_plus: ^8.0.0` (nueva dependencia) — para leer versión, build number, package name
- `url_launcher: ^6.x` (probablemente ya está) — para abrir el repo

---

## Notas de implementación

### Dependencias

```yaml
dependencies:
  package_info_plus: ^8.0.0  # NUEVO — leer versión dinámica
  url_launcher: ^6.2.0       # probable ya existente
```

### Ruta (go_router)

En `lib/core/router/app_router.dart`:

```dart
GoRoute(
  path: 'acerca-de',
  name: 'about',
  builder: (ctx, state) => const AboutScreen(),
),
```

### Entry point desde Configuración

En `lib/features/biblia/presentation/screens/settings_screen.dart` (sección "Acerca de"):

- **Antes:** una `ExpansionTile` o sección con la versión hardcoded
- **Después:** un `ListTile` con:
  - leading: `Icons.info_outline_rounded` (24dp, gold)
  - title: "Acerca de"
  - subtitle: "Versión, repositorio, comunidad"
  - trailing: `Icons.chevron_right_rounded` (20dp)
  - onTap: `context.pushNamed('about')`

### Versión dinámica

```dart
import 'package:package_info_plus/package_info_plus.dart';

class _AboutScreenState extends State<AboutScreen> {
  String _version = '...';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;       // "1.0.1"
      _buildNumber = info.buildNumber;  // "3"
    });
  }
}
```

Mostrar en pantalla: `"v$_version"` (sin build number en esta versión; agregar en debug builds).

### UX de "Próximamente"

Los placeholders "Página oficial" y "Comunidad WhatsApp" usan el patrón de **deshabilitado pero presente**:

```dart
ListTile(
  leading: Icon(Icons.home_outlined, color: cs.onSurface.withOpacity(0.3)),
  title: Text('Página oficial', style: TextStyle(color: cs.onSurface.withOpacity(0.5))),
  subtitle: Text('Próximamente', style: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.5))),
  enabled: false,  // desactiva el ripple y el tap
),
```

**Decisión:** se muestran en la UI aunque no funcionen, para:
- Cumplir la promesa del wireframe original
- Visibilizar la roadmap al usuario
- Permitir greyboxing futuro sin re-diseñar la pantalla

### Tap en repo

```dart
import 'package:url_launcher/url_launcher.dart';

Future<void> _openRepo(BuildContext context) async {
  final uri = Uri.parse('https://github.com/melquisedec-ark/MQ-App');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    // Fallback: copiar al portapapeles + snackbar
    await Clipboard.setData(const ClipboardData(text: uri.toString()));
    if (context.mounted) {
      AppSnackBar.show(context, 'Enlace copiado al portapapeles');
    }
  }
}
```

### Licencia MIT

No se abre un viewer de licencia completo en v1.0.1 (sería Nice to Have). Se muestra solo el texto "MIT" como chip para confirmar el tipo. **Pendiente:** decisión de si mostrar la licencia completa en un dialog (no wireframeado aquí).

---

## Responsive

### Tablet (≥ 600dp)

- Card "Información" crece a 60% del ancho, centrada.
- Logo y nombre se mantienen centrados, sin cambios.

### Desktop (≥ 1024dp)

- Card crece a 480dp de ancho, centrada.
- Botón "Volver" se reduce a `maxWidth: 240dp` (no full width en desktop).

---

## Accesibilidad (WCAG 2.1 AA)

| Criterio | Implementación |
|----------|----------------|
| Contraste de "MQ-App" gold sobre fondo | `goldPrimary` (#CCA43B) sobre `surface` (#FEFAF0 / #121212). Cumple AA para texto grande ≥18pt (28sp ✓) |
| Items deshabilitados | Contraste reducido a 30% — etiquetados como "Próximamente" en subtítulo para claridad semántica |
| Lectores de pantalla | Cada `ListTile` con `Semantics` apropiado (Material lo provee por default) |
| Touch targets | 48dp mínimo en cada fila (Material `ListTile` lo garantiza) |
| Focus visible (desktop) | Outline 2px gold en items habilitados al recibir focus |

---

## Cambios vs versión anterior

- **Wireframe nuevo.** No existía pantalla "Acerca de" en v1.0.0.
- Reemplaza la `ExpansionTile` de "Acerca de" dentro de Settings (v1.0.0) por una entrada a esta pantalla dedicada.
- Versión hardcoded → versión dinámica con `package_info_plus`.

---

## Preguntas abiertas

1. **¿La pantalla debe tener un botón "Compartir app"?** (compartir URL del repo, invitar amigos). Sugerencia: NO en v1.0.1, Nice to Have. Diferido a v1.1+.

2. **¿Mostrar la licencia MIT completa** en un dialog expandible al tap en "MIT"? Sugerencia: SÍ — el chip "MIT" abre un `showDialog` con el texto de la licencia (es un gesto esperado en apps open-source). Bajo costo de implementación.

3. **¿El footer "Hecho con ❤ para la gloria de Dios" se incluye?** Es un toque personal, encaja con la identidad religiosa, pero no es funcional. Sugerencia: incluir en v1.0.1 (es solo un Text).

4. **¿Se debe incluir un "Easter egg" o QR code** al repo al final de la pantalla? No mencionado por el usuario. Sugerencia: NO en v1.0.1.

5. **El usuario mencionó usar "Cinzel" para "MQ-App"** (en el prompt original). El style guide LOCKED (`05_style_guide.md` §3.1) dice "No se carga ninguna fuente custom en v1.0". **Conflicto:** Cinzel requeriría agregar la fuente. Sugerencia: usar `displayMedium` del sistema en v1.0.1 (lock del style guide) y evaluar Cinzel en v1.1 cuando se agreguen fuentes custom para los versículos.

6. **El usuario mencionó `gold #D4A574` para FAB.** El style guide LOCKED dice `goldPrimary = #CCA43B`. **Conflicto:** usar #CCA43B (lock) por consistencia con el resto de la app.

---

*Wireframe creado por @design — pendiente revisión de @arqui antes de implementar. Cambios D4 (quitar glassmorphism) y D7 (pantalla Acerca de) ya incorporados.*
