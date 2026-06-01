import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/usuario_rol.dart';
import '../../../domain/entities/usuario.dart';
import '../../views_admin/providers/admin_providers.dart'
    show
        getAllUsuariosUseCaseProvider,
        createUsuarioUseCaseProvider,
        updateUsuarioUseCaseProvider,
        deleteUsuarioUseCaseProvider;

// ─────────────────────────────────────────────────────────────
// Provider local: lista de usuarios
// ─────────────────────────────────────────────────────────────

final _usuariosProvider = FutureProvider.autoDispose<List<Usuario>>((ref) {
  return ref.watch(getAllUsuariosUseCaseProvider).execute();
});

// ─────────────────────────────────────────────────────────────

/// Tab de administración de usuarios.
///
/// CRUD completo: crear, editar, listar y eliminar usuarios del sistema.
/// Cada usuario tiene: username (obligatorio), password (obligatorio al crear,
/// opcional al editar), nombre completo (obligatorio) y rol (Admin, Músico,
/// Visualizador).
class UsuarioTab extends ConsumerStatefulWidget {
  const UsuarioTab({super.key});

  @override
  ConsumerState<UsuarioTab> createState() => _UsuarioTabState();
}

class _UsuarioTabState extends ConsumerState<UsuarioTab> {
  // ── Formulario ─────────────────────────────────────────────
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();

  // Modo edición
  Usuario? _editando;

  // Rol seleccionado (valor por defecto: Músico)
  UsuarioRol _selectedRol = UsuarioRol.musico;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _usernameController.clear();
      _passwordController.clear();
      _nombreController.clear();
      _selectedRol = UsuarioRol.musico;
      _editando = null;
    });
  }

  void _cargarEnFormulario(Usuario usuario) {
    setState(() {
      _editando = usuario;
      _usernameController.text = usuario.username;
      _nombreController.text = usuario.nombre;
      _passwordController.clear();
      _selectedRol = usuario.rol;
    });
  }

  // ── Guardar (crear / actualizar) ──────────────────────────

  Future<void> _guardar() async {
    final username = _usernameController.text.trim();
    final nombre = _nombreController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los campos usuario y nombre son obligatorios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_editando == null && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña es obligatoria para nuevos usuarios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (_editando != null) {
        // ── Actualizar ────────────────────────────────────
        // Si la contraseña está vacía, conservar la existente
        final passwordHash = password.isEmpty
            ? _editando!.passwordHash
            : password;
        await ref.read(updateUsuarioUseCaseProvider).execute(
              Usuario(
                id: _editando!.id,
                username: username,
                passwordHash: passwordHash,
                nombre: nombre,
                rol: _selectedRol,
              ),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Usuario "$nombre" actualizado')),
          );
        }
      } else {
        // ── Crear ─────────────────────────────────────────
        await ref.read(createUsuarioUseCaseProvider).execute(
              username: username,
              passwordHash: password,
              nombre: nombre,
              rol: _selectedRol,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Usuario "$nombre" creado')),
          );
        }
      }
      _resetForm();
      ref.invalidate(_usuariosProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Eliminar con confirmación ────────────────────────────

  Future<void> _eliminarUsuario(Usuario usuario) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Eliminar usuario "${usuario.nombre}"?\n\n'
          'Los arreglos musicales asociados a este usuario se perderán.',
        ),
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
      await ref.read(deleteUsuarioUseCaseProvider).execute(usuario.id);
      if (_editando?.id == usuario.id) _resetForm();
      ref.invalidate(_usuariosProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuario "${usuario.nombre}" eliminado')),
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

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Formulario ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editando != null ? 'Editar usuario' : 'Nuevo usuario',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  hintText: 'Nombre de usuario',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  hintText: 'Nombre del usuario',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: _editando != null
                      ? 'Nueva contraseña (opcional)'
                      : 'Contraseña',
                  hintText: _editando != null
                      ? 'Dejar vacío para mantener'
                      : 'Contraseña',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UsuarioRol>(
                key: ValueKey(_selectedRol),
                initialValue: _selectedRol,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  isDense: true,
                ),
                items: [
                  for (final rol in UsuarioRol.values)
                    DropdownMenuItem(
                      value: rol,
                      child: Text(rol.value),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedRol = v);
                },
              ),
              const SizedBox(height: 12),
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

        // ── Lista de usuarios ───────────────────────────────────
        Expanded(
          child: ref.watch(_usuariosProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (usuarios) {
              if (usuarios.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay usuarios registrados',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea el primer usuario usando el formulario de arriba.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: usuarios.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final usuario = usuarios[index];
                  final isAdmin = usuario.rol == UsuarioRol.admin;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAdmin
                          ? theme.colorScheme.errorContainer
                          : usuario.rol == UsuarioRol.musico
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        isAdmin
                            ? Icons.shield
                            : usuario.rol == UsuarioRol.musico
                                ? Icons.music_note
                                : Icons.visibility,
                        color: isAdmin
                            ? theme.colorScheme.onErrorContainer
                            : usuario.rol == UsuarioRol.musico
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    title: Text(usuario.nombre),
                    subtitle: Row(
                      children: [
                        Text('@${usuario.username}'),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? theme.colorScheme.errorContainer
                                    .withValues(alpha: 0.5)
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            usuario.rol.value,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isAdmin
                                  ? theme.colorScheme.onErrorContainer
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar',
                          onPressed: () => _cargarEnFormulario(usuario),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          tooltip: 'Eliminar',
                          onPressed: () => _eliminarUsuario(usuario),
                        ),
                      ],
                    ),
                    onTap: () => _cargarEnFormulario(usuario),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
