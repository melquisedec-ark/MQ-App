import '../../../domain/entities/version_pais.dart';
import '../version_pais_model.dart';

/// Extensión para convertir VersionPaisModel a entidad de dominio.
extension VersionPaisModelX on VersionPaisModel {
  VersionPais toEntity() {
    return VersionPais(
      id: id,
      himnoId: himnoId,
      paisId: paisId,
      paisNombre: paisNombre,
      paisCodigo: paisCodigo,
      tonalidadOriginal: tonalidadOriginal,
      activo: activo,
      estrofas: estrofas?.map((e) => e.toEntity()).toList() ?? [],
    );
  }
}

extension VersionPaisModelListX on List<VersionPaisModel> {
  List<VersionPais> toEntities() => map((m) => m.toEntity()).toList();
}
