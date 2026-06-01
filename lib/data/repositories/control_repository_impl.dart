import 'dart:async';

import 'package:logging/logging.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/repositories/control_repository.dart';
import '../datasources/remote/grpc_control_datasource.dart';

/// Implementación del repositorio de control remoto.
///
/// Traduce NetworkException del datasource en NetworkFailure del dominio.
class ControlRepositoryImpl implements ControlRepository {
  static final _log = Logger('ControlRepositoryImpl');

  final GrpcControlDataSource _dataSource;

  ControlRepositoryImpl({GrpcControlDataSource? dataSource})
      : _dataSource = dataSource ?? GrpcControlDataSource();

  @override
  Future<bool> connect(String host, int port) async {
    try {
      await _dataSource.connect(host, port);
      return true;
    } on NetworkException catch (e) {
      _log.severe('NetworkFailure en connect: $e');
      throw NetworkFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en connect: $e');
      throw const NetworkFailure('Error inesperado al conectar');
    }
  }

  @override
  Future<bool> sendShowHimno(int himnoId) async {
    try {
      return await _dataSource.sendShowHimno(himnoId);
    } on NetworkException catch (e) {
      _log.severe('NetworkFailure en sendShowHimno: $e');
      throw NetworkFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en sendShowHimno: $e');
      throw const NetworkFailure('Error inesperado al enviar comando');
    }
  }

  @override
  Future<bool> sendNextStanza() async {
    try {
      return await _dataSource.sendNextStanza();
    } on NetworkException catch (e) {
      _log.severe('NetworkFailure en sendNextStanza: $e');
      throw NetworkFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en sendNextStanza: $e');
      throw const NetworkFailure('Error inesperado al enviar comando');
    }
  }

  @override
  Future<bool> sendPrevStanza() async {
    try {
      return await _dataSource.sendPrevStanza();
    } on NetworkException catch (e) {
      _log.severe('NetworkFailure en sendPrevStanza: $e');
      throw NetworkFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en sendPrevStanza: $e');
      throw const NetworkFailure('Error inesperado al enviar comando');
    }
  }

  @override
  Future<bool> sendGoToStanza(int index) async {
    try {
      return await _dataSource.sendGoToStanza(index);
    } on NetworkException catch (e) {
      _log.severe('NetworkFailure en sendGoToStanza: $e');
      throw NetworkFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en sendGoToStanza: $e');
      throw const NetworkFailure('Error inesperado al enviar comando');
    }
  }

  @override
  Future<bool> sendBlackout(bool active) async {
    try {
      return await _dataSource.sendBlackout(active);
    } on NetworkException catch (e) {
      _log.severe('NetworkFailure en sendBlackout: $e');
      throw NetworkFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en sendBlackout: $e');
      throw const NetworkFailure('Error inesperado al enviar comando');
    }
  }

  @override
  Future<bool> sendPlayAudio() async {
    // Audio playback is not yet implemented in gRPC protocol.
    // This is a placeholder for future implementation.
    _log.warning('sendPlayAudio no implementado en protocolo gRPC.');
    return false;
  }

  @override
  Future<bool> sendStopAudio() async {
    _log.warning('sendStopAudio no implementado en protocolo gRPC.');
    return false;
  }

  @override
  Future<bool> sendSetConfig({String? fondo, double? tamano}) async {
    try {
      var success = true;
      if (fondo != null) {
        success = await _dataSource.sendSetBackground(fondo) && success;
      }
      if (tamano != null) {
        success = await _dataSource.sendSetFontSize(tamano) && success;
      }
      return success;
    } on NetworkException catch (e) {
      _log.severe('NetworkFailure en sendSetConfig: $e');
      throw NetworkFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en sendSetConfig: $e');
      throw const NetworkFailure('Error inesperado al configurar display');
    }
  }

  @override
  Future<DisplayStatus> getStatus() async {
    try {
      return await _dataSource.getStatus();
    } on NetworkException catch (e) {
      _log.severe('NetworkFailure en getStatus: $e');
      throw NetworkFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en getStatus: $e');
      throw const NetworkFailure('Error inesperado al obtener estado');
    }
  }

  @override
  Stream<DisplayStatus> watchStatus() {
    try {
      return _dataSource.watchStatus();
    } on NetworkException catch (e) {
      _log.severe('NetworkFailure en watchStatus: $e');
      throw NetworkFailure(e.message);
    } catch (e) {
      _log.severe('Error inesperado en watchStatus: $e');
      throw const NetworkFailure('Error inesperado al iniciar stream');
    }
  }
}
