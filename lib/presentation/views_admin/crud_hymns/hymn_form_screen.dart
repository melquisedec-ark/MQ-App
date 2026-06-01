import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/estrofa_tipo.dart';
import '../../../../core/enums/himno_tipo.dart';
import '../../../../core/errors/failures.dart';
import '../../../../data/models/pais_model.dart';
import '../../../../domain/entities/himno.dart';
import '../../../../domain/usecases/himno/create_hymn_usecase.dart';
import '../../../../domain/usecases/himno/update_hymn_usecase.dart';
import '../../views_admin/providers/admin_providers.dart' show getAllPaisesUseCaseProvider;
import '../../views_personal/providers/hymn_providers.dart';
import 'categoria_selector.dart';
import 'stanza_block_editor.dart';

/// Representación editable de una estrofa en el formulario.
class _StanzaDraft {
  EstrofaTipo tipo;
  String contenido;

  _StanzaDraft({required this.tipo, this.contenido = ''});
}

/// Pantalla de formulario para crear o editar un himno.
///
/// Si [himnoId] es `null`, opera en modo de creación.
/// Si [himnoId] no es `null`, carga el himno existente para edición.
class HymnFormScreen extends ConsumerStatefulWidget {
  final int? himnoId;

  const HymnFormScreen({super.key, this.himnoId});

  @override
  ConsumerState<HymnFormScreen> createState() => _HymnFormScreenState();
}

class _HymnFormScreenState extends ConsumerState<HymnFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _numeroController = TextEditingController();
  final _tonalidadController = TextEditingController(text: 'C');

  HimnoTipo _tipo = HimnoTipo.oficial;
  int? _selectedPaisId;
  List<PaisModel> _paises = [];
  List<int> _selectedCategoriaIds = [];
  List<_StanzaDraft> _estrofas = [];
  bool _saving = false;
  bool _loading = true;
  bool _paisesLoading = true;

  bool get _isEditing => widget.himnoId != null;

  @override
  void initState() {
    super.initState();
    _loadPaises();
    if (_isEditing) {
      _loadHymn();
    } else {
      // Empezar con una estrofa vacía
      _estrofas.add(_StanzaDraft(tipo: EstrofaTipo.estrofa));
      _loading = false;
    }
  }

  Future<void> _loadPaises() async {
    try {
      final paises = await ref.read(getAllPaisesUseCaseProvider).execute();
      if (mounted) {
        setState(() {
          _paises = paises;
          _paisesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _paisesLoading = false);
      }
    }
  }

  Future<void> _loadHymn() async {
    try {
      final repo = ref.read(hymnRepositoryProvider);
      final himno = await repo.getHymnById(widget.himnoId!);

      if (!mounted) return;

      _tituloController.text = himno.titulo;
      if (himno.numero != null) {
        _numeroController.text = himno.numero.toString();
      }
      _tipo = himno.tipo;

      // Cargar categorías
      _selectedCategoriaIds =
          himno.categorias?.map((c) => c.id).toList() ?? [];

      // Cargar país y tonalidad de la primera versión
      if (himno.versiones.isNotEmpty) {
        final version = himno.versiones.first;
        _selectedPaisId = version.paisId;
        _tonalidadController.text = version.tonalidadOriginal;

        // Cargar estrofas
        final stanzas = await repo.getStanzas(version.id);
        _estrofas = stanzas
            .map((s) => _StanzaDraft(tipo: s.tipo, contenido: s.contenido))
            .toList();
      }

      if (_estrofas.isEmpty) {
        _estrofas.add(_StanzaDraft(tipo: EstrofaTipo.estrofa));
      }

      setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar himno: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _numeroController.dispose();
    _tonalidadController.dispose();
    super.dispose();
  }

  void _addStanza() {
    setState(() {
      _estrofas.add(_StanzaDraft(tipo: EstrofaTipo.estrofa));
    });
  }

  void _removeStanza(int index) {
    setState(() {
      _estrofas.removeAt(index);
    });
  }

  void _moveStanza(int from, int to) {
    setState(() {
      final item = _estrofas.removeAt(from);
      _estrofas.insert(to, item);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoriaIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar al menos una categoría')),
      );
      return;
    }

    if (_estrofas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe agregar al menos una estrofa')),
      );
      return;
    }

    for (int i = 0; i < _estrofas.length; i++) {
      if (_estrofas[i].contenido.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('La estrofa ${i + 1} no puede estar vacía')),
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final himno = Himno(
        id: widget.himnoId ?? 0,
        titulo: _tituloController.text.trim(),
        numero: int.tryParse(_numeroController.text.trim()),
        tipo: _tipo,
        activo: true,
      );

      // Versión: usamos pais_id y tonalidad del formulario
      final versiones = <Map<String, dynamic>>[
        {
          'pais_id': _selectedPaisId,
          'tonalidad_original': _tonalidadController.text.trim().isEmpty
              ? 'C'
              : _tonalidadController.text.trim(),
        },
      ];

      // Estrofas con version_idx apuntando a la única versión (índice 0)
      final estrofas = _estrofas.asMap().entries.map((entry) {
        return <String, dynamic>{
          'tipo': entry.value.tipo.value,
          'orden': entry.key,
          'contenido': entry.value.contenido,
          'version_idx': 0,
        };
      }).toList();

      if (_isEditing) {
        // Modo edición
        final updateUseCase = ref.read(updateHymnUseCaseProvider);
        await updateUseCase.execute(
          himno,
          versiones,
          estrofas,
          _selectedCategoriaIds,
        );
      } else {
        // Modo creación
        final createUseCase = ref.read(createHymnUseCaseProvider);
        await createUseCase.execute(
          himno,
          versiones,
          estrofas,
          _selectedCategoriaIds,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? '"${himno.titulo}" actualizado'
                  : '"${himno.titulo}" creado',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } on Failure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = _isEditing ? 'Editar Himno' : 'Nuevo Himno';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Título ───────────────────────────────────────
            TextFormField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título del himno *',
                prefixIcon: Icon(Icons.title),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'El título es obligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Número ───────────────────────────────────────
            TextFormField(
              controller: _numeroController,
              decoration: const InputDecoration(
                labelText: 'Número oficial',
                prefixIcon: Icon(Icons.tag),
                hintText: 'Ej: 123',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // ── Tipo ─────────────────────────────────────────
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Tipo *',
                prefixIcon: Icon(Icons.category),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<HimnoTipo>(
                  value: _tipo,
                  isDense: true,
                  isExpanded: true,
                  items: HimnoTipo.values.map((t) {
                    return DropdownMenuItem(value: t, child: Text(t.label));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _tipo = v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── País ─────────────────────────────────────────
            if (_paisesLoading)
              const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              DropdownButtonFormField<int>(
                value: _selectedPaisId,
                decoration: const InputDecoration(
                  labelText: 'País',
                  prefixIcon: Icon(Icons.public),
                ),
                isExpanded: true,
                hint: const Text('Seleccionar país'),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('(Sin país)'),
                  ),
                  ..._paises.map((p) => DropdownMenuItem<int>(
                        value: p.id,
                        child: Text(p.nombre),
                      )),
                ],
                onChanged: (v) {
                  setState(() => _selectedPaisId = v);
                },
              ),
            const SizedBox(height: 16),

            // ── Tonalidad original ───────────────────────────
            TextFormField(
              controller: _tonalidadController,
              decoration: const InputDecoration(
                labelText: 'Tonalidad original',
                prefixIcon: Icon(Icons.music_note),
                hintText: 'Ej: C, G, D, Am',
              ),
            ),
            const SizedBox(height: 24),

            // ── Categorías ───────────────────────────────────
            CategoriaSelector(
              selectedIds: _selectedCategoriaIds,
              onSelectionChanged: (ids) {
                setState(() => _selectedCategoriaIds = ids);
              },
            ),
            const SizedBox(height: 24),

            // ── Estrofas ─────────────────────────────────────
            Row(
              children: [
                Text(
                  'Estrofas',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_estrofas.length})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar estrofa'),
                  onPressed: _addStanza,
                ),
              ],
            ),
            const SizedBox(height: 4),

            if (_estrofas.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No hay estrofas. Agrega al menos una.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _estrofas.length,
                onReorder: _moveStanza,
                buildDefaultDragHandles: false,
                proxyDecorator: (child, index, animation) {
                  return Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: child,
                  );
                },
                itemBuilder: (context, index) {
                  final stanza = _estrofas[index];
                  return StanzaBlockEditor(
                    key: ValueKey('stanza_$index'),
                    index: index,
                    total: _estrofas.length,
                    tipo: stanza.tipo,
                    contenido: stanza.contenido,
                    onTipoChanged: (tipo) {
                      setState(() => _estrofas[index].tipo = tipo);
                    },
                    onContenidoChanged: (contenido) {
                      setState(() => _estrofas[index].contenido = contenido);
                    },
                    onMoveUp: index > 0
                        ? () => _moveStanza(index, index - 1)
                        : null,
                    onMoveDown: index < _estrofas.length - 1
                        ? () => _moveStanza(index, index + 1)
                        : null,
                    onDelete: () => _removeStanza(index),
                  );
                },
              ),

            const SizedBox(height: 24),

            // ── Botón guardar ────────────────────────────────
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _saving
                      ? 'Guardando...'
                      : (_isEditing ? 'Actualizar himno' : 'Crear himno'),
                ),
                onPressed: _saving ? null : _save,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
