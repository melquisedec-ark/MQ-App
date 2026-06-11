import 'package:equatable/equatable.dart';

/// Entidad de dominio que representa un país.
class Pais extends Equatable {
  final int id;
  final String nombre;
  final String? codigo;

  const Pais({
    required this.id,
    required this.nombre,
    this.codigo,
  });

  @override
  List<Object?> get props => [id, nombre, codigo];
}
