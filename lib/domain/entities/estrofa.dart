import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/enums/estrofa_tipo.dart';

part 'estrofa.freezed.dart';

/// Entidad de dominio que representa una estrofa individual dentro de un himno.
/// El contenido está en formato ChordPro.
@freezed
class Estrofa with _$Estrofa {
  const factory Estrofa({
    required int id,
    required int versionPaisId,
    required EstrofaTipo tipo,
    required int orden,
    required String contenido,
  }) = _Estrofa;

  const Estrofa._();

  /// `true` si esta estrofa es un coro.
  bool get isChorus => tipo == EstrofaTipo.coro;
}
