import '../../../core/errors/failures.dart';
import '../../entities/arreglo_musical.dart';
import '../../entities/estrofa_arreglo.dart';
import '../../repositories/arreglo_repository.dart';
import '../../repositories/hymn_repository.dart';

/// Caso de uso para crear un fork (arreglo personalizado) de un himno.
///
/// Toma un himno existente y crea un ArregloMusical basado en sus estrofas,
/// permitiendo al usuario personalizarlo.
class CreateForkUseCase {
  final HymnRepository _hymnRepository;
  final ArregloRepository _arregloRepository;

  CreateForkUseCase(this._hymnRepository, this._arregloRepository);

  /// Crea un fork de un himno para un usuario.
  ///
  /// [versionPaisId] - ID de la versión de país a forkar
  /// [usuarioId] - ID del usuario que crea el arreglo
  /// [nombreArreglo] - nombre personalizado para el arreglo
  /// [tonalidadBase] - tonalidad base del arreglo
  ///
  /// Retorna el [ArregloMusical] creado.
  Future<ArregloMusical> execute({
    required int versionPaisId,
    required int usuarioId,
    required String nombreArreglo,
    required String tonalidadBase,
  }) async {
    if (versionPaisId <= 0) {
      throw const InvalidArgumentFailure('ID de versión de país inválido');
    }
    if (usuarioId <= 0) {
      throw const InvalidArgumentFailure('ID de usuario inválido');
    }
    if (nombreArreglo.trim().isEmpty) {
      throw const InvalidArgumentFailure(
        'El nombre del arreglo no puede estar vacío',
      );
    }

    // Obtener estrofas originales del himno
    final estrofasOriginales = await _hymnRepository.getStanzas(versionPaisId);

    // Crear estrofas de arreglo a partir de las originales
    final estrofasArreglo = estrofasOriginales.asMap().entries.map((entry) {
      final estrofa = entry.value;
      return EstrofaArreglo(
        id: 0, // Nueva, se asignará en BD
        arregloMusicalId: 0, // Se asignará tras crear el arreglo
        tipo: estrofa.tipo,
        orden: estrofa.orden,
        contenido: estrofa.contenido, // Copia del contenido original
      );
    }).toList();

    // Crear el arreglo musical
    final arreglo = ArregloMusical(
      id: 0,
      versionPaisId: versionPaisId,
      usuarioId: usuarioId,
      nombreArreglo: nombreArreglo.trim(),
      tonalidadBase: tonalidadBase,
      version: 1,
      estrofas: estrofasArreglo,
    );

    return await _arregloRepository.createArreglo(arreglo, estrofasArreglo);
  }
}
