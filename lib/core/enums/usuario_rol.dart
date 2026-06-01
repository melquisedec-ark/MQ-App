/// Roles de usuario dentro del sistema de arreglos musicales.
enum UsuarioRol {
  admin('Admin', 'Administrador del sistema'),
  musico('Musico', 'Puede crear y editar arreglos'),
  visualizador('Visualizador', 'Solo puede visualizar himnos');

  final String value;
  final String description;

  const UsuarioRol(this.value, this.description);
}
