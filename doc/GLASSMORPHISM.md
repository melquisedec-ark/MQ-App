# Glassmorphism — Sistema de Vidrio

> **Widget**: `lib/presentation/shared_widgets/glass_container.dart`
> **Provider**: `lib/presentation/shared_widgets/providers/appearance_provider.dart`
> **Implementación**: Proyección (`live_projection_screen.dart`) y Vista personal (`hymn_detail_screen.dart`)

## Arquitectura

El glassmorphism se implementa con `BackdropFilter` + `ImageFilter.blur()` — NO con `ImageFiltered`. La diferencia es crucial:

- `ImageFiltered` → Aplica blur al widget y sus hijos (el contenido también se ve borroso)
- `BackdropFilter` → Aplica blur SOLO al fondo detrás del widget (el contenido se ve nítido)

### Widget `GlassContainer`

```dart
GlassContainer({
  required Widget child,
  double blurSigma = 8.0,         // intensidad del blur
  Color overlayColor = Colors.white.withOpacity(0.15),  // capa de color
  double borderRadius = 16.0,
  EdgeInsets padding = EdgeInsets.all(16),
})
```

Renderiza:
1. `ClipRRect` + `BackdropFilter` con `ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma)`
2. Capa de color semitransparente encima (`overlayColor`)
3. El `child` encima de todo

## Configuración del usuario

Tres parámetros configurables desde el brush sheet:

| Parámetro | DB key | Tipo | Descripción |
|-----------|--------|------|-------------|
| `glassBlurSigma` | `glass_blur_sigma` | `double (0-20)` | Intensidad del blur. 0 = desactivado (se usa el fondo normal sin glass) |
| `glassEnabled` | `glass_enabled` | `bool` | Interruptor on/off del efecto glass |
| `glassOverlayColor` | `glass_overlay_color` | `String (hex)` | Color de la capa semitransparente sobre el blur |

### Colores disponibles para overlay

| Color | Hex |
|-------|-----|
| Negro | `#000000` |
| Blanco | `#FFFFFF` |
| Azul | `#1E3A5F` |
| Gris oscuro | `#2C2C2C` |
| Granate | `#4A1A1A` |
| Verde oscuro | `#1A3A1A` |
| Púrpura | `#2A1A3A` |
| Marrón | `#3A2A1A` |

### Persistencia

Los valores se guardan en la tabla `Configuracion` vía `SET_CONFIG`. El `HymnAppearanceState` los lee al iniciar y expone getters sincrónicos.

## Proyección vs Vista Personal

### Proyección (`live_projection_screen.dart`)

El panel lateral usa `GlassContainer` directamente. El fondo completo (imagen con `ImageFilter.blur` de fondo + overlay de color) es el escenario donde se proyecta el contenido del himno.

```dart
// Pseudocódigo de _buildFondo()
Stack[
  FondoImage (imagen con blur de fondo + capa de color)
  BackdropFilter (blur variable según glassBlurSigma)
  Content (estrofas, título, etc. con fondo semitransparente)
]
```

### Vista Personal (`hymn_detail_screen.dart`)

Usa el mismo `GlassContainer` a través del widget `_FondoBackground`. El slider de opacidad es el mismo que controla la proyección (`cardOpacity` en `HymnAppearanceState`).

Cuando `glassEnabled == true`:
- El fondo de cada estrofa se vuelve transparente (sin tarjeta blanca/gris)
- Las etiquetas de tipo de estrofa ("Coro", "Estrofa") son texto sutil al 50% de opacidad
- El borde del coro se mantiene

## Sincronización

Ambas vistas (proyección y personal) comparten el mismo `HymnAppearanceState` via Riverpod. Cambiar el glass desde el brush sheet afecta ambas vistas simultáneamente.

## Historial

| Versión | Cambio |
|---------|--------|
| v2.1.0 | Implementación inicial solo en proyección |
| v2.1.1 | `copyWith()` bugfix (faltaban campos de glass) |
| v2.1.1 | Full-screen glass en vista personal |
| v2.1.1 | Slider unificado personal+proyección |
| v2.1.1 | 8 colores de overlay configurables |
