# Bug: Fondo de proyección se resetea al cambiar apariencia

> :warning: **ESTE BUG HA OCURRIDO 5 VECES.** Las causas raíz #1 (transporte) y
> #2 (persistencia) se parchaban parcialmente, pero #3 (reenvío redundante)
> persistió hasta v2.1.8.
> **Si vuelve a aparecer, buscar en `_syncAppearanceToProjection()` y
> `_syncAppearanceToSubprocess()` — funciones que envían fondo sin motivo.**

## Historial completo

| Ocurrencia | Síntoma | "Fix" aplicado | Resultado |
|------------|---------|----------------|-----------|
| **#1 (v2.0.1)** | Fondo se vuelve BLANCO al cambiar tamaño de letra | Agregar `bgColor` a `sendSetAppearance()` | ❌ Ahora se vuelve NEGRO |
| **#2 (v2.0.2)** | Fondo se vuelve NEGRO al cambiar tamaño de letra | El "fix" anterior | ❌ El fondo sigue cambiando |
| **#3 (v2.1.4)** | Fondo se vuelve NEGRO al cambiar apariencia desde celular | Eliminar `bgColor` y `bgFondoId` de SET_CONFIG y SET_APPEARANCE | ❌ El fondo SIGUE cambiando (causa REAL era otra) |
| **#4 (v2.1.6 → v2.1.7)** | Fondo se vuelve NEGRO al cambiar CUALQUIER apariencia | [v2.1.6] Eliminar `sendSetFontSize`, sync gRPC→subproceso. [v2.1.7] **Sacar `bg_fondo_id` de `_saveToDb()`** | ❌ **Todavía se re-envía fondo** |
| **#5 (v2.1.8)** | Fondo se RE-ENVÍA al cambiar apariencia (letra, color, etc.) | **Separar `_syncBackgroundToProjection()` de `_syncAppearanceToProjection()`** | ✅ **FIX COMPLETO** |

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

## Causa Raíz #3 (v2.1.8): Transporte redundante de fondo

**`_syncAppearanceToProjection()` y `_syncAppearanceToSubprocess()` re-enviaban el fondo en CADA cambio de apariencia.**

Incluso después de los fixes de persistencia (v2.1.7), cada vez que el usuario cambiaba cualquier campo de apariencia (fuente, color de letra, tamaño, etc.) desde el emisor móvil, se enviaban mensajes `SET_BACKGROUND` y `sendSetBackground` redundantes al receptor.

### Mecanismo

```
Emisor móvil cambia fuente:
  → hymnAppearanceProvider.setFontFamily()
  → _syncAppearanceToProjection()
    → (correcto) sendSetAppearance() — sin fondo
    → (incorrecto) sendSetBackground(id) — fondo reenviado ← BUG
    → (correcto) SET_CONFIG via WindowService — sin fondo
    → (incorrecto) SET_BACKGROUND via WindowService — fondo reenviado ← BUG

PC recibe sendSetBackground() + sendSetAppearance():
  → SET_BACKGROUND handler: setFondo(fondo) + _syncBackgroundToSubprocess()
  → SET_APPEARANCE handler: setters de apariencia + _syncAppearanceToSubprocess()
    → (incorrecto) _syncBackgroundToSubprocess() otra vez ← BUG
```

Aunque el ID del fondo era el mismo, el reenvío causaba:
1. Tráfico gRPC innecesario
2. Escrituras redundantes a la BD compartida (`_saveToDb()` en cada `setFondo`)
3. Posibles condiciones de carrera al procesar dos comandos de fondo seguidos
4. El receptor cambiaba el fondo aunque el usuario solo hubiera cambiado la letra

### Fix aplicado (v2.1.8)

> **Principio**: El fondo solo debe enviarse al receptor cuando el usuario CAMBIA explícitamente el fondo. Cambiar apariencia (fuente, color, tamaño) NO debe disparar ningún mensaje relacionado al fondo.

#### 1. `control_sheets.dart` — Separar `_syncBackgroundToProjection()`

**Antes**: `_syncAppearanceToProjection()` enviaba SET_BACKGROUND + sendSetBackground en cada llamada:
```dart
void _syncAppearanceToProjection(WidgetRef ref) {
  // ... envía SET_CONFIG ...
  // ... envía sendSetAppearance ...

  // ⚠️ Fondo reenviado en cada cambio de apariencia:
  if (appearance.selectedFondo != null) {
    ref.read(windowServiceProvider).sendMessage({'type': 'SET_BACKGROUND', ...});
    dataSource.sendSetBackground(appearance.selectedFondo!.id.toString());
  }
}
```

**Después**: Nueva función separada que SOLO se llama desde setters de fondo:
```dart
void _syncBackgroundToProjection(WidgetRef ref) {
  final bgId = appearance.selectedFondo?.id.toString();
  ref.read(windowServiceProvider).sendMessage({
    'type': 'SET_BACKGROUND', 'bgFondoId': bgId ?? '0',
  });
  if (isConnected && bgId != null) {
    dataSource.sendSetBackground(bgId);
  }
}
```

Llamada solo desde:
| Acción | Llama |
|--------|-------|
| `_FondoItem.onTap` → `setFondo(fondo)` | `_syncBackgroundToProjection(ref)` |
| `reset()` | `_syncBackgroundToProjection(ref)` |

#### 2. `grpc_display_server.dart` — Eliminar fondo de `_syncAppearanceToSubprocess()`

**Antes**: `_syncAppearanceToSubprocess()` reenviaba SET_BACKGROUND al subproceso:
```dart
void _syncAppearanceToSubprocess() {
  // ... envía SET_CONFIG ...
  // ⚠️ Fondo reenviado en cada cambio de apariencia:
  _syncBackgroundToSubprocess(bgId ?? 0);
}
```

**Después**: Solo envía SET_CONFIG. El fondo se maneja exclusivamente vía SET_BACKGROUND.

### Arquitectura final del flujo (v2.1.8)

```
Emisor móvil cambia textColor/fontFamily/etc:
  → hymnAppearanceProvider.setXxx()
  → _syncAppearanceToProjection()
    → SET_CONFIG (WindowService, sin fondo)
    → sendSetAppearance (gRPC, sin fondo)
    → NO envía background ← FIX v2.1.8

Emisor móvil cambia FONDO (toca un fondo):
  → hymnAppearanceProvider.setFondo(fondo)
    → _saveToDb() + _saveBgFondoId()
  → _syncBackgroundToProjection(ref)
    → SET_BACKGROUND (WindowService, con bgId)
    → sendSetBackground (gRPC, con bgId) ← SOLO cuando cambia fondo

PC recibe SET_APPEARANCE (gRPC):
  → setters de apariencia
  → _syncAppearanceToSubprocess()
    → SET_CONFIG (sin fondo, sin SET_BACKGROUND) ← FIX v2.1.8

PC recibe SET_BACKGROUND (gRPC):
  → setFondo(fondo) + _saveBgFondoId()
  → _syncBackgroundToSubprocess(bgId)
    → SET_BACKGROUND al subproceso
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
| `lib/presentation/shared_widgets/providers/appearance_provider.dart` | `_saveToDb()` sin `bg_fondo_id`, `_saveBgFondoId()` separada — fix persistencia (v2.1.7) |
| `lib/presentation/shared_widgets/control_sheets.dart` | `_syncAppearanceToProjection()` sin fondo, nueva `_syncBackgroundToProjection()` — **fix transporte redundante (v2.1.8)** |
| `lib/data/datasources/remote/grpc_display_server.dart` | `_syncAppearanceToSubprocess()` sin fondo, `_syncBackgroundToSubprocess()` solo llamada desde SET_BACKGROUND handler |
| `lib/presentation/views_projection/display/projection_app.dart` | `_handleSetConfig` con safeguard, `_handleSetBackground` con manejo de errores |
| `lib/presentation/views_projection/providers/projection_actions.dart` | `_buildSetConfigMessage` (línea 84) |
