import 'package:equatable/equatable.dart';

import 'biblia_version.dart';
import 'versiculo.dart';

/// Versículo + metadata del libro y capítulo donde aparece.
///
/// Se usa en:
/// - Resultados de búsqueda FTS5 (con `BibliaVersion` para mostrar el badge
///   de versión en cada hit).
/// - Versículo aleatorio del home (con `null` para `version` si no se
///   necesita).
/// - Cualquier otra UI que requiera mostrar el texto con su referencia
///   canónica ("Juan 3:16 — Porque de tal manera...").
class VersiculoContexto extends Equatable {
  /// El versículo en sí.
  final Versiculo versiculo;

  /// FK a `version.id` (no es el objeto completo para no acoplar).
  final int versionId;

  /// Nombre del libro (join con `libro.nombre`).
  final String libroNombre;

  /// Abreviatura del libro (join con `libro.abreviatura`).
  final String libroAbreviatura;

  /// Número canónico del libro (1-66).
  final int libroNumero;

  /// Número de capítulo.
  final int capituloNumero;

  /// Versión bíblica completa. Opcional porque el caller puede o no
  /// hacer el JOIN adicional (el random verse del home no lo necesita).
  final BibliaVersion? version;

  const VersiculoContexto({
    required this.versiculo,
    required this.versionId,
    required this.libroNombre,
    required this.libroAbreviatura,
    required this.libroNumero,
    required this.capituloNumero,
    this.version,
  });

  /// Construye desde una fila de SQLite con datos ya joined.
  ///
  /// Columnas esperadas (de un JOIN entre versiculo, capitulo, libro,
  /// y opcionalmente version):
  /// - `id`, `capitulo_id`, `numero`, `texto`  (de `versiculo`)
  /// - `version_id`                            (de `libro`)
  /// - `libro_nombre`, `libro_abreviatura`, `libro_numero` (alias)
  /// - `capitulo_numero`                       (alias de `capitulo.numero`)
  /// - `version_nombre`, `version_abreviatura`, etc. (opcional, de `version`)
  factory VersiculoContexto.fromJoinedMap(Map<String, dynamic> map) {
    final versiculo = Versiculo.fromMap({
      'id': map['id'],
      'capitulo_id': map['capitulo_id'],
      'numero': map['numero'],
      'texto': map['texto'],
    });
    BibliaVersion? version;
    final hasVersion =
        map.containsKey('version_nombre') && map['version_nombre'] != null;
    if (hasVersion) {
      version = BibliaVersion.fromMap({
        'id': map['version_id_v'],
        'nombre': map['version_nombre'],
        'abreviatura': map['version_abreviatura'],
        'idioma': map['version_idioma'] ?? 'es',
        'descripcion': map['version_descripcion'],
        'anio_publicacion': map['version_anio_publicacion'],
        'es_dominio_publico': map['version_es_dominio_publico'] ?? 1,
        'activa': map['version_activa'] ?? 1,
      });
    }
    return VersiculoContexto(
      versiculo: versiculo,
      versionId: map['version_id'] as int,
      libroNombre: map['libro_nombre'] as String,
      libroAbreviatura: map['libro_abreviatura'] as String,
      libroNumero: map['libro_numero'] as int,
      capituloNumero: map['capitulo_numero'] as int,
      version: version,
    );
  }

  /// Etiqueta corta canónica. Ej: "Juan 3:16" o "Gn 1:1".
  String get referencia => '$libroAbreviatura $capituloNumero:${versiculo.numero}';

  /// Etiqueta larga. Ej: "Juan 3:16 (RVR1909)".
  String get referenciaLarga {
    final ver = version != null ? ' (${version!.abreviatura})' : '';
    return '$libroNombre $capituloNumero:${versiculo.numero}$ver';
  }

  @override
  List<Object?> get props => [
        versiculo,
        versionId,
        libroNombre,
        libroAbreviatura,
        libroNumero,
        capituloNumero,
        version,
      ];
}
