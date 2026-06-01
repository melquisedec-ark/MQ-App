// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pista_audio.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PistaAudio {
  int get id => throw _privateConstructorUsedError;
  int get himnoId => throw _privateConstructorUsedError;
  String get rutaArchivo => throw _privateConstructorUsedError;
  String? get descripcion => throw _privateConstructorUsedError;
  double? get duracionSegundos => throw _privateConstructorUsedError;
  String? get formato => throw _privateConstructorUsedError;

  /// Create a copy of PistaAudio
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PistaAudioCopyWith<PistaAudio> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PistaAudioCopyWith<$Res> {
  factory $PistaAudioCopyWith(
          PistaAudio value, $Res Function(PistaAudio) then) =
      _$PistaAudioCopyWithImpl<$Res, PistaAudio>;
  @useResult
  $Res call(
      {int id,
      int himnoId,
      String rutaArchivo,
      String? descripcion,
      double? duracionSegundos,
      String? formato});
}

/// @nodoc
class _$PistaAudioCopyWithImpl<$Res, $Val extends PistaAudio>
    implements $PistaAudioCopyWith<$Res> {
  _$PistaAudioCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PistaAudio
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? himnoId = null,
    Object? rutaArchivo = null,
    Object? descripcion = freezed,
    Object? duracionSegundos = freezed,
    Object? formato = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      himnoId: null == himnoId
          ? _value.himnoId
          : himnoId // ignore: cast_nullable_to_non_nullable
              as int,
      rutaArchivo: null == rutaArchivo
          ? _value.rutaArchivo
          : rutaArchivo // ignore: cast_nullable_to_non_nullable
              as String,
      descripcion: freezed == descripcion
          ? _value.descripcion
          : descripcion // ignore: cast_nullable_to_non_nullable
              as String?,
      duracionSegundos: freezed == duracionSegundos
          ? _value.duracionSegundos
          : duracionSegundos // ignore: cast_nullable_to_non_nullable
              as double?,
      formato: freezed == formato
          ? _value.formato
          : formato // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PistaAudioImplCopyWith<$Res>
    implements $PistaAudioCopyWith<$Res> {
  factory _$$PistaAudioImplCopyWith(
          _$PistaAudioImpl value, $Res Function(_$PistaAudioImpl) then) =
      __$$PistaAudioImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int himnoId,
      String rutaArchivo,
      String? descripcion,
      double? duracionSegundos,
      String? formato});
}

/// @nodoc
class __$$PistaAudioImplCopyWithImpl<$Res>
    extends _$PistaAudioCopyWithImpl<$Res, _$PistaAudioImpl>
    implements _$$PistaAudioImplCopyWith<$Res> {
  __$$PistaAudioImplCopyWithImpl(
      _$PistaAudioImpl _value, $Res Function(_$PistaAudioImpl) _then)
      : super(_value, _then);

  /// Create a copy of PistaAudio
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? himnoId = null,
    Object? rutaArchivo = null,
    Object? descripcion = freezed,
    Object? duracionSegundos = freezed,
    Object? formato = freezed,
  }) {
    return _then(_$PistaAudioImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      himnoId: null == himnoId
          ? _value.himnoId
          : himnoId // ignore: cast_nullable_to_non_nullable
              as int,
      rutaArchivo: null == rutaArchivo
          ? _value.rutaArchivo
          : rutaArchivo // ignore: cast_nullable_to_non_nullable
              as String,
      descripcion: freezed == descripcion
          ? _value.descripcion
          : descripcion // ignore: cast_nullable_to_non_nullable
              as String?,
      duracionSegundos: freezed == duracionSegundos
          ? _value.duracionSegundos
          : duracionSegundos // ignore: cast_nullable_to_non_nullable
              as double?,
      formato: freezed == formato
          ? _value.formato
          : formato // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$PistaAudioImpl implements _PistaAudio {
  const _$PistaAudioImpl(
      {required this.id,
      required this.himnoId,
      required this.rutaArchivo,
      this.descripcion,
      this.duracionSegundos,
      this.formato});

  @override
  final int id;
  @override
  final int himnoId;
  @override
  final String rutaArchivo;
  @override
  final String? descripcion;
  @override
  final double? duracionSegundos;
  @override
  final String? formato;

  @override
  String toString() {
    return 'PistaAudio(id: $id, himnoId: $himnoId, rutaArchivo: $rutaArchivo, descripcion: $descripcion, duracionSegundos: $duracionSegundos, formato: $formato)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PistaAudioImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.himnoId, himnoId) || other.himnoId == himnoId) &&
            (identical(other.rutaArchivo, rutaArchivo) ||
                other.rutaArchivo == rutaArchivo) &&
            (identical(other.descripcion, descripcion) ||
                other.descripcion == descripcion) &&
            (identical(other.duracionSegundos, duracionSegundos) ||
                other.duracionSegundos == duracionSegundos) &&
            (identical(other.formato, formato) || other.formato == formato));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, himnoId, rutaArchivo,
      descripcion, duracionSegundos, formato);

  /// Create a copy of PistaAudio
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PistaAudioImplCopyWith<_$PistaAudioImpl> get copyWith =>
      __$$PistaAudioImplCopyWithImpl<_$PistaAudioImpl>(this, _$identity);
}

abstract class _PistaAudio implements PistaAudio {
  const factory _PistaAudio(
      {required final int id,
      required final int himnoId,
      required final String rutaArchivo,
      final String? descripcion,
      final double? duracionSegundos,
      final String? formato}) = _$PistaAudioImpl;

  @override
  int get id;
  @override
  int get himnoId;
  @override
  String get rutaArchivo;
  @override
  String? get descripcion;
  @override
  double? get duracionSegundos;
  @override
  String? get formato;

  /// Create a copy of PistaAudio
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PistaAudioImplCopyWith<_$PistaAudioImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
