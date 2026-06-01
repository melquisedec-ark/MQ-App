// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'estrofa.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Estrofa {
  int get id => throw _privateConstructorUsedError;
  int get versionPaisId => throw _privateConstructorUsedError;
  EstrofaTipo get tipo => throw _privateConstructorUsedError;
  int get orden => throw _privateConstructorUsedError;
  String get contenido => throw _privateConstructorUsedError;

  /// Create a copy of Estrofa
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EstrofaCopyWith<Estrofa> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EstrofaCopyWith<$Res> {
  factory $EstrofaCopyWith(Estrofa value, $Res Function(Estrofa) then) =
      _$EstrofaCopyWithImpl<$Res, Estrofa>;
  @useResult
  $Res call(
      {int id,
      int versionPaisId,
      EstrofaTipo tipo,
      int orden,
      String contenido});
}

/// @nodoc
class _$EstrofaCopyWithImpl<$Res, $Val extends Estrofa>
    implements $EstrofaCopyWith<$Res> {
  _$EstrofaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Estrofa
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? versionPaisId = null,
    Object? tipo = null,
    Object? orden = null,
    Object? contenido = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      versionPaisId: null == versionPaisId
          ? _value.versionPaisId
          : versionPaisId // ignore: cast_nullable_to_non_nullable
              as int,
      tipo: null == tipo
          ? _value.tipo
          : tipo // ignore: cast_nullable_to_non_nullable
              as EstrofaTipo,
      orden: null == orden
          ? _value.orden
          : orden // ignore: cast_nullable_to_non_nullable
              as int,
      contenido: null == contenido
          ? _value.contenido
          : contenido // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EstrofaImplCopyWith<$Res> implements $EstrofaCopyWith<$Res> {
  factory _$$EstrofaImplCopyWith(
          _$EstrofaImpl value, $Res Function(_$EstrofaImpl) then) =
      __$$EstrofaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int versionPaisId,
      EstrofaTipo tipo,
      int orden,
      String contenido});
}

/// @nodoc
class __$$EstrofaImplCopyWithImpl<$Res>
    extends _$EstrofaCopyWithImpl<$Res, _$EstrofaImpl>
    implements _$$EstrofaImplCopyWith<$Res> {
  __$$EstrofaImplCopyWithImpl(
      _$EstrofaImpl _value, $Res Function(_$EstrofaImpl) _then)
      : super(_value, _then);

  /// Create a copy of Estrofa
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? versionPaisId = null,
    Object? tipo = null,
    Object? orden = null,
    Object? contenido = null,
  }) {
    return _then(_$EstrofaImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      versionPaisId: null == versionPaisId
          ? _value.versionPaisId
          : versionPaisId // ignore: cast_nullable_to_non_nullable
              as int,
      tipo: null == tipo
          ? _value.tipo
          : tipo // ignore: cast_nullable_to_non_nullable
              as EstrofaTipo,
      orden: null == orden
          ? _value.orden
          : orden // ignore: cast_nullable_to_non_nullable
              as int,
      contenido: null == contenido
          ? _value.contenido
          : contenido // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$EstrofaImpl extends _Estrofa {
  const _$EstrofaImpl(
      {required this.id,
      required this.versionPaisId,
      required this.tipo,
      required this.orden,
      required this.contenido})
      : super._();

  @override
  final int id;
  @override
  final int versionPaisId;
  @override
  final EstrofaTipo tipo;
  @override
  final int orden;
  @override
  final String contenido;

  @override
  String toString() {
    return 'Estrofa(id: $id, versionPaisId: $versionPaisId, tipo: $tipo, orden: $orden, contenido: $contenido)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EstrofaImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.versionPaisId, versionPaisId) ||
                other.versionPaisId == versionPaisId) &&
            (identical(other.tipo, tipo) || other.tipo == tipo) &&
            (identical(other.orden, orden) || other.orden == orden) &&
            (identical(other.contenido, contenido) ||
                other.contenido == contenido));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, versionPaisId, tipo, orden, contenido);

  /// Create a copy of Estrofa
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EstrofaImplCopyWith<_$EstrofaImpl> get copyWith =>
      __$$EstrofaImplCopyWithImpl<_$EstrofaImpl>(this, _$identity);
}

abstract class _Estrofa extends Estrofa {
  const factory _Estrofa(
      {required final int id,
      required final int versionPaisId,
      required final EstrofaTipo tipo,
      required final int orden,
      required final String contenido}) = _$EstrofaImpl;
  const _Estrofa._() : super._();

  @override
  int get id;
  @override
  int get versionPaisId;
  @override
  EstrofaTipo get tipo;
  @override
  int get orden;
  @override
  String get contenido;

  /// Create a copy of Estrofa
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EstrofaImplCopyWith<_$EstrofaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
