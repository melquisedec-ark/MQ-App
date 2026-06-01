import 'package:json_annotation/json_annotation.dart';

import '../../core/enums/himno_tipo.dart';
import '../../domain/entities/himno.dart';
import 'version_pais_model.dart';
import 'categoria_model.dart';

part 'himno_model.g.dart';

/// Modelo serializable de Himno para persistencia y transferencia.
@JsonSerializable()
class HimnoModel {
  final int id;
  @JsonKey(name: 'titulo_principal')
  final String tituloPrincipal;
  @JsonKey(name: 'numero_oficial')
  final int? numeroOficial;
  final int tipo;
  final bool activo;
  List<VersionPaisModel>? versiones;
  List<CategoriaModel>? categorias;

  HimnoModel({
    required this.id,
    required this.tituloPrincipal,
    this.numeroOficial,
    required this.tipo,
    this.activo = true,
    this.versiones,
    this.categorias,
  });

  factory HimnoModel.fromJson(Map<String, dynamic> json) =>
      _$HimnoModelFromJson(json);

  Map<String, dynamic> toJson() => _$HimnoModelToJson(this);

  /// Convierte a entidad de dominio.
  Himno toEntity() {
    return Himno(
      id: id,
      titulo: tituloPrincipal,
      numero: numeroOficial,
      tipo: HimnoTipo.fromValue(tipo),
      activo: activo,
      versiones: versiones?.map((v) => v.toEntity()).toList() ?? [],
      categorias: categorias?.map((c) => c.toEntity()).toList() ?? [],
    );
  }

  /// Crea un modelo desde un mapa de SQLite (con columnas snake_case).
  factory HimnoModel.fromMap(Map<String, dynamic> map) {
    return HimnoModel(
      id: map['id'] as int,
      tituloPrincipal: map['titulo_principal'] as String,
      numeroOficial: map['numero_oficial'] as int?,
      tipo: map['tipo'] as int,
      activo: (map['activo'] as int?) == 1,
    );
  }
}
