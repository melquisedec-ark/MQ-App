> ⚠️ **DOCUMENTO HISTÓRICO** — Sprint 5 (mayo 2026)
> Las tareas de diseño descritas aquí fueron implementadas en sprints anteriores.
> Para el estado actual del proyecto, consultar `doc/tareas_pendientes.md`.
> Fecha de archivo: 19 de mayo de 2026

# Tareas para @design

## TAREA-002-DESIGN: UI Selector Emisor/Receptor
**Prioridad**: P0 (Crítica) | **Archivos**: `discover_display_sheet.dart`

### Qué hacer
Diseñar e implementar la interfaz de selección de rol (Emisor/Receptor) al abrir el sheet de conexión.

### Diseño
```
┌─────────────────────────────────────┐
│  ───                               │ <- Handle
│  Conectar Display          [X]      │ <- Título + cerrar
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📡  Soy Emisor              │  │ <- Card grande
│  │  Controlar la proyección     │  │    colorScheme.primaryContainer
│  │  desde mi dispositivo        │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │  📺  Soy Receptor             │  │ <- Card grande
│  │  Mostrar en esta pantalla     │  │    colorScheme.secondaryContainer
│  │  lo que el emisor envía       │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

### Especificaciones
- **Emisor**: Icon `Icons.cast_rounded`, colores `primaryContainer`/`onPrimaryContainer`
- **Receptor**: Icon `Icons.tv_rounded`, colores `secondaryContainer`/`onSecondaryContainer`
- Al seleccionar Receptor → cerrar sheet + cambiar a modo receptor
- Al seleccionar Emisor → transición suave a la vista de escaneo actual
- Animación: fade entre selector y escaneo

### Reglas de estilo
- Usar `colorScheme` y `textTheme` de Material Design 3
- Sin colores hardcodeados
- Widgets const donde sea posible
- Programación funcional con if/for de colección

---

## TAREA-009-DESIGN: Admin Hamburger Menu
**Prioridad**: P2 (Media) | **Archivos**: `admin_panel_screen.dart`

### Qué hacer
Rediseñar AdminPanelScreen para usar Drawer (hamburger menu) en lugar de ListView simple.

### Diseño
```
┌─────────────────────────────────────┐
│  ☰  Panel de Administración   [🔒] │ <- AppBar
├─────────────────────────────────────┤
│                                     │
│  Bienvenido, Admin                  │ <- Saludo
│                                     │
│  ┌───────────────────────────────┐  │
│  │ Contenido principal aquí      │  │ <- Vacío o bienvenida
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘

Drawer (izquierda):
┌─────────────────────┐
│ Header:              │
│ HimnarioID Admin     │
│ Admin                │
├─────────────────────┤
│ ✏️  Administrar     │ <- Opción activa por defecto
│    Himnos           │    Icon: Icons.edit_note
├─────────────────────┤
│ 🛠️  Catálogos       │
│    (País, Categorías,│    Icon: Icons.build
│     Pistas, Fondos)  │
├─────────────────────┤
│ 🚪  Cerrar sesión    │    Icon: Icons.logout
└─────────────────────┘
```

### Comportamiento
- Drawer se abre con ícono hamburguesa (☰) en AppBar leading
- Opción "Administrar Himnos" → push HymnListScreen (marca activa en drawer)
- Opción "Catálogos" → push CatalogPanelScreen
- Opción "Cerrar sesión" → logout + pop to login
- Mantener logout button en AppBar como respaldo

### Reglas de estilo
- Usar `NavigationDrawer` de Material Design 3
- `DrawerHeader` con información del admin autenticado
- `NavigationDrawerDestination` para cada opción
- Sin colores hardcodeados
