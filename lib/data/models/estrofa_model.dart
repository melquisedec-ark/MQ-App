import 'package:json_annotation/json_annotation.dart';

import '../../core/enums/estrofa_tipo.dart';
import '../../domain/entities/estrofa.dart';

part 'estrofa_model.g.dart';

/// Modelo serializable de Estrofa.
@JsonSerializable()
class EstrofaModel {
  final int id;
  @JsonKey(name: 'version_pais_id')
  final int versionPaisId;
  final String tipo;
  final int orden;
  final String contenido;

  const EstrofaModel({
    required this.id,
    required this.versionPaisId,
    required this.tipo,
    required this.orden,
    required this.contenido,
  });

  factory EstrofaModel.fromJson(Map<String, dynamic> json) =>
      _$EstrofaModelFromJson(json);

  Map<String, dynamic> toJson() => _$EstrofaModelToJson(this);

  Estrofa toEntity() {
    return Estrofa(
      id: id,
      versionPaisId: versionPaisId,
      tipo: EstrofaTipo.fromValue(tipo),
      orden: orden,
      contenido: contenido,
    );
  }

  factory EstrofaModel.fromMap(Map<String, dynamic> map) {
    return EstrofaModel(
      id: map['id'] as int,
      versionPaisId: map['version_pais_id'] as int,
      tipo: map['tipo'] as String,
      orden: map['orden'] as int,
      contenido: map['contenido'] as String,
    );
  }
}
