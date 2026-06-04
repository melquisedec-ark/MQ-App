# Wireframe 08 — Reading Settings Sheet (O9)

> **Propósito**: Documentar el bottom sheet de ajustes de lectura que reemplaza al icono de dado aleatorio.
> **Origen**: O9 del feedback post-v1.0.1
> **Versión**: v1.0.2
> **Audiencia**: @dev (implementador), @arqui (revisor técnico)

---

## ✅ Decisión final (DO2)

- **`bibleAppearanceProvider` INDEPENDIENTE** — NO reusa `hymnAppearanceProvider`
- Vive en `lib/features/biblia/application/providers/bible_appearance_provider.dart`
- Persiste en `BibliaConfigRepository` (misma BD que notas, favoritos, historial)
- 4 campos: `fontScale` (0.8-1.5), `fontFamily`, `textColor`, `lineHeight`

---

## 1. Trigger

### Antes (v1.0.1)
- Icono: `Icons.casino_rounded` (dado aleatorio)
- Acción: navega a un versículo aleatorio
- Ubicación: `_ReaderBottomBar` (esquina inferior derecha)

### Después (v1.0.2)
- Icono: `Icons.tune_rounded` (⚙️ tipo tune/ajustes)
- Acción: abre `ReadingSettingsSheet.show(context)`
- Tooltip: "Ajustes de lectura"
- Ubicación: misma posición (esquina inferior derecha del bottom bar)

---

## 2. Bottom Sheet — Layout

### 2.1 Estructura general

```
┌────────────────────────────────────────┐
│        [============]   (drag handle)  │
│                                        │
│   ⚙️  Ajustes de lectura               │
│      Biblia                            │
│                                        │
├────────────────────────────────────────┤
│  TAMAÑO DE LETRA                       │
│  ┌──┐ ────────●───── ┌──┐             │
│  A-│                  │+A              │
│                                        │
│  0.8x            1.0x           1.5x   │
│                                        │
├────────────────────────────────────────┤
│  FUENTE                                │
│  ┌──────┐  ┌──────┐  ┌──────┐         │
│  │Sistema│  │Serif │  │Mono  │         │
│  └──────┘  └──────┘  └──────┘         │
│  (seleccionado = borde gold)           │
│                                        │
├────────────────────────────────────────┤
│  COLOR DE TEXTO                        │
│  ⬜    ⬛    🟫    🟦                  │
│ Blanco Negro Sepia Azul               │
│  (seleccionado = borde gold)          │
│                                        │
├────────────────────────────────────────┤
│  INTERLINEADO                          │
│  ┌──┐ ──────●────── ┌──┐              │
│  ▎ │                  │▎▎              │
│  1.4            1.6           2.0     │
│                                        │
├────────────────────────────────────────┤
│  MODO DE LECTURA                       │
│  ┌─────────┐  ┌─────────┐             │
│  │ Verso   │  │Capítulo │             │
│  │  único  │  │ completo│             │
│  └─────────┘  └─────────┘             │
│                                        │
│  (Capítulo = default, seleccionado)   │
│                                        │
└────────────────────────────────────────┘
```

### 2.2 Tokens visuales

| Elemento | Token | Notas |
|---|---|---|
| Fondo del sheet | `colorScheme.surface` | Mismo que la app |
| Título | `textTheme.titleLarge` + gold primary | "Ajustes de lectura" |
| Subtítulo | `textTheme.bodySmall` + `onSurfaceVariant` | "Biblia" |
| Labels de sección | `textTheme.labelMedium` + uppercase | TAMAÑO DE LETRA, FUENTE, etc. |
| Slider activo | `goldPrimary` (#CCA43B) | `colorScheme.primary` |
| Slider inactivo | `colorScheme.surfaceContainerHigh` | Track de fondo |
| Botón seleccionado | Borde 2px `goldPrimary` | Chips, slider value, font family |
| Botón no seleccionado | Borde 1px `colorScheme.outlineVariant` | Mismo color que Cards |
| Handle de drag | 4×40 px, `colorScheme.outlineVariant` | Border radius 2px |

---

## 3. Controles — Detalle

### 3.1 Tamaño de letra (Slider)

```yaml
Tipo: Slider
Min: 0.8
Max: 1.5
Divisions: 7 (0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5)
Default: 1.0
Label: valor actual (ej. "1.0x")
OnChangeLive: true (aplica en vivo)
Persistencia: ref.read(bibleAppearanceProvider.notifier).setFontScale(value)
```

**Visual**:
- Iconos `text_decrease` y `text_increase` a los lados
- Track con valor seleccionado en gold
- Label con el valor numérico debajo

### 3.2 Fuente (Choice chips)

```yaml
Tipo: Wrap de ChoiceChip
Opciones:
  - { id: 'system', label: 'Sistema', font: null (Roboto/SF Pro) }
  - { id: 'serif', label: 'Serif', font: 'serif' (Merriweather) }
  - { id: 'monospace', label: 'Mono', font: 'monospace' }
Default: 'system'
Single-select: true
Persistencia: setFontFamily(option)
```

**Nota**: en v1.0.2 no se cargan fuentes custom. 'serif' y 'monospace' usan las fuentes del sistema operativo. Si en el futuro se quiere Merriweather, se agrega al `pubspec.yaml`.

### 3.3 Color de texto (Color swatches)

```yaml
Tipo: Row de IconButton con Container circular
Opciones:
  - { id: 'white', color: Colors.white, label: 'Blanco' }
  - { id: 'black', color: Colors.black, label: 'Negro' }
  - { id: 'sepia', color: Color(0xFF704214), label: 'Sepia' }
  - { id: 'blue', color: Color(0xFF1E3A8A), label: 'Azul' }
Default: 'black' (o 'white' si dark mode)
Single-select: true
Indicador de selección: borde 2px gold + check icon
Persistencia: setTextColor(Color)
```

### 3.4 Interlineado (Slider)

```yaml
Tipo: Slider
Min: 1.4
Max: 2.0
Divisions: 6 (1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 2.0)
Default: 1.6
OnChangeLive: true
Persistencia: setLineHeight(value)
```

**Visual**:
- Iconos `format_line_spacing` y `format_line_spacing` más/menos a los lados
- Track con valor seleccionado en gold

### 3.5 Modo de lectura (SegmentedButton)

```yaml
Tipo: SegmentedButton<ViewMode>
Opciones:
  - { value: verse, label: 'Verso único', icon: Icons.article_outlined }
  - { value: chapter, label: 'Capítulo completo', icon: Icons.menu_book_outlined }
Default: chapter (cambia de verse en v1.0.2)
Single-select: true
Persistencia: ref.read(readerViewModeProvider.notifier).setViewMode(mode)
```

**Nota**: este control replica el toggle del AppBar (`_ViewModeToggleButton`) pero dentro del sheet, por conveniencia.

---

## 4. Vista previa en vivo

Mientras el usuario mueve los sliders, los cambios se reflejan en el texto del BibleReader (que está detrás del bottom sheet, semi-transparente).

```dart
// En BibleReaderScreen, al aplicar appearance:
TextScaler.linear(appearance.fontScale)  // Para escalado de texto
TextStyle(
  fontFamily: appearance.fontFamily,
  color: appearance.textColor,
  height: appearance.lineHeight,
)
```

---

## 5. Persistencia

### 5.1 Claves en `BibliaConfigKeys`

```dart
static const String fontScale = 'biblia.font_scale';
static const String fontFamily = 'biblia.font_family';
static const String textColor = 'biblia.text_color';
static const String lineHeight = 'biblia.line_height';
```

### 5.2 BibleAppearanceNotifier

```dart
class BibleAppearanceNotifier extends StateNotifier<BibleAppearanceState> {
  BibleAppearanceNotifier(this._ref) : super(BibleAppearanceState.initial) {
    _loadFromDb();
  }
  
  Future<void> _loadFromDb() async {
    final repo = _ref.read(bibliaConfigRepositoryProvider);
    final fontScale = await repo.get(BibliaConfigKeys.fontScale, defaultValue: '1.0');
    final fontFamily = await repo.get(BibliaConfigKeys.fontFamily, defaultValue: 'system');
    final textColor = await repo.get(BibliaConfigKeys.textColor, defaultValue: 'black');
    final lineHeight = await repo.get(BibliaConfigKeys.lineHeight, defaultValue: '1.6');
    state = BibleAppearanceState(
      fontScale: double.tryParse(fontScale) ?? 1.0,
      fontFamily: fontFamily,
      textColor: _parseColor(textColor),
      lineHeight: double.tryParse(lineHeight) ?? 1.6,
    );
  }
  
  Future<void> setFontScale(double value) async {
    state = state.copyWith(fontScale: value);
    await _persist(BibliaConfigKeys.fontScale, value.toString());
  }
  
  // Similar para setFontFamily, setTextColor, setLineHeight
  
  Future<void> _persist(String key, String value) async {
    final repo = _ref.read(bibliaConfigRepositoryProvider);
    await repo.set(key, value);
  }
}
```

---

## 6. Accesibilidad

- **Slider values con label** ("1.0x" no solo el track)
- **Color swatches con `Semantics(label: 'Color de texto blanco')`**
- **Font family chips con descripción** ("Sistema (default del sistema operativo)")
- **Modo lectura con icon + label** para diferenciarlos sin color
- **Contraste mínimo** WCAG AA para el texto (4.5:1) cuando se aplica cualquier color

---

## 7. Tests

### 7.1 Unit tests

- `bible_appearance_provider_test.dart`:
  - Default state: fontScale=1.0, fontFamily='system', textColor=black, lineHeight=1.6
  - `setFontScale(1.5)` → state actualiza + persiste en BD
  - `setTextColor(Colors.white)` → state actualiza + persiste
  - Hidratación desde BD funciona

### 7.2 Widget tests

- `reading_settings_sheet_test.dart`:
  - Renderiza los 5 controles
  - Tap en opción de fuente → cambia selección
  - Mover slider → actualiza label
  - Cerrar sheet con tap fuera → no persiste cambios (a menos que ya estén guardados)

---

## 8. Archivos

### Nuevos
- `lib/features/biblia/application/providers/bible_appearance_provider.dart` (153 líneas)
- `lib/features/biblia/presentation/widgets/reading_settings_sheet.dart` (411 líneas)
- `test/features/biblia/bible_appearance_provider_test.dart` (pendiente)
- `test/features/biblia/widgets/reading_settings_sheet_test.dart` (pendiente)

### Modificados
- `lib/features/biblia/presentation/screens/bible_reader_screen.dart`:
  - Reemplazar `Icons.casino_rounded` por `Icons.tune_rounded` en `_ReaderBottomBar`
  - Agregar import de `bible_appearance_provider.dart` y `reading_settings_sheet.dart`
  - Aplicar `appearance` en `_VerseCard` y `_ChapterVerseList` (textScaler, fontFamily, textColor, lineHeight)
- `lib/features/biblia/data/repositories/biblia_config_repository.dart`:
  - Agregar 4 nuevas claves a `BibliaConfigKeys`

---

## 9. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Rendimiento: aplicar TextScaler en cada build | Usar `MediaQuery.textScalerOf(context)` con el valor cacheado del state |
| Color blanco sobre fondo claro = ilegible | Validar en theme dark que el contraste sea suficiente |
| Usuario no encuentra el botón (era un "dado" antes) | Tooltip explícito "Ajustes de lectura" + ícono `tune` conocido |
| `fontScale` extremo (0.8x o 1.5x) puede romper layout | Limitar a rango razonable (0.8-1.5); clamp en setter |
| Color sepia/azul no soportado por dark theme | Documentar que en dark mode solo blanco/negro son prácticos |

---

## 10. Diferido para v1.1+

- Más fuentes (Merriweather, Lora) — requiere `pubspec.yaml` assets
- Color de FONDO (no solo texto) — sepia background
- Tema "noche" completo (background negro, texto blanco)
- Presets ("Lectura nocturna", "Estudio", "Presentación")
- Exportar/importar configuración de apariencia
