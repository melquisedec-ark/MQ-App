import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/categoria.dart';

part 'categoria_model.g.dart';

/// Modelo serializable de Categoria.
@JsonSerializable()
class CategoriaModel {
  final int id;
  final String nombre;

  const CategoriaModel({
    required this.id,
    required this.nombre,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) =>
      _$CategoriaModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoriaModelToJson(this);

  Categoria toEntity() => Categoria(id: id, nombre: nombre);

  factory CategoriaModel.fromMap(Map<String, dynamic> map) {
    return CategoriaModel(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
    );
  }
}
