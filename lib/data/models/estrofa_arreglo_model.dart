import 'package:json_annotation/json_annotation.dart';

import '../../core/enums/estrofa_tipo.dart';
import '../../domain/entities/estrofa_arreglo.dart';

part 'estrofa_arreglo_model.g.dart';

/// Modelo serializable de EstrofaArreglo.
@JsonSerializable()
class EstrofaArregloModel {
  final int id;
  @JsonKey(name: 'arreglo_musical_id')
  final int arregloMusicalId;
  final String tipo;
  final int orden;
  final String contenido;

  const EstrofaArregloModel({
    required this.id,
    required this.arregloMusicalId,
    required this.tipo,
    required this.orden,
    required this.contenido,
  });

  factory EstrofaArregloModel.fromJson(Map<String, dynamic> json) =>
      _$EstrofaArregloModelFromJson(json);

  Map<String, dynamic> toJson() => _$EstrofaArregloModelToJson(this);

  EstrofaArreglo toEntity() {
    return EstrofaArreglo(
      id: id,
      arregloMusicalId: arregloMusicalId,
      tipo: EstrofaTipo.fromValue(tipo),
      orden: orden,
      contenido: contenido,
    );
  }

  factory EstrofaArregloModel.fromMap(Map<String, dynamic> map) {
    return EstrofaArregloModel(
      id: map['id'] as int,
      arregloMusicalId: map['arreglo_musical_id'] as int,
      tipo: map['tipo'] as String,
      orden: map['orden'] as int,
      contenido: map['contenido'] as String,
    );
  }
}
