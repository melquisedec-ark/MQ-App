import '../../../core/errors/failures.dart';
import '../../entities/himno.dart';
import '../../repositories/hymn_repository.dart';

/// Caso de uso para obtener el detalle completo de un himno.
class GetHymnDetailUseCase {
  final HymnRepository _repository;

  GetHymnDetailUseCase(this._repository);

  /// Obtiene un himno completo por su ID.
  ///
  /// Lanza [NotFoundFailure] si el himno no existe.
  Future<Himno> execute(int himnoId) async {
    if (himnoId <= 0) {
      throw const InvalidArgumentFailure('ID de himno inválido');
    }

    return await _repository.getHymnById(himnoId);
  }
}
