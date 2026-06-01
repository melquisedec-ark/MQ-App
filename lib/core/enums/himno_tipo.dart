/// Tipo de himno según su clasificación eclesiástica.
enum HimnoTipo {
  oficial(1, 'Oficial'),
  inspirada(2, 'Inspirada'),
  convencion(3, 'Convención');

  final int value;
  final String label;

  const HimnoTipo(this.value, this.label);

  static HimnoTipo fromValue(int value) {
    return HimnoTipo.values.firstWhere(
      (tipo) => tipo.value == value,
      orElse: () => HimnoTipo.oficial,
    );
  }
}
