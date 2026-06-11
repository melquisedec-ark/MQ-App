import '../../../core/errors/auth_exception.dart';
import '../../../core/errors/failures.dart';
import '../../entities/himno.dart';
import '../../repositories/hymn_repository.dart';

/// Caso de uso para crear un himno completo con versiones, estrofas
/// y categorías.
///
/// Requiere que el usuario esté autenticado (administrador).
class CreateHymnUseCase {
  final HymnRepository _repository;

  CreateHymnUseCase(this._repository);

  /// Crea un himno y todos sus datos asociados.
  ///
  /// [himno] entidad de dominio con los datos del himno.
  /// [versiones] lista de mapas con datos de versiones de país.
  /// [estrofas] lista de mapas con datos de estrofas (cada una debe incluir
  ///   `version_idx` apuntando al índice en [versiones]).
  /// [categoriaIds] IDs de categorías a asociar.
  /// [isAdmin] indica si el usuario tiene permisos de administrador.
  ///
  /// Retorna el ID del himno creado.
  ///
  /// Lanza [AuthException] si el usuario no está autenticado.
  /// Lanza [InvalidArgumentFailure] si los datos son inválidos.
  /// Lanza [DatabaseFailure] si ocurre un error en la base de datos.
  Future<int> execute(
    Himno himno,
    List<Map<String, dynamic>> versiones,
    List<Map<String, dynamic>> estrofas,
    List<int> categoriaIds, {
    required bool isAdmin,
  }) async {
    if (!isAdmin) {
      throw const AuthException('Solo administradores pueden crear himnos');
    }

    if (himno.titulo.trim().isEmpty) {
      throw const InvalidArgumentFailure('El título del himno es obligatorio');
    }

    if (versiones.isEmpty) {
      throw const InvalidArgumentFailure(
        'Debe proporcionar al menos una versión de país',
      );
    }

    return _repository.createHymn(himno, versiones, estrofas, categoriaIds);
  }
}


