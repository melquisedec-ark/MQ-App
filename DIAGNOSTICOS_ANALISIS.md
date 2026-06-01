# Análisis de Diagnósticos — flutter analyze

> Generado: 2026-05-28
> Revisado por @arqui y @curie: 2026-05-28
> Total: **68 issues** (0 errors, 1 warning, 67 info)

---

## Resumen por severidad

| Severidad | Cantidad | Requiere acción |
|-----------|----------|-----------------|
| 🔴 **error** | 0 | ❌ No |
| 🟡 **warning** | 1 | ⚠️ Sí (variable no usada) |
| 🔵 **info** | 67 | 🔍 Depende del caso |

## Resumen por categoría

| Categoría | Cantidad | Prioridad |
|-----------|----------|-----------|
| `prefer_const_constructors` | 30 | 🟢 Baja (solo test/lib, sin impacto) |
| `require_trailing_commas` | 20 | 🟢 Baja (cosmético) |
| `deprecated_member_use` | 3 | 🟡 Media (deprecado desde Flutter 3.35.0 / Riverpod 2.x) |
| `prefer_const_declarations` | 2 | 🟢 Baja (cosmético) |
| `sized_box_for_whitespace` | 2 | 🟢 Baja (cosmético) |
| `todo` | 2 | ⚪ N/A (comentarios de código) |
| `constant_identifier_names` | 1 | 🟢 Baja (naming style) |
| `no_leading_underscores_for_local_identifiers` | 1 | 🟢 Baja (test style) |
| `prefer_const_literals_to_create_immutables` | 1 | 🟢 Baja (cosmético) |
| `prefer_function_declarations_over_variables` | 1 | 🟢 Baja (test style) |
| `unused_local_variable` | 1 | 🟢 Baja (variable no usada en test, insert sí es necesario) |
| `use_build_context_synchronously` | 1 | 🟢 Baja (ya protegido con `if (mounted)`) |

---

## 1. 🟢 BAJA — `unused_local_variable`

### Archivo: `test/unit/core/database/user_data_backup_test.dart:178`

```dart
final arrId = await db.insert('Arreglo_Musical', {
  'version_pais_id': 1,
  'usuario_id': userId,
  'nombre_arreglo': 'Versión Acústica',
  'tonalidad_base': 'G',
});
// arrId nunca se usa en assertions posteriores
```

**Problema**: La variable `arrId` se asigna pero nunca se usa en ninguna aserción.

**Riesgo**: ❌ Ninguno. `db.insert()` lanza excepción si falla, así que el test sí detectaría errores. La variable simplemente no se verifica. El insert en sí es setup necesario para el test.

**Acción**: Eliminar la asignación (`await db.insert(...)` sin `final arrId =`) o agregar `expect(arrId, greaterThan(0))` para mejorar diagnóstico.

---

## 2. 🟡 MEDIA — `deprecated_member_use` (3 ocurrencias)

### 2a. `lib/presentation/views_admin/crud_hymns/hymn_form_screen.dart:354`

```dart
DropdownButtonFormField<int>(
  value: _selectedPaisId,  // ← deprecated, usar initialValue en vez de value
)
```

**Problema**: Usa `value` en un `DropdownButtonFormField` de Flutter. A partir de Flutter 3.35.0 (PR flutter/flutter#170805), `value` fue deprecado en favor de `initialValue`.

**Riesgo**: 🟡 **MEDIO**. El tipo (`int?`) es idéntico, el comportamiento es exactamente el mismo — la migración es un rename directo sin cambios funcionales.

**Acción**: Reemplazar `value:` por `initialValue:`.

### 2b. `test/widget/projection_app_test.dart:32-36` (2 ocurrencias)

```dart
controlRepositoryProvider.overrideWithProvider(
  Provider<ControlRepository>((ref) => MockControlRepository()),
),
```

**Problema**: Usa `overrideWithProvider` deprecado en Riverpod 2.x en favor de `overrideWith`.

**Riesgo**: 🟡 **MEDIO**. Solo en tests. La migración es simplemente eliminar el wrapper `Provider<...>()` y pasar el callback directamente a `overrideWith`.

**Acción**: Reemplazar `.overrideWithProvider(Provider<Foo>((ref) => ...))` por `.overrideWith((ref) => ...)`.

---

## 3. 🟢 BAJA — `use_build_context_synchronously`

### Archivo: `lib/presentation/views_admin/crud_catalogs/fondo_tab.dart:313`

### 📌 CORRECCIÓN DE REVISIÓN

> ❌ El análisis original describía `Navigator.of(context).pop()` sin guard — **esto es incorrecto**.
> El código **YA tiene** `if (mounted)` protegiendo el uso de `context`.

### Código real (líneas 292-322):

```dart
onPressed: () async {
  try {
    final result = await FilePicker.platform.pickFiles(...);
    if (result != null && result.files.isNotEmpty) {
      final localPath = await FileStorageService.copyToFondos(...);
      setState(() { _rutaController.text = localPath; });
    }
  } catch (e) {
    if (mounted) {                                                    // ← GUARD YA EXISTE
      ScaffoldMessenger.of(context).showSnackBar(                      // ← L313: protegido
        SnackBar(content: Text('Error al copiar archivo: $e')),
      );
    }
  }
},
```

**Problema**: El linter `use_build_context_synchronously` se dispara igual porque el `if (mounted)` está dentro de un `catch` tras un `await`. Algunos analizadores tienen análisis de flujo limitado con excepciones.

**Riesgo**: 🟢 **BAJO — código ya es seguro**. `ScaffoldMessenger.of(context)` degrada gracefulmente incluso sin guard. El `if (mounted)` existente es la protección estándar.

**Acción**: ❌ **Diferir**. El código ya es seguro. Opcionalmente migrar a `if (context.mounted)` (Flutter 3.22+) para mayor claridad, pero no urgente.

---

## 4. 🟢 BAJA — `prefer_const_constructors` (30 ocurrencias)

### Afecta a 6 archivos de lib/ y 8 archivos de test/

**Problema**: Objetos que podrían ser `const` pero se construyen sin la palabra clave.

**Riesgo**: ❌ Ninguno funcional. Solo es una optimización de rendimiento (menos allocations en el widget tree).

**Acción**: No urgente. Se puede aplicar `dart fix --apply` automáticamente cuando se quiera limpiar.

### Archivos en lib/:
| Archivo | Líneas |
|---------|--------|
| `lib/data/datasources/local/audio_local_datasource.dart` | 106 |
| `lib/data/datasources/remote/grpc_control_datasource.dart` | 40-44 |
| `lib/data/datasources/remote/grpc_display_server.dart` | 97-98 |
| `lib/presentation/views_admin/crud_catalogs/fondo_tab.dart` | 281, 777 |
| `lib/presentation/views_personal/hymn_scroll/hymn_detail_screen.dart` | 873 |
| `lib/presentation/views_projection/providers/connection_providers.dart` | 68 |

### Archivos en test/:
| Archivo | Líneas |
|---------|--------|
| `test/unit/core/chords/chord_parser_test.dart` | 16-75 (15 ocurrencias) |
| `test/unit/presentation/projection_actions_test.dart` | 68, 75, 121, 192, 235 |
| `test/unit/core/window_manager/subprocess_window_service_test.dart` | 120 |

---

## 5. 🟢 BAJA — `require_trailing_commas` (20 ocurrencias)

### Afecta a múltiples archivos

**Problema**: Faltan comas finales en listas de argumentos/parámetros.

**Riesgo**: ❌ Ninguno. Solo formateo. Sin trailing comma, el formateador de Dart no pone saltos de línea uno-por-línea.

**Acción**: Aplicar `dart format` cuando se quiera limpiar. No urgente.

### Archivos principales en lib/:
| Archivo | Líneas |
|---------|--------|
| `lib/data/datasources/remote/grpc_control_datasource.dart` | 267, 291 |
| `lib/presentation/views_admin/crud_hymns/hymn_form_screen.dart` | 369 |
| `lib/presentation/views_personal/dashboard/connected_dashboard.dart` | 281 |
| `lib/presentation/views_personal/hymn_scroll/hymn_detail_screen.dart` | 870, 889, 897 |
| `lib/presentation/views_projection/controller/minimal_control_screen.dart` | 249 |
| `lib/presentation/views_projection/display/live_projection_screen.dart` | 78 |

### Archivos en test/:
| Archivo | Líneas |
|---------|--------|
| `test/widget/control_sheets_test.dart` | 113, 123 |
| `test/widget/projection_app_test.dart` | 275-459 (10 ocurrencias) |

---

## 6. 🟢 BAJA — `sized_box_for_whitespace` (2 ocurrencias)

### 📌 CORRECCIÓN DE REVISIÓN

> ❌ El análisis original decía que estas líneas usaban `Container(height:)` puro para espaciado.
> **Esto es incorrecto**. Ambos Containers tienen **`child` + `width: double.infinity`** — no son spacers.

### Código real:

**`hymn_detail_screen.dart:490`**:
```dart
Container(
  width: double.infinity,
  child: AdaptiveStanzaText(...),
)
```

**`live_projection_screen.dart:390`**:
```dart
Container(
  width: double.infinity,
  child: AdaptiveStanzaText(...),
)
```

Ninguno activaría el lint `sized_box_for_whitespace` (que solo apunta a Containers sin child). El análisis original posiblemente se basó en una versión anterior del código o en líneas incorrectas.

**Estado real**: Probablemente estos warnings ya no existen en el código actual, o corresponden a líneas diferentes. Se requiere regenerar `flutter analyze` para confirmar.

**Acción**: ❌ **Diferir** hasta regenerar el análisis desde el código actual.

---

## 7. 🟢 BAJA — `constant_identifier_names`

### `lib/core/database/database_helper.dart:36`

```dart
static const int SCHEMA_VERSION = 6;  // ← debería ser schemaVersion
```

**Problema**: La constante no sigue lowerCamelCase.

**Riesgo**: ❌ Ninguno. Solo estilo. Cambiarlo requeriría actualizar todas las referencias.

**Acción**: Renombrar si se decide adoptar el estilo. Baja prioridad.

---

## 8. 🟢 BAJA — Misceláneos (5 ocurrencias)

| Código | Archivo | Línea | Impacto |
|--------|---------|-------|---------|
| `prefer_const_declarations` | `lib/data/datasources/remote/grpc_display_server.dart` | 89 | 🟢 Ninguno |
| `prefer_const_declarations` | `test/widget/projection_slides_test.dart` | 65 | 🟢 Ninguno |
| `prefer_const_literals_to_create_immutables` | `lib/presentation/views_admin/crud_catalogs/fondo_tab.dart` | 780 | 🟢 Ninguno |
| `prefer_function_declarations_over_variables` | `test/unit/core/window_manager/subprocess_window_service_test.dart` | 112 | 🟢 Ninguno |
| `no_leading_underscores_for_local_identifiers` | `test/widget/control_sheets_test.dart` | 29 | 🟢 Ninguno |

---

## 9. ⚪ INFORMATIVO — `todo` (2 ocurrencias)

### `lib/core/window_manager/window_service.dart:299,310`

```dart
// TODO(web): Habilitar cuando dart:html esté disponible
// TODO(web): Implementar vía BroadcastChannel cuando esté disponible
```

**Problema**: No son errores ni warnings. Son recordatorios de funcionalidad futura (soporte web).

**Acción**: ❌ Ninguna. Solo documentación.

---

## Correcciones de la revisión (@arqui + @curie)

| # | Issue | Severidad original | Severidad corregida | Diferencia |
|---|-------|-------------------|---------------------|------------|
| 1 | `use_build_context_synchronously` | 🟡 Media | 🟢 **Baja** | El código **YA** tiene `if (mounted)`. No hay bug. |
| 2 | `unused_local_variable` | 🟡 Media | 🟢 **Baja** | `db.insert()` lanza excepción si falla — el test sí detecta errores. |
| 3 | `sized_box_for_whitespace` (×2) | 🟢 Baja | ❌ **No aplica** | Los Containers tienen child — no son spacers. Probablemente ya no existen en HEAD. |
| 4 | `deprecated_member_use` (Dropdown) | 🟡 Media | 🟡 **Media** (✅ confirmado) | Migración segura. Versión correcta: Flutter 3.35.0 (no 3.33). |
| 5 | `deprecated_member_use` (Riverpod) | 🟡 Media | 🟡 **Media** (✅ confirmado) | Migración segura. Deprecado en Riverpod 2.x (no 3.0.0). |
| 6 | `constant_identifier_names` | 🟢 Baja | 🟢 **Baja** (✅ confirmado) | Valor real: `= 6` (no `= 2`). 20 referencias en total. |

## Matriz de prioridades (corregida)

| Prioridad | Items | Acción requerida |
|-----------|-------|------------------|
| 🔴 **Crítica** | 0 | — |
| 🟡 **Media** | 3 | `deprecated_member_use` (×3) — migraciones triviales |
| 🟢 **Baja** | ~62 | `prefer_const_constructors` (30), `require_trailing_commas` (20), `unused_local_variable` (1), `constant_identifier_names` (1), y ~10 misceláneos |
| ⚪ **Informativo** | 2 | `todo` comments |
| ❌ **Falso positivo** | 3 | `sized_box_for_whitespace` (×2 — Containers tienen child), `use_build_context_synchronously` (×1 — ya guardado) |

---

## Conclusión

- **0 errores** — el código compila sin problemas
- **1 warning** — `unused_local_variable`: variable capturada pero no usada en test; `db.insert()` sí es necesario (lanza excepción si falla)
- **Ningún bug real** 🐛 — el análisis original identificó incorrectamente `use_build_context_synchronously` como potencial crash, pero el código ya tiene `if (mounted)`
- **3 deprecaciones confirmadas** — 1 en lib/ (`value` → `initialValue`, trivially safe) y 2 en tests (`overrideWithProvider` → `overrideWith`, trivially safe)
- **3 falsos positivos** — el análisis se basó en un snapshot desactualizado del código (`sized_box_for_whitespace` y `use_build_context_synchronously`)
- **Ninguna pérdida de funcionalidad** al corregir cualquiera de estos issues
