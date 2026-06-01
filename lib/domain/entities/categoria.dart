import 'package:freezed_annotation/freezed_annotation.dart';

part 'categoria.freezed.dart';

/// Entidad de dominio que representa una categoría para clasificar himnos.
@freezed
class Categoria with _$Categoria {
  const factory Categoria({
    required int id,
    required String nombre,
  }) = _Categoria;
}
