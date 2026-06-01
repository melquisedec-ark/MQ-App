# Bug: Fondo de proyección se resetea al cambiar apariencia

> :warning: **ESTE BUG HA OCURRIDO 4 VECES.** La causa raíz #1 (transporte) se
> parchó en v2.1.4, pero la causa raíz #2 (persistencia) persistió hasta v2.1.7.
> **Si vuelve a aparecer, buscar en `_saveToDb()` antes que en mensajes.**

## Historial completo

| Ocurrencia | Síntoma | "Fix" aplicado | Resultado |
|------------|---------|----------------|-----------|
| **#1 (v2.0.1)** | Fondo se vuelve BLANCO al cambiar tamaño de letra | Agregar `bgColor` a `sendSetAppearance()` | ❌ Ahora se vuelve NEGRO |
| **#2 (v2.0.2)** | Fondo se vuelve NEGRO al cambiar tamaño de letra | El "fix" anterior | ❌ El fondo sigue cambiando |
| **#3 (v2.1.4)** | Fondo se vuelve NEGRO al cambiar apariencia desde celular | Eliminar `bgColor` y `bgFondoId` de SET_CONFIG y SET_APPEARANCE | ❌ El fondo SIGUE cambiando (causa REAL era otra) |
| **#4 (v2.1.6 → v2.1.7)** | Fondo se vuelve NEGRO al cambiar CUALQUIER apariencia | [v2.1.6] Eliminar `sendSetFontSize`, sync gRPC→subproceso. [v2.1.7] **Sacar `bg_fondo_id` de `_saveToDb()`** | ✅ **FIX DEFINITIVO** |

## Causa Raíz #1 (v2.0.1 – v2.1.4): Transporte

**`SET_APPEARANCE` / `SET_CONFIG` transportaba `bgColor`.**

Los conceptos de "apariencia" y "fondo" estaban mezclados en los mensajes. Cada vez que se cambiaba algo de apariencia (tamaño de letra, color de texto, etc.), se enviaba TAMBIÉN `bgColor` en el mismo mensaje.

### Mecanismo

```
Usuario cambia tamaño de letra
  → _syncAppearanceToProjection()
    → sendSetAppearance(bgColor: appearance.bgColor)  ← envía el color actual
    → (también) sendSetBackground()                     ← envía el fondo actual
```

En el receptor:

1. `SET_APPEARANCE` llega → `notifier.setBgColor(color)` → **borra `selectedFondo = null`**
2. El fondo de imagen se pierde momentáneamente
3. `SET_BACKGROUND` llega → `notifier.setFondo(fondo)` → restaura el fondo
4. Pero si `SET_BACKGROUND` se retrasa o falla → el fondo se pierde permanentemente

Agravante en el subproceso:
```dart
// projection_app.dart
final color = Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);
```
El `| 0xFF000000` fuerza alpha a opaco. `Colors.transparent` (`#00000000`) → `#FF000000` = **negro opaco**.

### Fix aplicado (v2.1.4)
Eliminar `bgColor` y `bgFondoId` de SET_CONFIG (emisor y receptor) y de SET_APPEARANCE (gRPC). Esto parchó el transporte, pero **no fue suficiente**.

---

## Causa Raíz #2 (v2.1.4 – v2.1.7): Persistencia

**`_saveToDb()` en `appearance_provider.dart` escribía `bg_fondo_id = ''` en la BD compartida en CADA setter.**

Este es el bug más sutil y el que realmente causaba las recurrencias #3 y #4. El fix de transporte (v2.1.4) eliminó `bgColor` de los mensajes, pero el daño ocurre a nivel de BD.

### Mecanismo

En `appearance_provider.dart` línea 165 (antes del fix):

```dart
Future<void> _saveToDb() async {
  try {
    await _dbHelper.setConfig('font_family', state.fontFamily);
    await _dbHelper.setConfig('is_bold', state.isBold.toString());
    await _dbHelper.setConfig('bg_color', _colorToHex(state.bgColor));
    await _dbHelper.setConfig('text_color', _colorToHex(state.textColor));
    await _dbHelper.setConfig('chord_color', _colorToHex(state.chordColor));
    await _dbHelper.setConfig('font_scale', state.fontScale.toString());
    // ... 5 campos más ...
    await _dbHelper.setConfig(                                   ← LÍNEA 165
      'bg_fondo_id',
      state.selectedFondo?.id.toString() ?? ''   // ← CONTAMINACIÓN
    );
  } catch (e) { /* Silent fail */ }
}
```

`_saveToDb()` es llamado por **TODOS los setters**: `setTextColor()`, `setFontScale()`, `setIsBold()`, etc. Todos escriben `bg_fondo_id = ''` si `selectedFondo` es null.

### Flujo de contaminación

```
Celular cambia color de letra
  → gRPC SET_APPEARANCE
    → PC: setTextColor(color) → _saveToDb() → bg_fondo_id = '' en BD
    → PC: _syncAppearanceToSubprocess()
      → SET_CONFIG (11 campos) al subproceso
        → Subproceso: 11 setters → 11 _saveToDb() → 11× bg_fondo_id = ''
```

La BD compartida (ambos procesos usan el mismo archivo SQLite) se contamina constantemente.

Cuando el subproceso se reinicia o hay una condición de carrera durante el procesamiento asíncrono de SET_CONFIG, `selectedFondo` se lee como null y el fondo se pierde — **incluso sin que ningún mensaje transporte `bgColor`**.

### ¿Por qué los fixes de transporte no funcionaron?

| Fix | Versión | Lo que parchó | ¿Toca la raíz? |
|-----|---------|---------------|:---:|
| Eliminar `bgColor` de SET_CONFIG | v2.1.4 | Transporte | ❌ |
| Eliminar `bgFondoId` de SET_CONFIG | v2.1.4 | Transporte | ❌ |
| Eliminar `sendSetFontSize` | v2.1.6 | Transporte gRPC | ❌ |
| Sync gRPC→subproceso + SET_BACKGROUND | v2.1.6 | Transporte IPC | ❌ |
| **Sacar `bg_fondo_id` de `_saveToDb()`** | **v2.1.7** | **Persistencia** | **✅** |

---

## Fix Definitivo (v2.1.7)

### Principio

> `_saveToDb()` debe guardar SOLO los campos que el setter específico modificó.
> `bg_fondo_id` NO debe escribirse al cambiar `textColor`, `fontScale`, etc.
> Solo debe persistirse mediante los setters DEDICADOS de fondo.

### Cambios aplicados

#### 1. `appearance_provider.dart` — Separar persistencia de fondo

**Antes** (línea 165 dentro de `_saveToDb()`):
```dart
await _dbHelper.setConfig('bg_fondo_id', state.selectedFondo?.id.toString() ?? '');
```

**Después**: `bg_fondo_id` eliminado de `_saveToDb()`. Nueva función exclusiva:

```dart
Future<void> _saveBgFondoId(String? id) async {
  try {
    await _dbHelper.setConfig('bg_fondo_id', id ?? '');
  } catch (e) { /* Silent fail */ }
}
```

Llamada SOLO desde los setters dedicados:

| Setter | Llama `_saveBgFondoId` con |
|--------|---------------------------|
| `setFondo(fondo)` | `fondo.id.toString()` |
| `setBgColor(color)` | `null` (borra fondo) |
| `clearFondo()` | `null` (borra fondo) |

#### 2. `grpc_display_server.dart` — SET_BACKGROUND incondicional

`_syncAppearanceToSubprocess()` ahora SIEMPRE envía SET_BACKGROUND:
```dart
_syncBackgroundToSubprocess(appearance.selectedFondo?.id ?? 0);
```
Antes era condicional (`if (selectedFondo != null)`). Ahora siempre se envía (con `'0'` como "sin fondo").

#### 3. `projection_app.dart` — Manejo robusto de errores

`_handleSetBackground` protegido con `.catchError()` para errores asíncronos de BD.

### Arquitectura final del flujo

```
Celular cambia textColor:
  → _syncAppearanceToProjection()
    → SET_CONFIG (11 campos, SIN bgColor, SIN bgFondoId) → WindowService (no-op en celular)
    → sendSetAppearance (gRPC, SIN bgColor)
    → sendSetBackground (gRPC, SOLO si selectedFondo != null)

PC recibe SET_APPEARANCE (gRPC):
  → notifier.setTextColor(color)            ← NO toca bg_fondo_id en BD
  → _syncAppearanceToSubprocess()
    → SET_CONFIG (11 campos, SIN bgColor)   → Subproceso: 11 setters, NO contaminan BD
    → SET_BACKGROUND (SIEMPRE)              → Subproceso: mantiene/actualiza fondo

PC cambia fondo localmente (brush sheet):
  → setFondo(fondo)
    → _saveToDb()                           ← Guarda apariencia normal
    → _saveBgFondoId(fondo.id)              ← Guarda bg_fondo_id
  → _syncAppearanceToProjection()
    → SET_CONFIG (11 campos, SIN fondo)
    → SET_BACKGROUND (con bgFondoId)        → Subproceso: actualiza fondo
```

### Lecciones aprendidas

1. **No asumas que el bug está en los mensajes solo porque el síntoma aparece al enviar datos.** Investiga también la capa de persistencia.
2. **`_saveToDb()` con 13 `await`s seguidos es una bomba de tiempo.** Cada `await` cede al event loop, permitiendo que otros mensajes se procesen en medio.
3. **BD compartida entre procesos = corrupción compartida.** Ambos procesos (main y subproceso) escriben al mismo archivo SQLite. Cualquier escritura incorrecta en uno afecta al otro.
4. **Separar conceptos en el transporte NO es suficiente si la persistencia los mezcla.**

### Verificación

1. Cambiar tamaño de letra → el fondo NO cambia
2. Cambiar color de texto → el fondo NO cambia
3. Cambiar fuente → el fondo NO cambia
4. Cambiar color de acordes → el fondo NO cambia
5. Alternar mostrar acordes → el fondo NO cambia
6. Seleccionar un fondo nuevo → el fondo CAMBIA (correcto)
7. Cambiar apariencia desde celular → el fondo NO cambia
8. Reiniciar subproceso → el fondo se mantiene
9. Cerrar y abrir app → el fondo se mantiene

### Archivos clave

| Archivo | Rol |
|---------|-----|
| `lib/presentation/shared_widgets/providers/appearance_provider.dart` | `_saveToDb()` (línea 148), `_saveBgFondoId()` (línea 175) — **el fix real** |
| `lib/presentation/shared_widgets/control_sheets.dart` | `_syncAppearanceToProjection` (línea 104) — emisor |
| `lib/data/datasources/remote/grpc_display_server.dart` | `_syncAppearanceToSubprocess()` (línea 525), `_syncBackgroundToSubprocess()` (línea 559) |
| `lib/presentation/views_projection/display/projection_app.dart` | `_handleSetConfig` (línea 157), `_handleSetBackground` (línea 235) |
| `lib/presentation/views_projection/providers/projection_actions.dart` | `_buildSetConfigMessage` (línea 84) |
