import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/enums/fondo_pantalla_tipo.dart';

part 'fondo_pantalla.freezed.dart';

/// Entidad de dominio que representa un fondo de pantalla
/// (imagen, video o color sólido) para la interfaz de proyección.
@freezed
class FondoPantalla with _$FondoPantalla {
  const factory FondoPantalla({
    required int id,
    required String nombre,
    required FondoPantallaTipo tipo,
    String? rutaArchivo,
    String? colorHex,
    @Default(false) bool esPredeterminado,
    @Default(true) bool activo,
  }) = _FondoPantalla;
}
