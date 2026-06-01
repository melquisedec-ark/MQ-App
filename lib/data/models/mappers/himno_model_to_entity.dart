import '../../../core/enums/himno_tipo.dart';
import '../../../domain/entities/himno.dart';
import '../himno_model.dart';

/// Extensión para convertir HimnoModel a entidad de dominio.
extension HimnoModelX on HimnoModel {
  /// Convierte este modelo a una entidad Himno.
  Himno toEntity() {
    return Himno(
      id: id,
      titulo: tituloPrincipal,
      numero: numeroOficial,
      tipo: HimnoTipo.fromValue(tipo),
      activo: activo,
      versiones: versiones?.map((v) => v.toEntity()).toList() ?? [],
      categorias: categorias?.map((c) => c.toEntity()).toList() ?? [],
    );
  }
}

/// Extensión para convertir lista de modelos a lista de entidades.
extension HimnoModelListX on List<HimnoModel> {
  List<Himno> toEntities() => map((m) => m.toEntity()).toList();
}
