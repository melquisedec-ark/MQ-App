import 'package:equatable/equatable.dart';

/// Versículo bíblico. La unidad más pequeña del texto sagrado.
///
/// ~31 102 versículos por versión × 2 versiones = ~62 204 filas totales.
/// La columna `texto` es la única columna "pesada" de la BD.
class Versiculo extends Equatable {
  /// Identificador único (PK en `versiculo.id`).
  final int id;

  /// FK a `capitulo.id`.
  final int capituloId;

  /// Número del versículo dentro del capítulo (>= 1).
  final int numero;

  /// Texto bíblico completo. UTF-8, ~250 bytes promedio por versículo.
  final String texto;

  const Versiculo({
    required this.id,
    required this.capituloId,
    required this.numero,
    required this.texto,
  });

  /// Construye desde una fila de SQLite.
  factory Versiculo.fromMap(Map<String, dynamic> map) {
    return Versiculo(
      id: map['id'] as int,
      capituloId: map['capitulo_id'] as int,
      numero: map['numero'] as int,
      texto: map['texto'] as String,
    );
  }

  /// Serializa a un mapa listo para `db.insert`.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'capitulo_id': capituloId,
      'numero': numero,
      'texto': texto,
    };
  }

  /// Crea una copia con campos reemplazados. Inmutable por convención.
  Versiculo copyWith({
    int? id,
    int? capituloId,
    int? numero,
    String? texto,
  }) {
    return Versiculo(
      id: id ?? this.id,
      capituloId: capituloId ?? this.capituloId,
      numero: numero ?? this.numero,
      texto: texto ?? this.texto,
    );
  }

  @override
  List<Object?> get props => [id, capituloId, numero, texto];
}
