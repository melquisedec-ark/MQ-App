/// Tipos de fondo de pantalla disponibles en el sistema.
enum FondoPantallaTipo {
  imagen('imagen'),
  colorSolido('color_solido');

  final String value;
  const FondoPantallaTipo(this.value);

  static FondoPantallaTipo fromValue(String value) {
    return FondoPantallaTipo.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FondoPantallaTipo.imagen,
    );
  }
}
