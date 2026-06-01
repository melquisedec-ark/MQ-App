> ⚠️ **DOCUMENTO HISTÓRICO** — Sprint 5 (mayo 2026)
> La mayoría de las tareas aquí descritas fueron implementadas en sprints anteriores.
> Para el estado actual del proyecto, consultar `doc/tareas_pendientes.md`.
> Fecha de archivo: 19 de mayo de 2026

# Tareas para @qa

## TAREA-QA-001: Tests para TAREA-001 (Candado)
**Prioridad**: P0 (Crítica)

### Qué testear
- [ ] HomeScreen muestra candado en AppBar leading
- [ ] Al presionar candado sin auth → navega a LoginScreen
- [ ] Al presionar candado con auth → navega a AdminPanelScreen
- [ ] Ícono cambia de `lock_outline` a `lock` según estado auth
- [ ] No hay regresiones en navegación existente

### Archivos de test
- `test/presentation/views_personal/dashboard/home_screen_test.dart` (actualizar)

---

## TAREA-QA-002: Tests para TAREA-002 (Selector Emisor/Receptor)
**Prioridad**: P0 (Crítica)

### Qué testear
- [ ] DiscoverDisplaySheet muestra selector de rol inicial
- [ ] Al seleccionar "Emisor" → transiciona a vista de escaneo
- [ ] Al seleccionar "Receptor" → cierra sheet + activa modo receptor
- [ ] ConnectionRole se propaga correctamente a ConnectionState
- [ ] UI se actualiza según el rol seleccionado

### Archivos de test
- `test/presentation/views_projection/controller/widgets/discover_display_sheet_test.dart` (actualizar)
- `test/core/network/connection_state_test.dart` (nuevo)

---

## TAREA-QA-003: Tests para TAREA-003 (DesktopWindowService)
**Prioridad**: P0 (Crítica)

### Qué testear
- [ ] DesktopWindowService.openProjectionWindow() abre ventana real
- [ ] DesktopWindowService.closeProjectionWindow() cierra ventana
- [ ] Stream de eventos funciona correctamente
- [ ] WebWindowService usa window.open() correctamente
- [ ] MobileWindowService lanza UnsupportedError

### Archivos de test
- `test/core/window_manager/window_service_test.dart` (actualizar)

---

## TAREA-QA-004: Tests para TAREA-004 (Present + Navegación)
**Prioridad**: P0 (Crítica)

### Qué testear
- [ ] isPresentingProvider se actualiza correctamente
- [ ] Cuando Present está activo + himno click → abre proyección + control
- [ ] Cuando Present NO está activo → comportamiento normal
- [ ] Estado de presentación persiste correctamente
- [ ] Integración con modo Desktop

### Archivos de test
- `test/presentation/views_personal/dashboard/present_button_test.dart` (actualizar)
- `test/presentation/views_personal/dashboard/home_screen_test.dart` (actualizar)

---

## TAREA-QA-005: Tests para TAREA-005 (MinimalControlScreen)
**Prioridad**: P1 (Alta)

### Qué testear
- [ ] Botón Brocha abre sheet de configuración visual
- [ ] Botón Solfa abre sheet de músico
- [ ] Botón Nota abre sheet de pistas
- [ ] Botón Lupa abre búsqueda
- [ ] Botón Salir navega atrás correctamente
- [ ] Navegación prev/next funciona

### Archivos de test
- `test/presentation/views_projection/controller/minimal_control_screen_test.dart` (actualizar)

---

## ~~TAREA-QA-006: Tests para TAREA-006 (SimpleProjectionView)~~ (CANCELADA - F5.2)
**Prioridad**: P1 (Alta)

**Motivo**: El widget SimpleProjectionView fue eliminado en Fase 5.2 porque fue reemplazado por `HymnDetailScreen` completo desde Fase 1.

---

---

## TAREA-QA-007: Tests para TAREA-007 (File Picker Fondos)
**Prioridad**: P1 (Alta)

### Qué testear
- [ ] Botón "Seleccionar archivo" dispara FilePicker
- [ ] Ruta seleccionada se muestra en campo de texto
- [ ] Preview de imagen funciona
- [ ] Guardar fondo con archivo funciona
- [ ] Editar fondo existente funciona

### Archivos de test
- `test/presentation/views_admin/crud_catalogs/fondo_tab_test.dart` (actualizar)

---

## TAREA-QA-008: Tests para TAREA-008 (Crear Arreglo en Solfa)
**Prioridad**: P1 (Alta)

### Qué testear
- [ ] Solfa sheet muestra opción "Crear Arreglo Personalizado"
- [ ] Al presionar → navega a ArrangementEditorScreen
- [ ] No hay regresiones en funcionalidad existente del sheet

### Archivos de test
- `test/presentation/views_personal/hymn_scroll/hymn_detail_screen_test.dart` (actualizar)

---

## TAREA-QA-009: Tests para TAREA-009 (Admin Hamburger Menu)
**Prioridad**: P2 (Media)

### Qué testear
- [ ] AdminPanelScreen tiene Drawer
- [ ] Opción "Administrar Himnos" navega a HymnListScreen
- [ ] Opción "Catálogos" navega a CatalogPanelScreen
- [ ] Opción "Cerrar sesión" hace logout + navega
- [ ] Drawer header muestra información del admin

### Archivos de test
- `test/presentation/views_admin/admin_panel_screen_test.dart` (actualizar)

---

## TAREA-QA-010: Test de Regresión General
**Prioridad**: P0 (Crítica) — **HACER AL FINAL**

### Qué testear
- [ ] `dart analyze lib/` → 0 errors, 0 warnings, 0 info
- [ ] Todos los tests existentes siguen pasando
- [ ] `flutter test` → 0 failures
- [ ] Navegación básica funciona (home → detalle → back)
- [ ] Login admin funciona (admin/admin123)
- [ ] CRUD himnos funciona
- [ ] CRUD catálogos funciona
- [ ] Conexión emisor/receptor fluye correctamente
- [ ] Modo PC/Celular switch funciona

### Comando de verificación
```bash
cd /home/melquisedec/Escritorio/Projects/Personales/HimnarioID_2.0
dart analyze lib/
flutter test
```
