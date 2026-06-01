import 'package:equatable/equatable.dart';

/// Versículo marcado como favorito por el usuario.
///
/// Constraint `UNIQUE(version_id, libro_id, capitulo, numero)` garantiza
/// que un versículo solo se marca una vez por versión. Los triggers
/// `favorito_versiculo_bi/bu` validan que `libro_id` pertenezca a la
/// `version_id` declarada (ver `001_biblia_schema.sql`).
class FavoritoVersiculo extends Equatable {
  /// Identificador único (PK en `favorito_versiculo.id`).
  final int id;

  /// FK a `version.id`.
  final int versionId;

  /// FK a `libro.id`. Validado por trigger.
  final int libroId;

  /// Número de capítulo (>= 1). No FK porque puede ser "fantasma" si
  /// la versión se re-versifica (decisión documentada en
  /// `assets/db/schema/README.md`).
  final int capitulo;

  /// Número de versículo dentro del capítulo (>= 1).
  final int numero;

  /// Timestamp (unix seconds) en que se agregó el favorito.
  final DateTime fechaAgregado;

  const FavoritoVersiculo({
    required this.id,
    required this.versionId,
    required this.libroId,
    required this.capitulo,
    required this.numero,
    required this.fechaAgregado,
  });

  /// Construye desde una fila de SQLite.
  factory FavoritoVersiculo.fromMap(Map<String, dynamic> map) {
    return FavoritoVersiculo(
      id: map['id'] as int,
      versionId: map['version_id'] as int,
      libroId: map['libro_id'] as int,
      capitulo: map['capitulo'] as int,
      numero: map['numero'] as int,
      fechaAgregado: DateTime.fromMillisecondsSinceEpoch(
        (map['fecha_agregado'] as int) * 1000,
        isUtc: true,
      ),
    );
  }

  /// Serializa a un mapa listo para `db.insert`.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'version_id': versionId,
      'libro_id': libroId,
      'capitulo': capitulo,
      'numero': numero,
      'fecha_agregado': fechaAgregado.toUtc().millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Crea una copia con campos reemplazados. Inmutable por convención.
  FavoritoVersiculo copyWith({
    int? id,
    int? versionId,
    int? libroId,
    int? capitulo,
    int? numero,
    DateTime? fechaAgregado,
  }) {
    return FavoritoVersiculo(
      id: id ?? this.id,
      versionId: versionId ?? this.versionId,
      libroId: libroId ?? this.libroId,
      capitulo: capitulo ?? this.capitulo,
      numero: numero ?? this.numero,
      fechaAgregado: fechaAgregado ?? this.fechaAgregado,
    );
  }

  @override
  List<Object?> get props => [
        id,
        versionId,
        libroId,
        capitulo,
        numero,
        fechaAgregado,
      ];
}
