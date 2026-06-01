import 'package:equatable/equatable.dart';

/// Enumeración canónica del testamento. Coincide con el CHECK constraint
/// de la columna `libro.testamento` (AT | NT).
enum Testamento { at, nt }

extension TestamentoX on Testamento {
  /// String usado en SQL.
  String get value {
    switch (this) {
      case Testamento.at:
        return 'AT';
      case Testamento.nt:
        return 'NT';
    }
  }

  /// Etiqueta en español para mostrar en la UI.
  String get label {
    switch (this) {
      case Testamento.at:
        return 'Antiguo Testamento';
      case Testamento.nt:
        return 'Nuevo Testamento';
    }
  }

  /// Convierte el string de SQLite a enum. Tolera mayúsculas.
  static Testamento? fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'AT':
        return Testamento.at;
      case 'NT':
        return Testamento.nt;
      default:
        return null;
    }
  }
}

/// Uno de los 66 libros canónicos de la Biblia.
///
/// `numero` sigue el orden canónico estándar:
///   AT: 1..46  (Génesis = 1, Malaquías = 39)
///   NT: 47..66 (Mateo = 40, Apocalipsis = 66)
///
/// `totalCapitulos` se desnormaliza para evitar `COUNT(*)` en la UI.
class Libro extends Equatable {
  /// Identificador único (PK en `libro.id`).
  final int id;

  /// FK a `version.id`. Cada libro pertenece a una sola versión.
  final int versionId;

  /// Nombre del libro. Ej: "Génesis", "1 Juan".
  final String nombre;

  /// Abreviatura canónica. Ej: "Gn", "Ex", "1Jn".
  final String abreviatura;

  /// Antiguo o Nuevo Testamento. Coincide con el CHECK en la BD.
  final Testamento testamento;

  /// Número canónico (1-66). Único por versión (`UNIQUE(version_id, numero)`).
  final int numero;

  /// Cantidad de capítulos. Se desnormaliza para evitar COUNT en UI.
  final int totalCapitulos;

  const Libro({
    required this.id,
    required this.versionId,
    required this.nombre,
    required this.abreviatura,
    required this.testamento,
    required this.numero,
    required this.totalCapitulos,
  });

  /// Construye desde una fila de SQLite.
  factory Libro.fromMap(Map<String, dynamic> map) {
    final testamentoStr = map['testamento'] as String;
    final testamentoEnum = TestamentoX.fromString(testamentoStr);
    if (testamentoEnum == null) {
      throw FormatException(
        'Libro.fromMap: testamento inválido "$testamentoStr" '
        '(se esperaba AT o NT)',
      );
    }
    return Libro(
      id: map['id'] as int,
      versionId: map['version_id'] as int,
      nombre: map['nombre'] as String,
      abreviatura: map['abreviatura'] as String,
      testamento: testamentoEnum,
      numero: map['numero'] as int,
      totalCapitulos: map['total_capitulos'] as int,
    );
  }

  /// Serializa a un mapa listo para `db.insert`.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'version_id': versionId,
      'nombre': nombre,
      'abreviatura': abreviatura,
      'testamento': testamento.value,
      'numero': numero,
      'total_capitulos': totalCapitulos,
    };
  }

  /// Crea una copia con campos reemplazados. Inmutable por convención.
  Libro copyWith({
    int? id,
    int? versionId,
    String? nombre,
    String? abreviatura,
    Testamento? testamento,
    int? numero,
    int? totalCapitulos,
  }) {
    return Libro(
      id: id ?? this.id,
      versionId: versionId ?? this.versionId,
      nombre: nombre ?? this.nombre,
      abreviatura: abreviatura ?? this.abreviatura,
      testamento: testamento ?? this.testamento,
      numero: numero ?? this.numero,
      totalCapitulos: totalCapitulos ?? this.totalCapitulos,
    );
  }

  @override
  List<Object?> get props => [
        id,
        versionId,
        nombre,
        abreviatura,
        testamento,
        numero,
        totalCapitulos,
      ];
}
