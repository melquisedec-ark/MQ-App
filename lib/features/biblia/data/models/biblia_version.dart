import 'package:equatable/equatable.dart';

/// Versión bíblica (RV1909, RV1569, futuras).
///
/// Mapea fila por fila con la tabla `version` del schema de Biblia.
/// Decisión arquitectónica #2: una fila por versión soportada.
class BibliaVersion extends Equatable {
  /// Identificador único (PK en `version.id`).
  final int id;

  /// Nombre legible. Ej: "Reina Valera 1909".
  final String nombre;

  /// Abreviatura única. Ej: "RVR1909".
  /// Es UNIQUE en la BD; se usa para resolver versiones por abreviatura.
  final String abreviatura;

  /// Código de idioma ISO 639-1. Ej: "es".
  final String idioma;

  /// Descripción libre (puede ser null).
  final String? descripcion;

  /// Año de publicación. Ej: 1909, 1569. Puede ser null.
  final int? anioPublicacion;

  /// `true` si es de dominio público. Controla qué versiones se pueden
  /// distribuir libremente (todas las RV lo son).
  final bool esDominioPublico;

  /// `true` si la versión está activa y debe aparecer en selectores de UI.
  final bool activa;

  const BibliaVersion({
    required this.id,
    required this.nombre,
    required this.abreviatura,
    required this.idioma,
    this.descripcion,
    this.anioPublicacion,
    this.esDominioPublico = true,
    this.activa = true,
  });

  /// Construye desde una fila de SQLite (claves en snake_case).
  factory BibliaVersion.fromMap(Map<String, dynamic> map) {
    return BibliaVersion(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      abreviatura: map['abreviatura'] as String,
      idioma: map['idioma'] as String,
      descripcion: map['descripcion'] as String?,
      anioPublicacion: map['anio_publicacion'] as int?,
      esDominioPublico: (map['es_dominio_publico'] as int? ?? 1) == 1,
      activa: (map['activa'] as int? ?? 1) == 1,
    );
  }

  /// Serializa a un mapa listo para `db.insert`.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'abreviatura': abreviatura,
      'idioma': idioma,
      'descripcion': descripcion,
      'anio_publicacion': anioPublicacion,
      'es_dominio_publico': esDominioPublico ? 1 : 0,
      'activa': activa ? 1 : 0,
    };
  }

  /// Crea una copia con campos reemplazados. Inmutable por convención.
  BibliaVersion copyWith({
    int? id,
    String? nombre,
    String? abreviatura,
    String? idioma,
    String? descripcion,
    int? anioPublicacion,
    bool? esDominioPublico,
    bool? activa,
  }) {
    return BibliaVersion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      abreviatura: abreviatura ?? this.abreviatura,
      idioma: idioma ?? this.idioma,
      descripcion: descripcion ?? this.descripcion,
      anioPublicacion: anioPublicacion ?? this.anioPublicacion,
      esDominioPublico: esDominioPublico ?? this.esDominioPublico,
      activa: activa ?? this.activa,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        abreviatura,
        idioma,
        descripcion,
        anioPublicacion,
        esDominioPublico,
        activa,
      ];
}
