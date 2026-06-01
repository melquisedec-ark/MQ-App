import 'package:equatable/equatable.dart';

/// Item del historial de lectura con datos pre-joined para mostrar en UI.
///
/// Esta es una vista materializada en el repositorio (no una tabla): se
/// construye con un JOIN entre `historial_versiculo`, `libro` y
/// `versiculo` para no obligar a la UI a hacer N+1 queries cuando
/// muestra una lista cronológica.
class HistorialItem extends Equatable {
  /// Identificador único del item de historial (PK en `historial_versiculo.id`).
  final int id;

  /// FK a `version.id`.
  final int versionId;

  /// FK a `libro.id`.
  final int libroId;

  /// Nombre del libro (join con `libro.nombre`).
  final String libroNombre;

  /// Abreviatura del libro (join con `libro.abreviatura`).
  final String libroAbreviatura;

  /// Número de capítulo.
  final int capitulo;

  /// Número de versículo.
  final int numero;

  /// Texto del versículo leído (join con `versiculo.texto`).
  /// Puede ser `null` si el versículo fue eliminado (versión re-versificada).
  final String? texto;

  /// Timestamp (unix seconds) en que se leyó el versículo.
  final DateTime fechaLectura;

  const HistorialItem({
    required this.id,
    required this.versionId,
    required this.libroId,
    required this.libroNombre,
    required this.libroAbreviatura,
    required this.capitulo,
    required this.numero,
    required this.texto,
    required this.fechaLectura,
  });

  /// Construye desde una fila de SQLite con datos ya joined.
  ///
  /// Se espera que el repositorio provea los nombres de columna en
  /// snake_case y `libro_nombre`/`libro_abreviatura`/`texto` (los alias
  /// del JOIN). Se tolera `texto` null por si el versículo fue eliminado.
  factory HistorialItem.fromJoinedMap(Map<String, dynamic> map) {
    return HistorialItem(
      id: map['id'] as int,
      versionId: map['version_id'] as int,
      libroId: map['libro_id'] as int,
      libroNombre: map['libro_nombre'] as String,
      libroAbreviatura: map['libro_abreviatura'] as String,
      capitulo: map['capitulo'] as int,
      numero: map['numero'] as int,
      texto: map['texto'] as String?,
      fechaLectura: DateTime.fromMillisecondsSinceEpoch(
        (map['fecha_lectura'] as int) * 1000,
        isUtc: true,
      ),
    );
  }

  /// Etiqueta corta para mostrar en listas. Ej: "Juan 3:16".
  String get referencia => '$libroAbreviatura $capitulo:$numero';

  @override
  List<Object?> get props => [
        id,
        versionId,
        libroId,
        libroNombre,
        libroAbreviatura,
        capitulo,
        numero,
        texto,
        fechaLectura,
      ];
}
