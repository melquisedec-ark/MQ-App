import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/arreglo_musical.dart';
import 'estrofa_arreglo_model.dart';

part 'arreglo_musical_model.g.dart';

/// Modelo serializable de ArregloMusical.
@JsonSerializable()
class ArregloMusicalModel {
  final int id;
  @JsonKey(name: 'version_pais_id')
  final int versionPaisId;
  @JsonKey(name: 'usuario_id')
  final int usuarioId;
  @JsonKey(name: 'nombre_arreglo')
  final String nombreArreglo;
  @JsonKey(name: 'tonalidad_base')
  final String tonalidadBase;
  final int version;
  final List<EstrofaArregloModel>? estrofas;

  const ArregloMusicalModel({
    required this.id,
    required this.versionPaisId,
    required this.usuarioId,
    required this.nombreArreglo,
    required this.tonalidadBase,
    this.version = 1,
    this.estrofas,
  });

  factory ArregloMusicalModel.fromJson(Map<String, dynamic> json) =>
      _$ArregloMusicalModelFromJson(json);

  Map<String, dynamic> toJson() => _$ArregloMusicalModelToJson(this);

  ArregloMusical toEntity() {
    return ArregloMusical(
      id: id,
      versionPaisId: versionPaisId,
      usuarioId: usuarioId,
      nombreArreglo: nombreArreglo,
      tonalidadBase: tonalidadBase,
      version: version,
      estrofas: estrofas?.map((e) => e.toEntity()).toList() ?? [],
    );
  }

  factory ArregloMusicalModel.fromMap(Map<String, dynamic> map) {
    return ArregloMusicalModel(
      id: map['id'] as int,
      versionPaisId: map['version_pais_id'] as int,
      usuarioId: map['usuario_id'] as int,
      nombreArreglo: map['nombre_arreglo'] as String,
      tonalidadBase: map['tonalidad_base'] as String,
      version: map['version'] as int? ?? 1,
    );
  }
}
