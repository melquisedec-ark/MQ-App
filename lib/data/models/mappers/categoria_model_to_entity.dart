import '../../../domain/entities/categoria.dart';
import '../categoria_model.dart';

/// Extensión para convertir CategoriaModel a entidad de dominio.
extension CategoriaModelX on CategoriaModel {
  Categoria toEntity() => Categoria(id: id, nombre: nombre);
}

extension CategoriaModelListX on List<CategoriaModel> {
  List<Categoria> toEntities() => map((m) => m.toEntity()).toList();
}
