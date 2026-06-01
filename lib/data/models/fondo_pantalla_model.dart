// ignore_for_file: non_constant_identifier_names
// Las columnas SQLite usan snake_case, por eso los campos del modelo
// usan ese estilo en lugar de lowerCamelCase.

import 'package:json_annotation/json_annotation.dart';

import '../../core/enums/fondo_pantalla_tipo.dart';
import '../../domain/entities/fondo_pantalla.dart';

part 'fondo_pantalla_model.g.dart';

/// Modelo serializable de FondoPantalla para JSON y SQLite.
@JsonSerializable()
class FondoPantallaModel {
  final int id;
  final String nombre;
  final String tipo;
  final String? ruta_archivo;
  final String? color_hex;
  final int es_predeterminado;
  final int activo;

  const FondoPantallaModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.ruta_archivo,
    this.color_hex,
    this.es_predeterminado = 0,
    this.activo = 1,
  });

  factory FondoPantallaModel.fromJson(Map<String, dynamic> json) =>
      _$FondoPantallaModelFromJson(json);

  Map<String, dynamic> toJson() => _$FondoPantallaModelToJson(this);

  FondoPantalla toEntity() {
    return FondoPantalla(
      id: id,
      nombre: nombre,
      tipo: FondoPantallaTipo.fromValue(tipo),
      rutaArchivo: ruta_archivo,
      colorHex: color_hex,
      esPredeterminado: es_predeterminado == 1,
      activo: activo == 1,
    );
  }

  factory FondoPantallaModel.fromMap(Map<String, dynamic> map) {
    return FondoPantallaModel(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      tipo: map['tipo'] as String,
      ruta_archivo: map['ruta_archivo'] as String?,
      color_hex: map['color_hex'] as String?,
      es_predeterminado: map['es_predeterminado'] as int? ?? 0,
      activo: map['activo'] as int? ?? 1,
    );
  }
}
