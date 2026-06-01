import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/enums/estrofa_tipo.dart';

part 'estrofa_arreglo.freezed.dart';

/// Entidad de dominio que representa una estrofa dentro de un arreglo personalizado.
@freezed
class EstrofaArreglo with _$EstrofaArreglo {
  const factory EstrofaArreglo({
    required int id,
    required int arregloMusicalId,
    required EstrofaTipo tipo,
    required int orden,
    required String contenido,
  }) = _EstrofaArreglo;
}
