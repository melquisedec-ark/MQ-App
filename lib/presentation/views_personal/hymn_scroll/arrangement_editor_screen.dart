import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/estrofa_tipo.dart';
import '../../../domain/entities/arreglo_musical.dart';
import '../../../domain/entities/estrofa_arreglo.dart';
import '../../../domain/entities/himno.dart';
import '../../views_admin/crud_hymns/stanza_block_editor.dart';
import '../providers/arreglo_providers.dart';
import '../providers/hymn_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Inner helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Representación mutable de una estrofa durante la edición.
///
/// [tempId] es un identificador local para las keys de widgets;
/// no debe confundirse con el ID persistente de [EstrofaArreglo].
class _EditableStanza {
  int tempId;
  EstrofaTipo tipo;
  String contenido;

  _EditableStanza({
    required this.tempId,
    required this.tipo,
    required this.contenido,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// Pantalla de edición/creación de arreglos musicales.
///
/// Soporta dos modos de operación:
/// - **Creación** ([himno] != null): parte de las estrofas del himno original.
/// - **Edición**  ([arregloId] != null): carga un arreglo existente.
class ArrangementEditorScreen extends ConsumerStatefulWidget {
  final Himno? himno;
  final int? arregloId;

  const ArrangementEditorScreen({
    super.key,
    this.himno,
    this.arregloId,
  }) : assert(
          (himno != null) ^ (arregloId != null),
          'Debe proporcionar himno (creación) o arregloId (edición), no ambos.',
        );

  @override
  ConsumerState<ArrangementEditorScreen> createState() =>
      _ArrangementEditorScreenState();
}

class _ArrangementEditorScreenState
    extends ConsumerState<ArrangementEditorScreen> {
  // ── Estado interno ──────────────────────────────────────────────────────

  /// `null` = modo creación, no-null = modo edición (ID del arreglo).
  int? _arregloId;

  /// Controlador del campo de nombre del arreglo.
  final TextEditingController _nameCtrl = TextEditingController();

  /// Lista mutable de estrofas que el usuario está editando.
  final List<_EditableStanza> _estrofas = [];

  /// Contador para asignar [tempId] únicos a cada [_EditableStanza].
  int _nextTempId = 0;

  /// Evita guardados duplicados (anti-doble-click).
  bool _isSaving = false;

  /// Estado de carga inicial (mientras se obtienen datos de BD).
  bool _isLoading = true;

  /// `true` cuando el usuario ha modificado algo sin guardar.
  bool _isDirty = false;

  /// Tonalidad original del himno (se mantiene fija).
  String _tonalidadBase = '';

  /// ID de la versión de país sobre la que se basa el arreglo.
  int _versionPaisId = 0;

  /// Versión actual del arreglo (para preservar en edición).
  int _currentVersion = 1;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _arregloId = widget.arregloId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Inicialización ──────────────────────────────────────────────────────

  /// Carga los datos iniciales según el modo (creación o edición).
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      if (widget.himno != null) {
        await _initForCreation();
      } else if (widget.arregloId != null) {
        await _initForEdition();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initForCreation() async {
    final himno = widget.himno!;
    _versionPaisId = himno.primaryVersionPaisId;
    _tonalidadBase =
        himno.versiones.firstOrNull?.tonalidadOriginal ?? '';

    if (_versionPaisId <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El himno no tiene versiones de país disponibles.'),
          ),
        );
      }
      return;
    }

    final stanzas = await ref.read(stanzasProvider(_versionPaisId).future);

    if (!mounted) return;
    setState(() {
      _estrofas.addAll(
        stanzas.map(
          (s) => _EditableStanza(
            tempId: _nextTempId++,
            tipo: s.tipo,
            contenido: s.contenido,
          ),
        ),
      );
      _isLoading = false;
    });
  }

  Future<void> _initForEdition() async {
    final arreglo =
        await ref.read(arregloDetailProvider(widget.arregloId!).future);
    final estrofas =
        await ref.read(arregloEstrofasProvider(widget.arregloId!).future);

    if (!mounted) return;

    if (arreglo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arreglo no encontrado.')),
      );
      return;
    }

    setState(() {
      _nameCtrl.text = arreglo.nombreArreglo;
      _tonalidadBase = arreglo.tonalidadBase;
      _versionPaisId = arreglo.versionPaisId;
      _currentVersion = arreglo.version;

      _estrofas.addAll(
        estrofas.map(
          (e) => _EditableStanza(
            tempId: _nextTempId++,
            tipo: e.tipo,
            contenido: e.contenido,
          ),
        ),
      );

      _isLoading = false;
    });
  }

  // ── Mutaciones de estrofas ──────────────────────────────────────────────

  void _updateTipo(int tempId, EstrofaTipo nuevoTipo) {
    final idx = _estrofas.indexWhere((e) => e.tempId == tempId);
    if (idx == -1) return;
    setState(() {
      _estrofas[idx].tipo = nuevoTipo;
      _isDirty = true;
    });
  }

  void _updateContenido(int tempId, String nuevoContenido) {
    final idx = _estrofas.indexWhere((e) => e.tempId == tempId);
    if (idx == -1) return;
    setState(() {
      _estrofas[idx].contenido = nuevoContenido;
      _isDirty = true;
    });
  }

  void _moveStanza(int tempId, int delta) {
    final idx = _estrofas.indexWhere((e) => e.tempId == tempId);
    if (idx == -1) return;
    final target = idx + delta;
    if (target < 0 || target >= _estrofas.length) return;
    setState(() {
      final item = _estrofas.removeAt(idx);
      _estrofas.insert(target, item);
      _isDirty = true;
    });
  }

  Future<void> _deleteStanza(int tempId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar estrofa'),
        content: const Text('¿Estás seguro de eliminar esta estrofa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _estrofas.removeWhere((e) => e.tempId == tempId);
      _isDirty = true;
    });
  }

  void _addEmptyStanza() {
    setState(() {
      _estrofas.add(
        _EditableStanza(
          tempId: _nextTempId++,
          tipo: EstrofaTipo.estrofa,
          contenido: '',
        ),
      );
      _isDirty = true;
    });
  }

  // ── Guardado ────────────────────────────────────────────────────────────

  Future<void> _saveArrangement() async {
    final nombre = _nameCtrl.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre para el arreglo')),
      );
      return;
    }

    if (_estrofas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos una estrofa')),
      );
      return;
    }

    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(arregloRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);

      if (_arregloId == null) {
        // ── Crear nuevo arreglo ─────────────────────────────────
        final arreglo = ArregloMusical(
          id: 0, // la BD asigna AUTOINCREMENT
          versionPaisId: _versionPaisId,
          usuarioId: userId,
          nombreArreglo: nombre,
          tonalidadBase: _tonalidadBase,
        );

        final estrofas = _estrofas.asMap().entries.map(
          (e) => EstrofaArreglo(
                id: 0, // la BD asigna AUTOINCREMENT
                arregloMusicalId: 0, // se asigna tras insertar el arreglo
                tipo: e.value.tipo,
                orden: e.key,
                contenido: e.value.contenido,
              ),
        ).toList();

        await repo.createArreglo(arreglo, estrofas);
      } else {
        // ── Actualizar arreglo existente ────────────────────────
        final arreglo = ArregloMusical(
          id: _arregloId!,
          versionPaisId: _versionPaisId,
          usuarioId: userId,
          nombreArreglo: nombre,
          tonalidadBase: _tonalidadBase,
          version: _currentVersion,
        );

        final estrofas = _estrofas.asMap().entries.map(
          (e) => EstrofaArreglo(
                id: 0, // el datasource reemplaza mediante delete+insert
                arregloMusicalId: _arregloId!,
                tipo: e.value.tipo,
                orden: e.key,
                contenido: e.value.contenido,
              ),
        ).toList();

        await repo.updateArreglo(arreglo, estrofas);
      }

      // Invalidar providers para que la UI refleje los cambios
      ref.invalidate(userArreglosProvider);
      if (_arregloId != null) {
        ref.invalidate(arregloDetailProvider(_arregloId!));
        ref.invalidate(arregloEstrofasProvider(_arregloId!));
      }

      // Marcar como no sucio para que el PopScope no pregunte al salir
      if (mounted) setState(() => _isDirty = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arreglo "$nombre" guardado exitosamente'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Diálogo de salida sin guardar ─────────────────────────────────────

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text(
          'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titulo = widget.himno?.titulo ?? 'Arreglo #$_arregloId';

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Arreglo: $titulo'),
          actions: [
            IconButton(
              icon: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              tooltip: 'Guardar',
              onPressed: _isSaving ? null : _saveArrangement,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildEditorBody(colorScheme),
      ),
    );
  }

  Widget _buildEditorBody(ColorScheme colorScheme) {
    return Column(
      children: [
        // ── Nombre del arreglo ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _nameCtrl,
            onChanged: (_) {
              if (!_isDirty) setState(() => _isDirty = true);
            },
            decoration: const InputDecoration(
              labelText: 'Nombre del arreglo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.music_note),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Lista de estrofas editables ────────────────────────
        Expanded(
          child: _estrofas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.library_music_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No hay estrofas',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Usa el botón inferior para añadir una',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _estrofas.length,
                  itemBuilder: (context, index) {
                    final e = _estrofas[index];
                    // IMPORTANTE: index y total se calculan con indexOf
                    // para que los botones de reordenar funcionen correctamente
                    // tras inserciones/eliminaciones.
                    final effectiveIndex = _estrofas.indexOf(e);
                    final total = _estrofas.length;

                    return StanzaBlockEditor(
                      index: effectiveIndex,
                      total: total,
                      tipo: e.tipo,
                      contenido: e.contenido,
                      onTipoChanged: (t) => _updateTipo(e.tempId, t),
                      onContenidoChanged: (c) => _updateContenido(e.tempId, c),
                      onMoveUp: effectiveIndex > 0
                          ? () => _moveStanza(e.tempId, -1)
                          : null,
                      onMoveDown: effectiveIndex < total - 1
                          ? () => _moveStanza(e.tempId, 1)
                          : null,
                      onDelete: () => _deleteStanza(e.tempId),
                    );
                  },
                ),
        ),

        // ── Botón "Añadir estrofa" ─────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addEmptyStanza,
              icon: const Icon(Icons.add),
              label: const Text('Añadir Estrofa'),
            ),
          ),
        ),
      ],
    );
  }
}
