import 'package:equatable/equatable.dart';

/// Colores permitidos para notas. Coincide con el CHECK constraint de
/// `nota.color` (ver `001_biblia_schema.sql`).
///
/// Decisión arquitectónica #9: notas 1-por-versículo con color
/// semaforizado (GTD-style). El color es una categoría lightweight, no
/// una etiqueta jerárquica.
enum NotaColor { amarillo, verde, azul, ninguno }

extension NotaColorX on NotaColor {
  /// String usado en SQL.
  String get value {
    switch (this) {
      case NotaColor.amarillo:
        return 'amarillo';
      case NotaColor.verde:
        return 'verde';
      case NotaColor.azul:
        return 'azul';
      case NotaColor.ninguno:
        return 'ninguno';
    }
  }

  /// Convierte el string de SQLite a enum. Tolera minúsculas.
  static NotaColor? fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'amarillo':
        return NotaColor.amarillo;
      case 'verde':
        return NotaColor.verde;
      case 'azul':
        return NotaColor.azul;
      case 'ninguno':
        return NotaColor.ninguno;
      default:
        return null;
    }
  }
}

/// Nota personal del usuario sobre un versículo.
///
/// Decisión arquitectónica #9: 1 nota por versículo, con color
/// semaforizado. Constraint `UNIQUE(version_id, libro_id, capitulo,
/// numero)` lo garantiza.
class Nota extends Equatable {
  /// Identificador único (PK en `nota.id`).
  final int id;

  /// FK a `version.id`.
  final int versionId;

  /// FK a `libro.id`. Validado por trigger.
  final int libroId;

  /// Número de capítulo (>= 1).
  final int capitulo;

  /// Número de versículo dentro del capítulo (>= 1).
  final int numero;

  /// Contenido de la nota (texto libre, UTF-8).
  final String contenido;

  /// Color semaforizado. Validado por el CHECK en la BD.
  final NotaColor color;

  /// Timestamp de creación (unix seconds).
  final DateTime fechaCreacion;

  /// Timestamp de última modificación (unix seconds).
  final DateTime fechaModificacion;

  const Nota({
    required this.id,
    required this.versionId,
    required this.libroId,
    required this.capitulo,
    required this.numero,
    required this.contenido,
    required this.color,
    required this.fechaCreacion,
    required this.fechaModificacion,
  });

  /// Construye desde una fila de SQLite.
  factory Nota.fromMap(Map<String, dynamic> map) {
    final colorStr = map['color'] as String;
    final colorEnum = NotaColorX.fromString(colorStr);
    if (colorEnum == null) {
      throw FormatException(
        'Nota.fromMap: color inválido "$colorStr"',
      );
    }
    return Nota(
      id: map['id'] as int,
      versionId: map['version_id'] as int,
      libroId: map['libro_id'] as int,
      capitulo: map['capitulo'] as int,
      numero: map['numero'] as int,
      contenido: map['contenido'] as String,
      color: colorEnum,
      fechaCreacion: DateTime.fromMillisecondsSinceEpoch(
        (map['fecha_creacion'] as int) * 1000,
        isUtc: true,
      ),
      fechaModificacion: DateTime.fromMillisecondsSinceEpoch(
        (map['fecha_modificacion'] as int) * 1000,
        isUtc: true,
      ),
    );
  }

  /// Serializa a un mapa listo para `db.insert` o `db.update`.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'version_id': versionId,
      'libro_id': libroId,
      'capitulo': capitulo,
      'numero': numero,
      'contenido': contenido,
      'color': color.value,
      'fecha_creacion': fechaCreacion.toUtc().millisecondsSinceEpoch ~/ 1000,
      'fecha_modificacion':
          fechaModificacion.toUtc().millisecondsSinceEpoch ~/ 1000,
    };
  }

  /// Crea una copia con campos reemplazados. Inmutable por convención.
  Nota copyWith({
    int? id,
    int? versionId,
    int? libroId,
    int? capitulo,
    int? numero,
    String? contenido,
    NotaColor? color,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
  }) {
    return Nota(
      id: id ?? this.id,
      versionId: versionId ?? this.versionId,
      libroId: libroId ?? this.libroId,
      capitulo: capitulo ?? this.capitulo,
      numero: numero ?? this.numero,
      contenido: contenido ?? this.contenido,
      color: color ?? this.color,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: fechaModificacion ?? this.fechaModificacion,
    );
  }

  @override
  List<Object?> get props => [
        id,
        versionId,
        libroId,
        capitulo,
        numero,
        contenido,
        color,
        fechaCreacion,
        fechaModificacion,
      ];
}
