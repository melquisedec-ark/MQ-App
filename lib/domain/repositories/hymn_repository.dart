import '../entities/categoria.dart';
import '../entities/estrofa.dart';
import '../entities/himno.dart';
import '../../core/enums/himno_tipo.dart';

/// Parámetros de búsqueda para himnos.
class HymnQuery {
  final String text;
  final int? tipo; // null = todos, 1=Oficial, 2=Inspirada, 3=Convencion

  const HymnQuery({this.text = '', this.tipo});

  HymnQuery copyWith({String? text, int? tipo}) {
    return HymnQuery(
      text: text ?? this.text,
      tipo: tipo ?? this.tipo,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HymnQuery && text == other.text && tipo == other.tipo;

  @override
  int get hashCode => text.hashCode ^ tipo.hashCode;
}

/// Repositorio de himnos.
abstract class HymnRepository {
  /// Busca himnos por texto (título o número) con filtros opcionales.
  ///
  /// [orderBy] permite ordenar alfabéticamente: 'titulo_principal ASC' (A-Z),
  ///   'titulo_principal DESC' (Z-A), o 'h.numero_oficial ASC' (default).
  /// [categoriaId] filtra himnos que pertenecen a la categoría indicada.
  Future<List<Himno>> searchHymns(
    String query, {
    HimnoTipo? tipo,
    String? orderBy,
    int? categoriaId,
  });

  /// Obtiene un himno por su ID.
  Future<Himno> getHymnById(int id);

  /// Obtiene las estrofas de una versión de país.
  Future<List<Estrofa>> getStanzas(int versionPaisId);

  /// Obtiene todas las categorías disponibles.
  Future<List<Categoria>> getCategories();

  /// Busca himnos por categoría.
  Future<List<Himno>> getHymnsByCategory(int categoriaId);

  /// Crea un nuevo himno completo con versiones, estrofas y categorías.
  ///
  /// [himno] entidad de dominio con los datos del himno.
  /// [versiones] lista de mapas con datos de versiones de país.
  /// [estrofas] lista de mapas con datos de estrofas (cada una debe incluir
  ///   `version_idx` apuntando al índice en [versiones]).
  /// [categoriaIds] IDs de categorías a asociar.
  ///
  /// Retorna el ID del himno creado.
  Future<int> createHymn(
    Himno himno,
    List<Map<String, dynamic>> versiones,
    List<Map<String, dynamic>> estrofas,
    List<int> categoriaIds,
  );

  /// Actualiza un himno completo con sus versiones, estrofas y categorías.
  ///
  /// Reemplaza todos los datos hijos (versiones, estrofas, categorías)
  /// con los nuevos valores.
  Future<void> updateHymn(
    Himno himno,
    List<Map<String, dynamic>> versiones,
    List<Map<String, dynamic>> estrofas,
    List<int> categoriaIds,
  );

  /// Elimina (soft-delete) un himno por su ID.
  ///
  /// Establece `activo = 0` en lugar de borrar físicamente.
  Future<void> deleteHymn(int id);

  /// Verifica si un himno tiene referencias en otras tablas
  /// (arreglos musicales, pistas de audio, historial de reproducción).
  Future<bool> hymnHasReferences(int himnoId);

  /// Obtiene todas las categorías disponibles.
  Future<List<Categoria>> getAllCategorias();

  /// Crea una nueva categoría con el nombre dado.
  ///
  /// Retorna la [Categoria] recién creada.
  Future<Categoria> createCategoria(String nombre);

  /// Elimina una categoría por su ID.
  Future<void> deleteCategoria(int id);

  @Deprecated('Usar ArregloRepository.createArreglo en su lugar')
  Future<int> createArrangement({
    required int versionPaisId,
    required int usuarioId,
    required String nombreArreglo,
    required String tonalidadBase,
    required List<({String tipo, int orden, String contenido})> estrofas,
  });
}
