# Wireframe 07 — Pantalla "Administrar Himnario"

> **Versión:** v1.0.1 | Actualizado: 2026-06-02 | Por: @design
> **Estado:** ✅ Wireframe nuevo (decisión D8 de `CONTROL/DECISIONES.md`)
> **Origen:** F6 de `CONTROL/PENDIENTE.md` + observación #8 del usuario en `BITACORA.md`
> **Archivo destino (Flutter):** `lib/features/himnario/presentation/screens/admin_himnario_screen.dart`
> **Ruta go_router:** `/himnario/admin` (nombre: `hymn-admin`)
> **Idioma:** Español (es-419)

---

## Propósito

**Centralizar las herramientas de gestión del himnario** (himnos individuales + catálogos) en una sola pantalla con tabs. Reemplaza la dispersión anterior donde "Administrar himnos" y "Catálogos" estaban en Configuración.

### Decisión UX clave (D8)

- **Antes:** dos entradas separadas en Configuración (`Administrar himnos` + `Catálogos`)
- **Después:** una entrada unificada → pantalla con 2 tabs
- **Acceso doble:** desde Configuración (mantener) + desde la pantalla principal del Himnario (nueva card)

---

## Vista (Portrait, móvil)

```
+--------------------------------------------------------------------------+
|  <-                                          Administrar himnario   [⋮]  |  <- AppBar
+--------------------------------------------------------------------------+
|                                                                          |
|   [   Himnos   ]   [   Catalogos   ]                                     |  <- TabBar (2 tabs, fixed)
|                                                                          |     active = gold underline 2dp
+--------------------------------------------------------------------------+
|                                                                          |
|   (Contenido del tab activo)                                             |
|                                                                          |
|                                                                          |
|                                                                          |
|                                                                          |
|                                                                          |
|                                                                          |
|                                                                          |
|                                                                          |
|                                                                          |
|                                                                          |
+--------------------------------------------------------------------------+
|                                                                          |
|                                                    [+] <- FAB            |  <- FAB (depende del tab)
|                                                                          |
+--------------------------------------------------------------------------+
```

---

## Tab 1: Himnos

```
+--------------------------------------------------------------------------+
|  <-                                          Administrar himnario   [⋮]  |
+--------------------------------------------------------------------------+
|   [   Himnos   ]   [   Catalogos   ]                                     |
+--------------------------------------------------------------------------+
|                                                                          |
|   68 himnos cargados                                                     |  <- counter (bodySmall, onSurfaceVariant)
|                                                                          |
|   +----------------------------------------------------------------+     |
|   |  [1]  Sublime gracia                              [★]          |     |  <- ListTile
|   |       Autor: John Newton                                       |     |     - número (displaySmall, gold)
|   |                                                  [editar] [<] |     |     - título (bodyLarge, 600)
|   |                                                  (swipe)      |     |     - autor (bodySmall, variant)
|   +----------------------------------------------------------------+     |
|   |  [2]  Alabaré                                  [ ]            |     |
|   |       Autor: Henry Zelley                                      |     |
|   |                                                  [editar] [<] |     |
|   +----------------------------------------------------------------+     |
|   |  [3]  Castillo fuerte es nuestro Dios            [★]          |     |
|   |       Autor: Martin Luther                                      |     |
|   |                                                  [editar] [<] |     |
|   +----------------------------------------------------------------+     |
|   |  [4]  Cuán grande es Él                                [ ]    |     |
|   |       Autor: Stuart K. Hine                                    |     |
|   |                                                  [editar] [<] |     |
|   +----------------------------------------------------------------+     |
|   |  ...                                                              |     |
|                                                                          |
|                                                       [+]                |  <- FAB "Crear nuevo"
+--------------------------------------------------------------------------+
```

### Anotaciones

- **Counter "68 himnos cargados":** `bodySmall` (12sp, onSurfaceVariant), padding 16dp horizontal, 8dp top.
- **Cada item:** Card-like row con `ListTile` (Material 3) o `InkWell` + custom layout.
  - **Número:** `displaySmall` (36sp, 700, gold) a la izquierda, en un contenedor de 56dp ancho.
  - **Título:** `bodyLarge` (16sp, 600, onSurface).
  - **Autor:** `bodySmall` (12sp, onSurfaceVariant) debajo del título.
  - **Badge favorito:** icono `star_rounded` 20dp gold si es favorito, o `star_outline_rounded` 20dp onSurfaceVariant si no.
  - **Sin glassmorphism:** fondo `surface` sólido, separadores `outlineVariant` 1dp entre items.
- **Swipe actions (`Dismissible`):**
  - **Swipe ← (derecha → izquierda):** reveal de 2 acciones
    - **[editar]** — fondo `primaryContainer` (goldLight), icono `edit_outlined`
    - **[eliminar]** — fondo `errorContainer`, icono `delete_outline` con confirmación
  - Confirmación de eliminar: `showDialog` con "¿Eliminar 'Sublime gracia'? Esta acción no se puede deshacer." + [Cancelar] [Eliminar]
- **Tap normal en fila:** abre el himno en `HymnDetailScreen` (preview, no edición).
- **FAB "Crear nuevo":** extendido opcionalmente (`ExtendedFloatingActionButton`) con icono `add` y label "Nuevo". Color gold, posición bottom-right (16dp + safe area).

### Búsqueda (header del tab)

```
+----------------------------------------------------------------+
|  [buscar himno...                    ]   [X]                   |  <- SearchBar (opcional en v1.0.1)
+----------------------------------------------------------------+
```

> **Decisión:** la búsqueda se difiere a v1.0.2 si no entra en scope. El tab es navegable solo por scroll. Si la lista crece > 200 himnos, se agrega `SearchAnchor` con filtrado en memoria.

---

## Tab 2: Catálogos

```
+--------------------------------------------------------------------------+
|  <-                                          Administrar himnario   [⋮]  |
+--------------------------------------------------------------------------+
|   [   Himnos   ]   [   Catalogos   ]                                     |
+--------------------------------------------------------------------------+
|                                                                          |
|   3 catalogos instalados                                                 |  <- counter
|                                                                          |
|   +----------------------------------------------------------------+     |
|   |  [folder]  Himnario Adventista                                |     |
|   |            250 himnos · Instalado 12 jun 2026        [activo] |     |  <- chip "activo" (gold)
|   |                                                  [<] [<]      |     |  swipe: re-importar / eliminar
|   +----------------------------------------------------------------+     |
|   |  [folder]  Himnario Bautista Clasico                          |     |
|   |            180 himnos · Instalado 05 jun 2026                |     |
|   |                                                  [<] [<]      |     |
|   +----------------------------------------------------------------+     |
|   |  [folder]  Cantos de Avivamiento                              |     |
|   |            68 himnos · Instalado 01 jun 2026                 |     |
|   |                                                  [<] [<]      |     |
|   +----------------------------------------------------------------+     |
|                                                                          |
|                                                       [↓]                |  <- FAB "Importar catálogo"
+--------------------------------------------------------------------------+
```

### Anotaciones

- **Counter:** "3 catálogos instalados" (bodySmall).
- **Cada item:** Row con icono `folder_rounded` 40dp gold a la izquierda.
  - **Nombre:** `bodyLarge` (16sp, 600, onSurface).
  - **Metadata:** "250 himnos · Instalado 12 jun 2026" (bodySmall, onSurfaceVariant).
  - **Badge "activo":** `Chip` pequeño con fondo `primaryContainer` y texto goldDark, solo en el catálogo marcado como activo.
- **FAB "Importar catálogo":** icono `file_download_rounded` (no `add`), label "Importar". Color gold.

### Active catalog

Solo UN catálogo está activo a la vez (es la fuente de himnos que se muestran en la lista principal del Himnario).

- **Definición:** `Configuracion.catalogo_activo` (clave ya existente en BD).
- **Cambio de activo:** tap en fila → bottom sheet "Establecer como catálogo activo" + opciones.
- **Si NO hay catálogo activo:** estado vacío "No hay catálogo activo. La lista de himnos está vacía."

### Swipe actions en catálogos

- **Swipe ← (derecha → izquierda):**
  - **[re-importar]** — fondo `primaryContainer`, icono `refresh_rounded`. Actualiza desde archivo fuente.
  - **[eliminar]** — fondo `errorContainer`, icono `delete_outline`. Confirmación: "¿Eliminar el catálogo 'X'? Se eliminarán también sus Y himnos."

---

## Empty states

### Tab 1: Sin himnos

```
+----------------------------------------------------------------+
|                                                                |
|                       [music_note 80dp]                        |
|                                                                |
|                    No hay himnos cargados                      |
|                                                                |
|     Importa un catalogo para empezar a usar el himnario.      |
|                                                                |
|                    [ Ir a Catalogos ]                          |  <- FilledButton outlined
|                                                                |
+----------------------------------------------------------------+
```

Tap en "Ir a Catálogos" → cambia al tab 2.

### Tab 2: Sin catálogos

```
+----------------------------------------------------------------+
|                                                                |
|                      [folder_open 80dp]                        |
|                                                                |
|                  No hay catalogos instalados                   |
|                                                                |
|        Importa un archivo de catalogo (formato .hymcat)        |
|                                                                |
|                    [ Importar catalogo ]                       |  <- FilledButton gold
|                                                                |
+----------------------------------------------------------------+
```

Tap en "Importar catálogo" → abre file picker (`file_picker` package).

---

## AppBar — Menú overflow (`[⋮]`)

```
+--------------------------------+
|                                |
|   Importar catalogo            |  <- icono file_download
|   Exportar catalogo            |  <- icono file_upload
|   ---------------------------- |
|   Acerca de los catalogos      |  <- icono info (link a docs)
|                                |
+--------------------------------+
```

> **Nota:** "Importar catálogo" en el menú hace lo MISMO que el FAB del tab 2. Se mantiene para redundancia y descubrimiento. **Decisión:** NO remover uno de los dos para v1.0.1; evaluar tras feedback de usuario.

### Comportamiento de Importar / Exportar

#### Importar catálogo

1. Tap → `file_picker` abre el selector de archivos del SO
2. Filtros: `.json` (formato interno) o `.hymcat` (formato custom futuro, no en v1.0.1)
3. Validación: parsing del JSON, validación de esquema
4. **Errores:**
   - Archivo corrupto → snackbar "Archivo inválido o corrupto"
   - Catálogo duplicado → dialog "Ya existe un catálogo con este nombre. ¿Reemplazar?" [Cancelar] [Reemplazar]
5. **Éxito:** snackbar "Catálogo 'X' importado (250 himnos)" + el nuevo catálogo aparece en la lista + es marcado activo automáticamente

#### Exportar catálogo

1. Tap → bottom sheet "Exportar catálogo activo"
2. Opciones:
   - **Formato:** JSON (default) | CSV (próximamente, deshabilitado)
   - **Destino:** Guardar en... (abre file picker en modo save)
3. Tap "Exportar" → genera archivo + snackbar "Catálogo exportado a Descargas/MQ-App/..."

---

## Elementos

| Elemento | Tipo | Posición | Acción |
|----------|------|----------|--------|
| `<-` | IconButton | AppBar leading | Pop a HimnarioHomeScreen (o Settings, según entry point) |
| "Administrar himnario" | AppBar title | AppBar center | Estático |
| `[⋮]` | PopupMenuButton | AppBar actions | Abre menú overflow |
| TabBar "Himnos / Catálogos" | `TabBar` fijo (2 tabs) | Debajo del AppBar | Cambia contenido del body |
| Counter "X himnos/catálogos" | `Text` bodySmall | Padding 16dp horizontal, 8dp top | Estático |
| Item himno | `ListTile`/`InkWell` + `Dismissible` | Body scroll | Tap = preview / Swipe = editar-eliminar |
| FAB `+` (tab Himnos) | `FloatingActionButton` | Bottom-right | Abre editor de himno nuevo |
| FAB `↓` (tab Catálogos) | `FloatingActionButton` | Bottom-right | Abre file picker para importar |
| Empty state (sin himnos) | `Column` centered | Body | CTA cambia a tab 2 |
| Empty state (sin catálogos) | `Column` centered | Body | CTA abre file picker |

---

## Componentes reutilizados

- **`HymnListScreen`** (`lib/presentation/views_personal/hymn/hymn_list_screen.dart`) — reutilizar widgets internos (HymnCard, HymnRow). Solo adaptar al layout admin (swipe, FAB).
- **`CatalogListView`** (`lib/presentation/views_admin/crud_catalogs/`) — reutilizar la vista de catálogos existente, agregar swipe + chip "activo".
- **`HymnEditorScreen`** (ya existe) — destino del FAB "+" y del swipe "editar".
- **`FilePicker`** (`file_picker: ^8.0.0`) — para importar catálogos (probable dependencia nueva, validar con @arqui).
- **`AppSnackBar`** (helper de D5) — feedback de importar/exportar.
- **Sin glassmorphism** (D4/D14) — usar `Card` Material 3 con elevación 1 o superficies sólidas.

---

## Notas de implementación

### Estructura del widget

```dart
class AdminHimnarioScreen extends ConsumerStatefulWidget {
  // Stateful porque tiene TabController
}

class _AdminHimnarioScreenState extends ConsumerState<AdminHimnarioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
}
```

### Entry points

#### 1. Desde HimnarioHomeScreen (card nueva)

En `lib/features/himnario/presentation/screens/himnario_home_screen.dart`, agregar **una card** debajo de los himnos recientes (o como acción en AppBar):

```
+----------------------------------------------------------------+
|  [tune]  Administrar himnario                                  |
|          Himnos, catalogos, importar/exportar          [chev]  |  <- tap
+----------------------------------------------------------------+
```

- `IconButton` action alternativo en AppBar: `Icons.tune_rounded`
- Decisión: **preferir la card** (más descubrible) sobre el AppBar action (ver D8)

#### 2. Desde Configuración (mantener)

En `lib/features/biblia/presentation/screens/settings_screen.dart`, mantener el `ListTile` "Administrar himnario" que llama a la misma ruta.

```dart
ListTile(
  leading: Icon(Icons.tune_rounded),
  title: Text('Administrar himnario'),
  subtitle: Text('Himnos, catálogos, importar/exportar'),
  trailing: Icon(Icons.chevron_right_rounded),
  onTap: () => context.pushNamed('hymn-admin'),
),
```

### Ruta (go_router)

```dart
GoRoute(
  path: 'himnario/admin',
  name: 'hymn-admin',
  builder: (ctx, state) => const AdminHimnarioScreen(),
),
```

### Swipe actions con `Dismissible`

```dart
Dismissible(
  key: ValueKey(himno.id),
  direction: DismissDirection.endToStart,  // swipe ← reveal acciones
  background: Container(
    color: Theme.of(context).colorScheme.primaryContainer,
    alignment: Alignment.centerRight,
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(icon: Icon(Icons.edit_outlined), onPressed: () { ... }),
        SizedBox(width: 8),
        IconButton(icon: Icon(Icons.delete_outline, color: error), onPressed: () { ... }),
      ],
    ),
  ),
  confirmDismiss: (_) async {
    // Para este caso, NO confirmar el dismiss — los botones revealed son la confirmación visual
    return false;  // el dismiss visual es solo para reveal, no para ejecutar
  },
  child: HymnRow(himno: himno),
)
```

> **Decisión técnica:** usar `confirmDismiss: (_) => false` y manejar la acción en los botones revelados. Esto da mejor control que el `Dismissible` estándar que ejecuta la acción al terminar el swipe.

### FAB dinámico según tab

```dart
floatingActionButton: AnimatedSwitcher(
  duration: Duration(milliseconds: 200),
  child: _tabController.index == 0
      ? FloatingActionButton.extended(
          key: ValueKey('create-hymn'),
          onPressed: () => _openHymnEditor(null),
          icon: Icon(Icons.add),
          label: Text('Nuevo'),
        )
      : FloatingActionButton.extended(
          key: ValueKey('import-catalog'),
          onPressed: _importCatalog,
          icon: Icon(Icons.file_download_rounded),
          label: Text('Importar'),
        ),
),
```

---

## Responsive

### Tablet (≥ 600dp)

- TabBar y lista crecen en ancho (limitados a 720dp central, mejor lectura).
- FAB se mantiene en bottom-right.

### Desktop (≥ 1024dp)

- **Layout 2 columnas:**
  - Izquierda (40%): lista de himnos/catálogos
  - Derecha (60%): preview del item seleccionado (sincronizado con el tab)
- TabBar visible siempre.
- FAB reemplazado por un botón en la barra lateral.

---

## Accesibilidad (WCAG 2.1 AA)

| Criterio | Implementación |
|----------|----------------|
| Touch targets | 48dp mínimo (Material `ListTile` lo garantiza) |
| Contraste | Textos sobre `surface` cumplen ≥ 4.5:1 |
| Screen readers | `Semantics` en cada item con: "Himno 1, Sublime gracia, autor John Newton, favorito" |
| Swipe gestures | Cada item tiene alternativas visibles (botones revealed) además del swipe |
| Focus visible (desktop) | Outline 2px gold en items con focus |

---

## Cambios vs versión anterior

- **Wireframe nuevo.** Reemplaza la dispersión anterior:
  - ❌ `SettingsScreen > ExpansionTile "Administrar himnos"` (eliminado)
  - ❌ `SettingsScreen > ListTile "Catálogos"` (eliminado)
  - ✅ `SettingsScreen > ListTile "Administrar himnario"` (nuevo, unificado)
  - ✅ `HimnarioHomeScreen > Card "Administrar himnario"` (nuevo, descubrimiento)
  - ✅ Pantalla dedicada con 2 tabs internos

---

## Preguntas abiertas

1. **¿La búsqueda en el tab Himnos entra en v1.0.1?** Sugerencia: NO, diferir a v1.0.2 si la lista crece > 200 himnos. Para 250 himnos del catálogo adventista, el scroll es suficiente.

2. **¿El FAB debe ser extendido (con label) o mini (solo icono)?** El style guide no especifica. Sugerencia: extendido (más descubrible, especialmente en "Importar catálogo" donde el icono solo podría no ser claro).

3. **¿Soporte para "Duplicar himno" como swipe action?** Útil para crear variantes (misma letra, diferente melodía). Sugerencia: NO en v1.0.1, diferir a v1.1+.

4. **¿Mostrar preview del himno al tap largo (long press)?** Sugerencia: NO, mantener flujo simple: tap = preview, swipe = editar.

5. **El usuario mencionó `gold #D4A574` para FAB.** El style guide LOCKED dice `goldPrimary = #CCA43B`. **Conflicto:** usar #CCA43B (lock) por consistencia.

6. **¿El tab "Catálogos" debe mostrar un "Sample preview" de los himnos al tap?** (mostrar los primeros 3-5 himnos en un bottom sheet). Sugerencia: NO en v1.0.1, NICE TO HAVE.

7. **¿Exportar debe permitir elegir qué himnos exportar** (filtro por favorito, por letra) o solo "todo el catálogo activo"? Sugerencia: solo "todo el catálogo activo" en v1.0.1.

---

*Wireframe creado por @design — pendiente revisión de @arqui antes de implementar. Decisiones D4 (quitar glassmorphism) y D8 (administrar himnario unificado) ya incorporadas.*
