> ⚠️ **DOCUMENTO HISTÓRICO** — Sprint 5 (mayo 2026)
> La mayoría de las tareas aquí descritas fueron implementadas en sprints anteriores.
> Para el estado actual del proyecto, consultar `doc/tareas_pendientes.md`.
> Fecha de archivo: 22 de mayo de 2026
>
> ---
>
> ## 🗄️ DB Auto-Update (Feature completa desde 22 mayo 2026)
>
> ### Arquitectura de versionado
>
> Hay **dos números de versión independientes**:
>
> 1. **`SCHEMA_VERSION`** (en `DatabaseHelper`): controla migraciones estructurales (tablas, columnas, índices) mediante `onUpgrade()`. Se incrementa cuando el equipo cambia el esquema SQL.
> 2. **Asset version** (`assets/db/db_version.json`): controla el reemplazo de la BD pre-cargada completa. Se incrementa cuando cambia el seed data (himnos, estrofas, etc.) sin cambiar el esquema.
>
> ### Flujo de actualización automática
>
> ```
> _initDatabase()
>   ├─ 1. Leer assetVersion (db_version.json) y localVersion (db_version.txt)
>   ├─ 2. ¿assetVersion > localVersion o .db no existe?
>   │   ├─ Sí → Backup user data → Copiar nuevo .db → writeLocalVersion → Restaurar
>   │   └─ No → Continuar con BD existente
>   └─ 3. Abrir BD con onCreate/onUpgrade (esquema SQLite)
> ```
>
> ### Cómo actualizar la BD para nueva release
>
> 1. Reemplazar `assets/db/himnario_id.db` con la nueva BD precargada.
> 2. Incrementar `version` en `assets/db/db_version.json`.
> 3. Si hay cambios de esquema, incrementar `SCHEMA_VERSION` en `DatabaseHelper` y agregar migración en `_onUpgrade()`.
> 4. Commit y push. La app existente detectará la nueva versión al iniciar.
>
> ### Archivos del sistema
>
> | Archivo | Propósito |
> |---------|-----------|
> | `assets/db/db_version.json` | Versión del asset (seed data) |
> | `assets/db/himnario_id.db` | BD precargada |
> | `{appDocs}/himnario_id.db` | BD local (copia del asset + datos de usuario) |
> | `{appDocs}/db_version_applied.txt` | Versión aplicada localmente (marker) |
>
> ### Clases nuevas
>
> - `lib/core/database/db_version_manager.dart` — Lectura/escritura de versiones, comparación, carga de asset.
> - `lib/core/database/user_data_backup.dart` — Backup/restore de datos de usuario durante actualización.
> - `lib/core/database/database_helper.dart` (refactorizado) — `SCHEMA_VERSION`, `_openDatabasePlatform()`, `_openDatabaseRaw()`, Logger.

# Tareas para @dev

## TAREA-001: Candado en HomeScreen
**Prioridad**: P0 (Crítica) | **Archivos**: `home_screen.dart`

### Qué hacer
Agregar un `IconButton` con ícono de candado en el `leading` del `AppBar` en `HomeScreen`.

### Código base (reemplazar build method section)
```dart
// En el AppBar de HomeScreen, agregar:
leading: IconButton(
  icon: Icon(
    ref.watch(isAuthenticatedProvider) 
        ? Icons.lock 
        : Icons.lock_outline,
  ),
  onPressed: () {
    final isAuth = ref.read(isAuthenticatedProvider);
    if (isAuth) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  },
  tooltip: 'Administración',
),
```

### Importaciones necesarias
```dart
import '../../views_admin/login/login_screen.dart';
import '../../views_admin/admin_panel_screen.dart';
import '../../views_admin/providers/auth_providers.dart'
    show isAuthenticatedProvider;
```

### Verificación
- `dart analyze lib/` debe dar 0 errores
- Al hacer clic en candado → LoginScreen si no auth, AdminPanelScreen si auth
- Ícono cambia de `lock_outline` a `lock` según estado auth

---

## TAREA-002: Selector Emisor/Receptor en DiscoverDisplaySheet
**Prioridad**: P0 (Crítica) | **Archivos**: `discover_display_sheet.dart`, `connection_state.dart`, `connection_providers.dart`

### Qué hacer
Agregar una pantalla de selección de rol (Emisor/Receptor) al abrir el sheet de conexión, antes del escaneo de dispositivos.

### Paso 1: Modificar `connection_state.dart`
Agregar enum:
```dart
/// Rol de conexión.
enum ConnectionRole { emitter, receiver, none }
```
Agregar `role` a `Connected`:
```dart
class Connected extends ConnectionState {
  final DeviceInfo device;
  final ConnectionRole role;
  const Connected(this.device, {this.role = ConnectionRole.none});
}
```

### Paso 2: Modificar `DiscoverDisplaySheet`
Agregar pantalla inicial con 2 cards grandes:
- "Soy Emisor" (Icons.cast, color primario) → inicia escaneo de displays
- "Soy Receptor" (Icons.tv, color secundario) → cierra sheet y activa modo receptor

### Paso 3: Modificar `ConnectedDashboard`
Cuando role = receiver, no mostrar buscador sino mensaje "Modo Receptor activo".

---

## TAREA-003: DesktopWindowService Real
**Prioridad**: P0 (Crítica) | **Archivos**: `window_service.dart`, `window_providers.dart`

### Qué hacer
Implementar `DesktopWindowService.openProjectionWindow()` para abrir una segunda ventana real usando `window_manager`.

### Código base
```dart
import 'package:window_manager/window_manager.dart';

class DesktopWindowService implements WindowService {
  @override
  Future<void> openProjectionWindow(Map<String, dynamic> args) async {
    // Usar window_manager para crear segunda ventana
    await windowManager.createWindow(
      WindowOptions(
        size: Size(1920, 1080),
        fullScreen: true,
        alwaysOnTop: true,
        backgroundColor: Colors.black,
        title: 'HimnarioID - Proyección',
      ),
    );
    _eventController.add(WindowEvent(type: WindowEventType.opened, data: args));
  }
}
```

### Consideraciones
- La segunda ventana debe ejecutar la misma app Flutter con un flag `--projection-mode`
- Alternativa: usar `WebWindowService` con `window.open()` + `BroadcastChannel`
- En Web, la URL debe ser `/projection-display` que renderiza `LiveProjectionScreen`

---

## TAREA-004: Integración PresentButton + Navegación
**Prioridad**: P0 (Crítica) | **Archivos**: `home_screen.dart`, `present_button.dart`, `himnario_dual_app.dart`

### Qué hacer
Cuando Present está activo + usuario selecciona himno → abrir proyección en 2da ventana + convertir HomeScreen en panel de control.

### Provider nuevo
```dart
// En present_button.dart o nuevo archivo
final isPresentingProvider = StateProvider<bool>((ref) => false);
```

### En HomeScreen
```dart
// Cuando isPresenting && isDesktop, cambiar comportamiento de HymnCard.onTap:
onTap: () async {
  if (ref.read(isPresentingProvider)) {
    // 1. Abrir proyección en 2da ventana
    await windowService.openProjectionWindow({'hymnId': himno.id});
    // 2. Navegar a LiveControlScreen
    Navigator.pushNamed(context, '/live-control', arguments: himno);
  } else {
    // Comportamiento normal
    Navigator.pushNamed(context, '/hymn-detail', arguments: himno);
  }
},
```

---

## TAREA-005: MinimalControlScreen Funcional
**Prioridad**: P1 (Alta) | **Archivos**: `minimal_control_screen.dart`, create `shared_widgets/control_sheets.dart`

### Qué hacer
Conectar los botones Brocha, Solfa, Nota, Lupa a funcionalidad real. Extraer los sheets de HymnDetailScreen a widgets compartidos.

### Refactor: Crear `shared_widgets/control_sheets.dart`
```dart
// Mover los métodos _showBrochaSheet, _showSolfaSheet, _showNotaSheet,
// _showLupaDialog de HymnDetailScreen a funciones/variables reutilizables.

void showBrushSheet(BuildContext context, {required double fontScale, ...}) { ... }
void showNoteSheet(BuildContext context, {required int himnoId, ...}) { ... }
void showSolfaSheet(BuildContext context, {required WidgetRef ref, ...}) { ... }
void showSearchSheet(BuildContext context, {required WidgetRef ref, ...}) { ... }
```

### En MinimalControlScreen
```dart
_FunctionButton(
  icon: Icons.brush,
  label: 'Brocha',
  onPressed: () => showBrushSheet(context, ...),
),
```

---

## ~~TAREA-006: SimpleProjectionView~~ (CANCELADA - F5.2)
**Prioridad**: P1 (Alta) | **Archivos**: ~~`simple_projection_view.dart`~~

### Qué hacer
~~Crear vista simplificada para cuando el usuario en Desktop NO ha presionado Present y selecciona un himno.~~

**Motivo**: Reemplazado por `HymnDetailScreen` completo desde Fase 1. El widget `SimpleProjectionView` y su test fueron eliminados en Fase 5.2.

---

---

## TAREA-007: File Picker para Fondos
**Prioridad**: P1 (Alta) | **Archivos**: `fondo_tab.dart`, `pubspec.yaml`

### Paso 1: Agregar dependencia
```yaml
# pubspec.yaml
file_picker: ^8.0.0
```

### Paso 2: Modificar FondoTab
Agregar botón "Seleccionar archivo" junto al campo de ruta:
```dart
Row(
  children: [
    Expanded(
      child: TextField(controller: _rutaController, ...),
    ),
    IconButton(
      icon: Icon(Icons.folder_open),
      onPressed: () async {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.media,
        );
        if (result != null && result.files.isNotEmpty) {
          _rutaController.text = result.files.single.path ?? '';
        }
      },
    ),
  ],
)
```

---

## TAREA-008: "Crear Arreglo" en Solfa Sheet
**Prioridad**: P1 (Alta) | **Archivos**: `hymn_detail_screen.dart`

### Qué hacer
Agregar opción "Crear Arreglo Personalizado" dentro del Solfa sheet.

### Código
```dart
// Dentro de _showSolfaSheet, después del divider:
const Divider(),
ListTile(
  leading: Icon(Icons.edit_note, color: sheetColorScheme.tertiary),
  title: Text('Crear Arreglo Personalizado'),
  subtitle: Text('Fork del himno con tus propios acordes'),
  onTap: () {
    Navigator.pop(context); // cerrar sheet
    Navigator.pushNamed(context, '/arrangement-editor',
        arguments: widget.himno);
  },
),
```

---

## TAREA-010: Refactor ConnectionRole
**Prioridad**: P2 (Media) | **Archivos**: `connection_state.dart`, `connection_providers.dart`, `discover_display_sheet.dart`

### Qué hacer
Integrar `ConnectionRole` en todo el flujo de conexión. Ajustar UI y lógica según el rol.

---

## TAREA-011: Detección Plataforma Release
**Prioridad**: P3 (Baja) | **Archivos**: `dual_mode_providers.dart`

### Código
```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

static DeviceMode _detectInitialMode() {
  if (kReleaseMode) {
    if (kIsWeb) return DeviceMode.desktop;
    try {
      if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
        return DeviceMode.desktop;
      }
    } catch (_) {}
    return DeviceMode.phone;
  }
  return DeviceMode.phone; // debug: phone por defecto
}
```
