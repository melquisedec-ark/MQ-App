import '../entities/fondo_pantalla.dart';

/// Repositorio de fondos de pantalla.
///
/// Define el contrato para el CRUD de fondos de pantalla
/// utilizados en la interfaz de proyección.
abstract class FondoRepository {
  /// Obtiene todos los fondos de pantalla activos.
  Future<List<FondoPantalla>> getAll();

  /// Obtiene un fondo de pantalla por su [id].
  /// Retorna `null` si no existe.
  Future<FondoPantalla?> getById(int id);

  /// Obtiene el fondo de pantalla predeterminado.
  /// Retorna `null` si no hay ninguno configurado como predeterminado.
  Future<FondoPantalla?> getDefault();

  /// Crea un nuevo fondo de pantalla.
  /// Retorna el ID autogenerado.
  Future<int> create(FondoPantalla fondo);

  /// Actualiza un fondo de pantalla existente.
  Future<void> update(FondoPantalla fondo);

  /// Elimina un fondo de pantalla por su [id].
  /// Retorna `true` si se eliminó correctamente.
  Future<bool> delete(int id);
}
