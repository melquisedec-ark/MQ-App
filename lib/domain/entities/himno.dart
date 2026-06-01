import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/enums/himno_tipo.dart';
import 'version_pais.dart';
import 'categoria.dart';

part 'himno.freezed.dart';

/// Entidad de dominio que representa un himno completo.
@freezed
class Himno with _$Himno {
  const factory Himno({
    required int id,
    required String titulo,
    int? numero,
    required HimnoTipo tipo,
    @Default(true) bool activo,
    @Default([]) List<VersionPais> versiones,
    @Default([]) List<Categoria>? categorias,
  }) = _Himno;

  const Himno._();

  /// `true` si el himno es de tipo oficial.
  bool get esOficial => tipo == HimnoTipo.oficial;

  /// Nombre de la primera categoría asignada (si existe).
  String get categoria => categorias?.firstOrNull?.nombre ?? '';

  /// ID de la primera versión de país disponible,
  /// o `-1` si el himno no tiene versiones.
  int get primaryVersionPaisId => versiones.firstOrNull?.id ?? -1;

  /// Código ISO del país de la primera versión disponible (ej. "SV").
  String? get paisCodigo => versiones.firstOrNull?.paisCodigo;

  /// Primera línea de la primera estrofa de la primera versión
  /// (sin marcadores ChordPro).
  String? get primeraLinea =>
      versiones.firstOrNull?.estrofas.firstOrNull?.contenido
          .split('\n')
          .firstOrNull
          ?.replaceAll(RegExp(r'\[.*?\]'), '')
          .trim();
}
