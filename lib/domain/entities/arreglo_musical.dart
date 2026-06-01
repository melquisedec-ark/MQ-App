import 'package:freezed_annotation/freezed_annotation.dart';
import 'estrofa_arreglo.dart';

part 'arreglo_musical.freezed.dart';

/// Entidad de dominio que representa un arreglo musical personalizado (fork).
@freezed
class ArregloMusical with _$ArregloMusical {
  const factory ArregloMusical({
    required int id,
    required int versionPaisId,
    required int usuarioId,
    required String nombreArreglo,
    required String tonalidadBase,
    @Default(1) int version,
    @Default([]) List<EstrofaArreglo> estrofas,
  }) = _ArregloMusical;
}
