import '../../domain/entities/pista_audio.dart';
import '../../../domain/repositories/pista_audio_repository.dart';
import '../datasources/local/catalog_local_datasource.dart';
import '../models/pista_audio_model.dart';

/// Implementación de [PistaAudioRepository] usando [CatalogLocalDataSource].
class PistaAudioRepositoryImpl implements PistaAudioRepository {
  final CatalogLocalDataSource _dataSource;

  PistaAudioRepositoryImpl(this._dataSource);

  @override
  Future<List<PistaAudio>> getByHimno(int himnoId) async {
    final models = await _dataSource.getPistasByHimno(himnoId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<int> create({
    required int himnoId,
    required String rutaArchivo,
    String? descripcion,
    double? duracionSegundos,
    String? formato,
    String origen = 'local',
  }) {
    final model = PistaAudioModel(
      id: 0,
      himnoId: himnoId,
      rutaArchivo: rutaArchivo,
      descripcion: descripcion,
      duracionSegundos: duracionSegundos,
      formato: formato,
      origen: origen,
    );
    return _dataSource.insertPista(model);
  }

  @override
  Future<void> delete(int id) => _dataSource.deletePista(id);
}
