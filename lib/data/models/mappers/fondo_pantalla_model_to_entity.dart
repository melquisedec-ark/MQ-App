import '../../../core/enums/fondo_pantalla_tipo.dart';
import '../../../domain/entities/fondo_pantalla.dart';
import '../fondo_pantalla_model.dart';

/// Extensión para convertir FondoPantallaModel a entidad de dominio.
extension FondoPantallaModelX on FondoPantallaModel {
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
}

extension FondoPantallaModelListX on List<FondoPantallaModel> {
  List<FondoPantalla> toEntities() => map((m) => m.toEntity()).toList();
}
