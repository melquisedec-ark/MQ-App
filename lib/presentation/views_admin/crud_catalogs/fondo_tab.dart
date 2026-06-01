import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/fondo_pantalla_tipo.dart';
import '../../../core/utils/file_storage_service.dart';
import '../../../domain/entities/fondo_pantalla.dart';
import '../../views_admin/providers/admin_providers.dart'
    show
        getAllFondosUseCaseProvider,
        createFondoUseCaseProvider,
        updateFondoUseCaseProvider,
        deleteFondoUseCaseProvider;
import '../../views_admin/providers/auth_providers.dart' show currentUserProvider;
import '../../shared_widgets/providers/fondo_options_provider.dart'
    show fondosActivosProvider;
import '../../shared_widgets/providers/appearance_provider.dart'
    show hymnAppearanceProvider;

// ─────────────────────────────────────────────────────────────
// Provider local: lista de fondos
// ─────────────────────────────────────────────────────────────

final _fondoListProvider =
    FutureProvider.autoDispose<List<FondoPantalla>>((ref) {
  return ref.watch(getAllFondosUseCaseProvider).execute();
});

// ─────────────────────────────────────────────────────────────

/// Tab de administración de fondos de pantalla.
///
/// Permite crear, editar y eliminar fondos. El formulario es condicional:
/// - Si tipo = color_solido → campo color_hex con vista previa
/// - Si tipo = imagen → campo ruta_archivo
/// Incluye checkbox "Predeterminado".
class FondoTab extends ConsumerStatefulWidget {
  const FondoTab({super.key});

  @override
  ConsumerState<FondoTab> createState() => _FondoTabState();
}

class _FondoTabState extends ConsumerState<FondoTab> {
  // Formulario
  final _nombreController = TextEditingController();
  final _rutaController = TextEditingController();
  final _colorController = TextEditingController();
  FondoPantallaTipo _tipo = FondoPantallaTipo.imagen;
  bool _esPredeterminado = false;

  // Modo edición
  FondoPantalla? _editando;

  @override
  void dispose() {
    _nombreController.dispose();
    _rutaController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _nombreController.clear();
      _rutaController.clear();
      _colorController.clear();
      _tipo = FondoPantallaTipo.imagen;
      _esPredeterminado = false;
      _editando = null;
    });
  }

  void _cargarEnFormulario(FondoPantalla fondo) {
    setState(() {
      _editando = fondo;
      _nombreController.text = fondo.nombre;
      _tipo = fondo.tipo;
      _esPredeterminado = fondo.esPredeterminado;
      if (fondo.tipo == FondoPantallaTipo.colorSolido) {
        _colorController.text = fondo.colorHex ?? '';
        _rutaController.clear();
      } else {
        _rutaController.text = fondo.rutaArchivo ?? '';
        _colorController.clear();
      }
    });
  }

  Future<void> _guardar() async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;

    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre es requerido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final rutaArchivo =
        _tipo != FondoPantallaTipo.colorSolido ? _rutaController.text.trim() : null;
    final colorHex =
        _tipo == FondoPantallaTipo.colorSolido ? _colorController.text.trim() : null;

    try {
      if (_editando != null) {
        // Si el usuario cambió el archivo, eliminar la copia anterior
        if (_tipo != FondoPantallaTipo.colorSolido &&
            rutaArchivo != null &&
            _editando!.rutaArchivo != null &&
            _editando!.rutaArchivo != rutaArchivo) {
          await FileStorageService.deleteIfAppFile(_editando!.rutaArchivo!);
        }
        // Actualizar
        await ref.read(updateFondoUseCaseProvider).execute(
              id: _editando!.id,
              nombre: nombre,
              tipo: _tipo,
              rutaArchivo: rutaArchivo,
              colorHex: colorHex,
              esPredeterminado: _esPredeterminado,
              activo: true,
              admin: admin,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fondo "$nombre" actualizado')),
          );
        }
      } else {
        // Crear
        await ref.read(createFondoUseCaseProvider).execute(
              nombre: nombre,
              tipo: _tipo,
              rutaArchivo: rutaArchivo,
              colorHex: colorHex,
              esPredeterminado: _esPredeterminado,
              activo: true,
              admin: admin,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fondo "$nombre" creado')),
          );
        }
      }
      _resetForm();
      ref.invalidate(_fondoListProvider);
      ref.invalidate(fondosActivosProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _eliminarFondo(FondoPantalla fondo) async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar fondo'),
        content: Text('¿Eliminar fondo "${fondo.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(deleteFondoUseCaseProvider).execute(
            fondo.id,
            admin: admin,
          );
      if (_editando?.id == fondo.id) _resetForm();
      // Limpiar selección si el fondo eliminado era el activo
      final currentFondo = ref.read(hymnAppearanceProvider).selectedFondo;
      if (currentFondo?.id == fondo.id) {
        ref.read(hymnAppearanceProvider.notifier).clearFondo();
      }
      ref.invalidate(_fondoListProvider);
      ref.invalidate(fondosActivosProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fondo "${fondo.nombre}" eliminado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Formulario ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editando != null ? 'Editar fondo' : 'Nuevo fondo',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 12),
                // Nombre
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                // Tipo
                DropdownButtonFormField<FondoPantallaTipo>(
                  key: ValueKey(_tipo),
                  initialValue: _tipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: FondoPantallaTipo.imagen,
                      child: Text('Imagen'),
                    ),
                    DropdownMenuItem(
                      value: FondoPantallaTipo.colorSolido,
                      child: Text('Color sólido'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _tipo = v);
                  },
                ),
                const SizedBox(height: 12),
                // Campo condicional
                if (_tipo == FondoPantallaTipo.colorSolido)
                  _buildColorField(theme)
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _rutaController,
                          decoration: InputDecoration(
                            labelText: 'Ruta de imagen',
                            hintText: 'Selecciona un archivo...',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.folder_open),
                        tooltip: 'Seleccionar archivo',
                        onPressed: () async {
                          try {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.media,
                              allowMultiple: false,
                              withReadStream: true,
                            );
                            if (result != null && result.files.isNotEmpty) {
                              final file = result.files.single;
                              final localPath = await FileStorageService
                                  .copyToFondos(
                                sourcePath: file.path ?? '',
                                fileName: file.name,
                                readStream: file.readStream,
                              );
                              setState(() {
                                _rutaController.text = localPath;
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Error al copiar archivo: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                // Checkbox predeterminado
                CheckboxListTile(
                  title: const Text('Predeterminado'),
                  value: _esPredeterminado,
                  onChanged: (v) {
                    setState(() => _esPredeterminado = v ?? false);
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),
                // Botones
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _guardar,
                        icon: Icon(
                          _editando != null ? Icons.save : Icons.add,
                          size: 20,
                        ),
                        label: Text(_editando != null ? 'Actualizar' : 'Crear'),
                      ),
                    ),
                    if (_editando != null) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _resetForm,
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        // ── Lista de fondos ─────────────────────────────────────
        Expanded(
          child: ref.watch(_fondoListProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (fondos) {
              if (fondos.isEmpty) {
                return Center(
                  child: Text(
                    'No hay fondos registrados',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: fondos.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final fondo = fondos[index];
                  return ListTile(
                    leading: _buildFondoPreview(fondo),
                    title: Text(fondo.nombre),
                    subtitle: Text(
                      [
                        _tipoLabel(fondo.tipo),
                        if (fondo.esPredeterminado) 'Predeterminado',
                        if (!fondo.activo) 'Inactivo',
                      ].join(' · '),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar',
                          onPressed: () => _cargarEnFormulario(fondo),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          tooltip: 'Eliminar',
                          onPressed: () => _eliminarFondo(fondo),
                        ),
                      ],
                    ),
                    onTap: () => _cargarEnFormulario(fondo),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorField(ThemeData theme) {
    // Intentar parsear el color hex para vista previa
    Color? previewColor;
    final hex = _colorController.text.trim();
    if (hex.isNotEmpty) {
      try {
        final cleanHex = hex.replaceFirst('#', '');
        if (cleanHex.length == 6) {
          previewColor = Color(int.parse('FF$cleanHex', radix: 16));
        } else if (cleanHex.length == 8) {
          previewColor = Color(int.parse(cleanHex, radix: 16));
        }
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color hex',
                  hintText: '#RRGGBB',
                  isDense: true,
                  prefixText: '#',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (previewColor != null) ...[
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: previewColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showColorPicker(context, theme, _colorController.text.trim()),
            icon: const Icon(Icons.palette, size: 18),
            label: const Text('Selector de color'),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Colores rápidos',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ColorOption(
              color: const Color(0xFFB71C1C),
              hex: '#B71C1C',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#B71C1C',
              onTap: () {
                _colorController.text = '#B71C1C';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFFD32F2F),
              hex: '#D32F2F',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#D32F2F',
              onTap: () {
                _colorController.text = '#D32F2F';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFFF44336),
              hex: '#F44336',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#F44336',
              onTap: () {
                _colorController.text = '#F44336';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFFE91E63),
              hex: '#E91E63',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#E91E63',
              onTap: () {
                _colorController.text = '#E91E63';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFF9C27B0),
              hex: '#9C27B0',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#9C27B0',
              onTap: () {
                _colorController.text = '#9C27B0';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFF673AB7),
              hex: '#673AB7',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#673AB7',
              onTap: () {
                _colorController.text = '#673AB7';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFF3F51B5),
              hex: '#3F51B5',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#3F51B5',
              onTap: () {
                _colorController.text = '#3F51B5';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFF2196F3),
              hex: '#2196F3',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#2196F3',
              onTap: () {
                _colorController.text = '#2196F3';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFF03A9F4),
              hex: '#03A9F4',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#03A9F4',
              onTap: () {
                _colorController.text = '#03A9F4';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFF009688),
              hex: '#009688',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#009688',
              onTap: () {
                _colorController.text = '#009688';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFF4CAF50),
              hex: '#4CAF50',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#4CAF50',
              onTap: () {
                _colorController.text = '#4CAF50';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFF8BC34A),
              hex: '#8BC34A',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#8BC34A',
              onTap: () {
                _colorController.text = '#8BC34A';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFFCDDC39),
              hex: '#CDDC39',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#CDDC39',
              onTap: () {
                _colorController.text = '#CDDC39';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFFFFEB3B),
              hex: '#FFEB3B',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#FFEB3B',
              onTap: () {
                _colorController.text = '#FFEB3B';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFFFFC107),
              hex: '#FFC107',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#FFC107',
              onTap: () {
                _colorController.text = '#FFC107';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFFFF9800),
              hex: '#FF9800',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#FF9800',
              onTap: () {
                _colorController.text = '#FF9800';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFFFF5722),
              hex: '#FF5722',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#FF5722',
              onTap: () {
                _colorController.text = '#FF5722';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFF795548),
              hex: '#795548',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#795548',
              onTap: () {
                _colorController.text = '#795548';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFF9E9E9E),
              hex: '#9E9E9E',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#9E9E9E',
              onTap: () {
                _colorController.text = '#9E9E9E';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFF607D8B),
              hex: '#607D8B',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#607D8B',
              onTap: () {
                _colorController.text = '#607D8B';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFF000000),
              hex: '#000000',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#000000',
              onTap: () {
                _colorController.text = '#000000';
                setState(() {});
              },
            ),
            _ColorOption(
              color: const Color(0xFFFFFFFF),
              hex: '#FFFFFF',
              isSelected:
                  _colorController.text.trim().toUpperCase() == '#FFFFFF',
              onTap: () {
                _colorController.text = '#FFFFFF';
                setState(() {});
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showColorPicker(BuildContext context, ThemeData theme, String currentHex) {
    // Color inicial: intentar parsear el hex actual, o negro por defecto
    Color initialColor;
    try {
      final clean = currentHex.replaceFirst('#', '');
      if (clean.length == 6) {
        initialColor = Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        initialColor = Color(int.parse(clean, radix: 16));
      } else {
        initialColor = Colors.black;
      }
    } catch (_) {
      initialColor = Colors.black;
    }

    HSVColor hsv = HSVColor.fromColor(initialColor);

    showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Selector de color'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Rectángulo Saturación × Brillo ──
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double w = constraints.maxWidth;
                        return GestureDetector(
                          onPanUpdate: (details) {
                            final dx = (details.localPosition.dx / w).clamp(0.0, 1.0);
                            final dy = (details.localPosition.dy / 200).clamp(0.0, 1.0);
                            setDialogState(() {
                              hsv = HSVColor.fromAHSV(1.0, hsv.hue, dx, 1.0 - dy);
                            });
                          },
                          child: Container(
                            width: w,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: [
                                  HSVColor.fromAHSV(1.0, hsv.hue, 0.0, 1.0).toColor(),
                                  HSVColor.fromAHSV(1.0, hsv.hue, 1.0, 1.0).toColor(),
                                ],
                                stops: const [0.0, 0.5],
                              ),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            foregroundDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black,
                                ],
                                stops: const [0.0, 0.5],
                              ),
                            ),
                            child: CustomPaint(
                              painter: _CrosshairPainter(
                                color: hsv.toColor().computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                saturation: hsv.saturation,
                                brightness: hsv.value,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // ── Slider de Tono (Hue) ──
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF0000), // 0°
                            Color(0xFFFFFF00), // 60°
                            Color(0xFF00FF00), // 120°
                            Color(0xFF00FFFF), // 180°
                            Color(0xFF0000FF), // 240°
                            Color(0xFFFF00FF), // 300°
                            Color(0xFFFF0000), // 360°
                          ],
                        ),
                      ),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 24,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                        ),
                        child: Slider(
                          value: hsv.hue,
                          min: 0.0,
                          max: 360.0,
                          onChanged: (value) {
                            setDialogState(() {
                              hsv = HSVColor.fromAHSV(1.0, value, hsv.saturation, hsv.value);
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ── Previsualización + Hex ──
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: hsv.toColor(),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.dividerColor),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '#${hsv.toColor().toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(hsv.toColor()),
                  child: const Text('Seleccionar'),
                ),
              ],
            );
          },
        );
      },
    ).then((selectedColor) {
      if (selectedColor != null) {
        final hex = '#${selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
        _colorController.text = hex;
        setState(() {});
      }
    });
  }

  Widget _buildFondoPreview(FondoPantalla fondo) {
    if (fondo.tipo == FondoPantallaTipo.colorSolido && fondo.colorHex != null) {
      Color? color;
      try {
        final hex = fondo.colorHex!.replaceFirst('#', '');
        if (hex.length == 6) {
          color = Color(int.parse('FF$hex', radix: 16));
        }
      } catch (_) {}
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color ?? Colors.grey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
      );
    }
    return CircleAvatar(
      backgroundColor: Colors.green.shade100,
      child: Icon(
        Icons.image,
        color: Colors.green.shade700,
      ),
    );
  }

  String _tipoLabel(FondoPantallaTipo tipo) {
    switch (tipo) {
      case FondoPantallaTipo.imagen:
        return 'Imagen';
      case FondoPantallaTipo.colorSolido:
        return 'Color sólido';
    }
  }
}

/// Círculo de color preseleccionado para el formulario de fondos.
class _ColorOption extends StatelessWidget {
  final Color color;
  final String hex;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.hex,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                size: 16,
                color: color.computeLuminance() > 0.5
                    ? Colors.black
                    : Colors.white,
              )
            : null,
      ),
    );
  }
}

/// Pinta un crosshair en la posición saturación/brillo del selector de color.
class _CrosshairPainter extends CustomPainter {
  final Color color;
  final double saturation;
  final double brightness;

  _CrosshairPainter({
    required this.color,
    required this.saturation,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = saturation * size.width;
    final cy = (1.0 - brightness) * size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Círculo
    canvas.drawCircle(Offset(cx, cy), 8, paint);

    // Líneas de crosshair
    canvas.drawLine(Offset(cx - 14, cy), Offset(cx - 5, cy), paint);
    canvas.drawLine(Offset(cx + 5, cy), Offset(cx + 14, cy), paint);
    canvas.drawLine(Offset(cx, cy - 14), Offset(cx, cy - 5), paint);
    canvas.drawLine(Offset(cx, cy + 5), Offset(cx, cy + 14), paint);
  }

  @override
  bool shouldRepaint(_CrosshairPainter oldDelegate) =>
      oldDelegate.saturation != saturation ||
      oldDelegate.brightness != brightness ||
      oldDelegate.color != color;
}
