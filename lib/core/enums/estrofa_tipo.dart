/// Tipo de estrofa dentro de un himno.
enum EstrofaTipo {
  coro('Coro'),
  estrofa('Estrofa'),
  puente('Puente'),
  intro('Intro'),
  final_('Final');

  final String value;

  const EstrofaTipo(this.value);

  static EstrofaTipo fromValue(String value) {
    return EstrofaTipo.values.firstWhere(
      (tipo) => tipo.value == value,
      orElse: () => EstrofaTipo.estrofa,
    );
  }
}
