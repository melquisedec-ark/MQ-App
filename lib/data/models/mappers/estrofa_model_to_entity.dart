import '../../../core/enums/estrofa_tipo.dart';
import '../../../domain/entities/estrofa.dart';
import '../estrofa_model.dart';

/// Extensión para convertir EstrofaModel a entidad de dominio.
extension EstrofaModelX on EstrofaModel {
  Estrofa toEntity() {
    return Estrofa(
      id: id,
      versionPaisId: versionPaisId,
      tipo: EstrofaTipo.fromValue(tipo),
      orden: orden,
      contenido: contenido,
    );
  }
}

extension EstrofaModelListX on List<EstrofaModel> {
  List<Estrofa> toEntities() => map((m) => m.toEntity()).toList();
}
