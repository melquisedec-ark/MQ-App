import '../../../domain/entities/arreglo_musical.dart';
import '../arreglo_musical_model.dart';

/// Extensión para convertir ArregloMusicalModel a entidad de dominio.
extension ArregloMusicalModelX on ArregloMusicalModel {
  ArregloMusical toEntity() {
    return ArregloMusical(
      id: id,
      versionPaisId: versionPaisId,
      usuarioId: usuarioId,
      nombreArreglo: nombreArreglo,
      tonalidadBase: tonalidadBase,
      version: version,
      estrofas: estrofas?.map((e) => e.toEntity()).toList() ?? [],
    );
  }
}

extension ArregloMusicalModelListX on List<ArregloMusicalModel> {
  List<ArregloMusical> toEntities() => map((m) => m.toEntity()).toList();
}
