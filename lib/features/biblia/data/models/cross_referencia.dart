import 'package:equatable/equatable.dart';

/// Cross-reference bíblica: una referencia FROM → TO entre versículos
/// (o rangos) de la Biblia.
///
/// Mapea fila por fila con la tabla `cross_referencia` del schema
/// de Biblia (ver `assets/db/schema/004_cross_referencias.sql`).
///
/// ## Decisiones de diseño
///
/// 1. **Sin FK a `versiculo.id`**: igual que `Nota` y `FavoritoVersiculo`,
///    la referencia es "lógica" — apunta a un (libro, capítulo, versículo)
///    que puede o no existir materialmente en `versiculo`. Esto permite:
///      * refs cross-versión (referenciar Juan 3:16 usando la version RV1909
///        cuando ese versículo aún no se ha cargado en otra versión).
///      * robustez ante re-versificación: si el dataset openbible
///        referencia Apocalipsis 22:21 pero la versión local no lo tiene,
///        la ref no rompe la BD (simplemente no muestra preview).
///
/// 2. **Soporte de rangos en el destino**: el dataset openbible incluye
///    referencias a rangos, ej. `1John.4.9-10` (versículos 9 al 10).
///    El destino se modela con dos campos: `to_versiculo_inicio` y
///    `to_versiculo_fin`. Si el destino es un versículo único, ambos
///    campos son iguales (ver [esRango]).
///
/// 3. **`votos` (default 1)**: refleja la "fuerza" de la referencia
///    en el dataset openbible (cuántos usuarios la marcaron). Se usa
///    para ordenar las refs más relevantes primero en la UI.
///
/// ## Uso
///
/// ```dart
/// final refs = await repo.getByFromVerse(
///   versionId: 1, libroId: 43, capitulo: 3, versiculo: 16,
/// );
/// for (final r in refs) {
///   // Juan 3:16 → Génesis 22:12 (3 votos)
/// }
/// ```
class CrossReferencia extends Equatable {
  /// Identificador único (PK en `cross_referencia.id`).
  final int id;

  /// FK a `version.id`. La ref pertenece a una sola versión.
  final int versionId;

  /// FK a `libro.id` (origen). Validada por trigger.
  final int fromLibroId;

  /// Número de capítulo de origen (>= 1). No FK porque la ref puede
  /// apuntar a un versículo aún no sembrado en `versiculo`.
  final int fromCapitulo;

  /// Número de versículo de origen (>= 1).
  final int fromVersiculo;

  /// FK a `libro.id` (destino). Validada por trigger.
  final int toLibroId;

  /// Número de capítulo de destino (>= 1).
  final int toCapitulo;

  /// Versículo inicial del rango de destino (>= 1). Si el destino es
  /// un versículo único, este campo es igual a [toVersiculoFin].
  final int toVersiculoInicio;

  /// Versículo final del rango de destino (>= [toVersiculoInicio]).
  final int toVersiculoFin;

  /// Peso / votos de la referencia. Default 1 en el schema.
  /// Refs con más votos son las más "valiosas" según el dataset openbible.
  final int votos;

  const CrossReferencia({
    required this.id,
    required this.versionId,
    required this.fromLibroId,
    required this.fromCapitulo,
    required this.fromVersiculo,
    required this.toLibroId,
    required this.toCapitulo,
    required this.toVersiculoInicio,
    required this.toVersiculoFin,
    required this.votos,
  });

  /// `true` si la referencia apunta a un rango de versículos
  /// (no un versículo único).
  ///
  /// Útil para la UI: una ref de rango podría mostrarse como
  /// "Génesis 22:12-14" en lugar de "Génesis 22:12".
  bool get esRango => toVersiculoInicio != toVersiculoFin;

  /// Construye desde una fila de SQLite (claves en snake_case).
  factory CrossReferencia.fromMap(Map<String, dynamic> map) {
    return CrossReferencia(
      id: map['id'] as int,
      versionId: map['version_id'] as int,
      fromLibroId: map['from_libro_id'] as int,
      fromCapitulo: map['from_capitulo'] as int,
      fromVersiculo: map['from_versiculo'] as int,
      toLibroId: map['to_libro_id'] as int,
      toCapitulo: map['to_capitulo'] as int,
      toVersiculoInicio: map['to_versiculo_inicio'] as int,
      toVersiculoFin: map['to_versiculo_fin'] as int,
      votos: (map['votos'] as int?) ?? 1,
    );
  }

  /// Serializa a un mapa listo para `db.insert` o `db.update`.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'version_id': versionId,
      'from_libro_id': fromLibroId,
      'from_capitulo': fromCapitulo,
      'from_versiculo': fromVersiculo,
      'to_libro_id': toLibroId,
      'to_capitulo': toCapitulo,
      'to_versiculo_inicio': toVersiculoInicio,
      'to_versiculo_fin': toVersiculoFin,
      'votos': votos,
    };
  }

  /// Crea una copia con campos reemplazados. Inmutable por convención.
  ///
  /// Nota: solo se permite actualizar `votos` porque es el único campo
  /// que puede cambiar en runtime (futuro: el usuario puede votar
  /// una ref hacia arriba/abajo).
  CrossReferencia copyWith({int? votos}) {
    return CrossReferencia(
      id: id,
      versionId: versionId,
      fromLibroId: fromLibroId,
      fromCapitulo: fromCapitulo,
      fromVersiculo: fromVersiculo,
      toLibroId: toLibroId,
      toCapitulo: toCapitulo,
      toVersiculoInicio: toVersiculoInicio,
      toVersiculoFin: toVersiculoFin,
      votos: votos ?? this.votos,
    );
  }

  @override
  List<Object?> get props => [
        id,
        versionId,
        fromLibroId,
        fromCapitulo,
        fromVersiculo,
        toLibroId,
        toCapitulo,
        toVersiculoInicio,
        toVersiculoFin,
        votos,
      ];
}

/// Cross-reference con texto preview del versículo destino.
///
/// Se obtiene mediante una query con LEFT JOIN a la tabla `versiculo`.
/// Si el versículo destino no existe en la BD (caso raro), `previewTexto`
/// será null y la UI no mostrará snippet. El texto se guarda completo;
/// la UI decide si truncarlo o no según el contexto.
class CrossReferenciaConPreview extends CrossReferencia {
  /// Texto completo del versículo destino (o null si no existe en la BD).
  final String? previewTexto;

  const CrossReferenciaConPreview({
    required super.id,
    required super.versionId,
    required super.fromLibroId,
    required super.fromCapitulo,
    required super.fromVersiculo,
    required super.toLibroId,
    required super.toCapitulo,
    required super.toVersiculoInicio,
    required super.toVersiculoFin,
    required super.votos,
    this.previewTexto,
  });

  /// Construye desde una fila de SQLite con `preview_texto` opcional.
  /// El texto se guarda completo (sin truncar).
  factory CrossReferenciaConPreview.fromMap(Map<String, dynamic> map) {
    final preview = map['preview_texto'] as String?;
    return CrossReferenciaConPreview(
      id: map['id'] as int,
      versionId: map['version_id'] as int,
      fromLibroId: map['from_libro_id'] as int,
      fromCapitulo: map['from_capitulo'] as int,
      fromVersiculo: map['from_versiculo'] as int,
      toLibroId: map['to_libro_id'] as int,
      toCapitulo: map['to_capitulo'] as int,
      toVersiculoInicio: map['to_versiculo_inicio'] as int,
      toVersiculoFin: map['to_versiculo_fin'] as int,
      votos: (map['votos'] as int?) ?? 1,
      previewTexto: preview,
    );
  }

  @override
  List<Object?> get props => [
        ...super.props,
        previewTexto,
      ];
}
