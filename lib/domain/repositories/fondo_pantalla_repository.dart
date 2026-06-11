import '../entities/fondo_pantalla.dart';
import '../../core/enums/fondo_pantalla_tipo.dart';

/// Interfaz de repositorio para operaciones CRUD sobre fondos de pantalla.
abstract class FondoPantallaRepository {
  /// Obtiene todos los fondos de pantalla ordenados por nombre.
  Future<List<FondoPantalla>> getAll();

  /// Obtiene un fondo de pantalla por su [id].
  /// Retorna `null` si no existe.
  Future<FondoPantalla?> getById(int id);

  /// Crea un fondo de pantalla.
  /// Retorna el ID autogenerado.
  Future<int> create({
    required String nombre,
    required FondoPantallaTipo tipo,
    String? rutaArchivo,
    String? colorHex,
    bool esPredeterminado,
    bool activo,
  });

  /// Actualiza un fondo de pantalla.
  Future<void> update({
    required int id,
    required String nombre,
    required FondoPantallaTipo tipo,
    String? rutaArchivo,
    String? colorHex,
    required bool esPredeterminado,
    required bool activo,
  });

  /// Elimina el fondo de pantalla con [id].
  Future<void> delete(int id);
}
