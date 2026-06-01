import 'package:equatable/equatable.dart';

/// Capítulo bíblico. Ej: "Juan 3".
///
/// `totalVersiculos` se desnormaliza para mostrar
/// "Salmos 119:176 vers." sin un `COUNT(*)` adicional.
class Capitulo extends Equatable {
  /// Identificador único (PK en `capitulo.id`).
  final int id;

  /// FK a `libro.id`. Cada capítulo pertenece a un único libro.
  final int libroId;

  /// Número del capítulo dentro del libro (>= 1).
  final int numero;

  /// Cantidad de versículos en el capítulo. Se desnormaliza para
  /// evitar COUNT en la UI.
  final int totalVersiculos;

  const Capitulo({
    required this.id,
    required this.libroId,
    required this.numero,
    required this.totalVersiculos,
  });

  /// Construye desde una fila de SQLite.
  factory Capitulo.fromMap(Map<String, dynamic> map) {
    return Capitulo(
      id: map['id'] as int,
      libroId: map['libro_id'] as int,
      numero: map['numero'] as int,
      totalVersiculos: map['total_versiculos'] as int,
    );
  }

  /// Serializa a un mapa listo para `db.insert`.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'libro_id': libroId,
      'numero': numero,
      'total_versiculos': totalVersiculos,
    };
  }

  /// Crea una copia con campos reemplazados. Inmutable por convención.
  Capitulo copyWith({
    int? id,
    int? libroId,
    int? numero,
    int? totalVersiculos,
  }) {
    return Capitulo(
      id: id ?? this.id,
      libroId: libroId ?? this.libroId,
      numero: numero ?? this.numero,
      totalVersiculos: totalVersiculos ?? this.totalVersiculos,
    );
  }

  @override
  List<Object?> get props => [id, libroId, numero, totalVersiculos];
}
