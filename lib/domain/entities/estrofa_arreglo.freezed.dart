// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'estrofa_arreglo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$EstrofaArreglo {
  int get id => throw _privateConstructorUsedError;
  int get arregloMusicalId => throw _privateConstructorUsedError;
  EstrofaTipo get tipo => throw _privateConstructorUsedError;
  int get orden => throw _privateConstructorUsedError;
  String get contenido => throw _privateConstructorUsedError;

  /// Create a copy of EstrofaArreglo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EstrofaArregloCopyWith<EstrofaArreglo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EstrofaArregloCopyWith<$Res> {
  factory $EstrofaArregloCopyWith(
          EstrofaArreglo value, $Res Function(EstrofaArreglo) then) =
      _$EstrofaArregloCopyWithImpl<$Res, EstrofaArreglo>;
  @useResult
  $Res call(
      {int id,
      int arregloMusicalId,
      EstrofaTipo tipo,
      int orden,
      String contenido});
}

/// @nodoc
class _$EstrofaArregloCopyWithImpl<$Res, $Val extends EstrofaArreglo>
    implements $EstrofaArregloCopyWith<$Res> {
  _$EstrofaArregloCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EstrofaArreglo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? arregloMusicalId = null,
    Object? tipo = null,
    Object? orden = null,
    Object? contenido = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      arregloMusicalId: null == arregloMusicalId
          ? _value.arregloMusicalId
          : arregloMusicalId // ignore: cast_nullable_to_non_nullable
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
abstract class _$$EstrofaArregloImplCopyWith<$Res>
    implements $EstrofaArregloCopyWith<$Res> {
  factory _$$EstrofaArregloImplCopyWith(_$EstrofaArregloImpl value,
          $Res Function(_$EstrofaArregloImpl) then) =
      __$$EstrofaArregloImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int arregloMusicalId,
      EstrofaTipo tipo,
      int orden,
      String contenido});
}

/// @nodoc
class __$$EstrofaArregloImplCopyWithImpl<$Res>
    extends _$EstrofaArregloCopyWithImpl<$Res, _$EstrofaArregloImpl>
    implements _$$EstrofaArregloImplCopyWith<$Res> {
  __$$EstrofaArregloImplCopyWithImpl(
      _$EstrofaArregloImpl _value, $Res Function(_$EstrofaArregloImpl) _then)
      : super(_value, _then);

  /// Create a copy of EstrofaArreglo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? arregloMusicalId = null,
    Object? tipo = null,
    Object? orden = null,
    Object? contenido = null,
  }) {
    return _then(_$EstrofaArregloImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      arregloMusicalId: null == arregloMusicalId
          ? _value.arregloMusicalId
          : arregloMusicalId // ignore: cast_nullable_to_non_nullable
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

class _$EstrofaArregloImpl implements _EstrofaArreglo {
  const _$EstrofaArregloImpl(
      {required this.id,
      required this.arregloMusicalId,
      required this.tipo,
      required this.orden,
      required this.contenido});

  @override
  final int id;
  @override
  final int arregloMusicalId;
  @override
  final EstrofaTipo tipo;
  @override
  final int orden;
  @override
  final String contenido;

  @override
  String toString() {
    return 'EstrofaArreglo(id: $id, arregloMusicalId: $arregloMusicalId, tipo: $tipo, orden: $orden, contenido: $contenido)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EstrofaArregloImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.arregloMusicalId, arregloMusicalId) ||
                other.arregloMusicalId == arregloMusicalId) &&
            (identical(other.tipo, tipo) || other.tipo == tipo) &&
            (identical(other.orden, orden) || other.orden == orden) &&
            (identical(other.contenido, contenido) ||
                other.contenido == contenido));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, arregloMusicalId, tipo, orden, contenido);

  /// Create a copy of EstrofaArreglo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EstrofaArregloImplCopyWith<_$EstrofaArregloImpl> get copyWith =>
      __$$EstrofaArregloImplCopyWithImpl<_$EstrofaArregloImpl>(
          this, _$identity);
}

abstract class _EstrofaArreglo implements EstrofaArreglo {
  const factory _EstrofaArreglo(
      {required final int id,
      required final int arregloMusicalId,
      required final EstrofaTipo tipo,
      required final int orden,
      required final String contenido}) = _$EstrofaArregloImpl;

  @override
  int get id;
  @override
  int get arregloMusicalId;
  @override
  EstrofaTipo get tipo;
  @override
  int get orden;
  @override
  String get contenido;

  /// Create a copy of EstrofaArreglo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EstrofaArregloImplCopyWith<_$EstrofaArregloImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
