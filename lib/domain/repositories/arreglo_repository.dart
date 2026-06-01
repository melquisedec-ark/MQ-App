import '../entities/arreglo_musical.dart';
import '../entities/estrofa_arreglo.dart';

/// Repositorio de arreglos musicales personalizados.
///
/// Define el contrato para el CRUD de forks de himnos,
/// incluyendo la gestión de sus estrofas asociadas.
abstract class ArregloRepository {
  /// Crea un nuevo arreglo musical con sus estrofas.
  ///
  /// [arreglo] - entidad del arreglo (sin ID, se asigna en BD)
  /// [estrofas] - lista de estrofas del arreglo
  ///
  /// Retorna el [ArregloMusical] creado con su ID asignado.
  Future<ArregloMusical> createArreglo(
    ArregloMusical arreglo,
    List<EstrofaArreglo> estrofas,
  );

  /// Obtiene todos los arreglos de un usuario.
  Future<List<ArregloMusical>> getArreglosByUser(int usuarioId);

  /// Obtiene un arreglo por su ID.
  /// Retorna `null` si no existe.
  Future<ArregloMusical?> getArregloById(int id);

  /// Obtiene las estrofas de un arreglo, ordenadas por orden.
  Future<List<EstrofaArreglo>> getEstrofasByArreglo(int arregloId);

  /// Actualiza un arreglo existente reemplazando sus estrofas.
  Future<void> updateArreglo(
    ArregloMusical arreglo,
    List<EstrofaArreglo> estrofas,
  );

  /// Elimina un arreglo por su ID.
  /// Retorna `true` si se eliminó correctamente.
  Future<bool> deleteArreglo(int id);
}
