import 'package:freezed_annotation/freezed_annotation.dart';
import 'estrofa.dart';

part 'version_pais.freezed.dart';

/// Entidad de dominio que representa una versión de himno para un país específico.
@freezed
class VersionPais with _$VersionPais {
  const factory VersionPais({
    required int id,
    required int himnoId,
    required int paisId,
    String? paisNombre,
    String? paisCodigo,
    required String tonalidadOriginal,
    @Default(true) bool activo,
    @Default([]) List<Estrofa> estrofas,
  }) = _VersionPais;
}
