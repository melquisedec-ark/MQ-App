// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fondo_pantalla.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FondoPantalla {
  int get id => throw _privateConstructorUsedError;
  String get nombre => throw _privateConstructorUsedError;
  FondoPantallaTipo get tipo => throw _privateConstructorUsedError;
  String? get rutaArchivo => throw _privateConstructorUsedError;
  String? get colorHex => throw _privateConstructorUsedError;
  bool get esPredeterminado => throw _privateConstructorUsedError;
  bool get activo => throw _privateConstructorUsedError;

  /// Create a copy of FondoPantalla
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FondoPantallaCopyWith<FondoPantalla> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FondoPantallaCopyWith<$Res> {
  factory $FondoPantallaCopyWith(
          FondoPantalla value, $Res Function(FondoPantalla) then) =
      _$FondoPantallaCopyWithImpl<$Res, FondoPantalla>;
  @useResult
  $Res call(
      {int id,
      String nombre,
      FondoPantallaTipo tipo,
      String? rutaArchivo,
      String? colorHex,
      bool esPredeterminado,
      bool activo});
}

/// @nodoc
class _$FondoPantallaCopyWithImpl<$Res, $Val extends FondoPantalla>
    implements $FondoPantallaCopyWith<$Res> {
  _$FondoPantallaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FondoPantalla
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nombre = null,
    Object? tipo = null,
    Object? rutaArchivo = freezed,
    Object? colorHex = freezed,
    Object? esPredeterminado = null,
    Object? activo = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      nombre: null == nombre
          ? _value.nombre
          : nombre // ignore: cast_nullable_to_non_nullable
              as String,
      tipo: null == tipo
          ? _value.tipo
          : tipo // ignore: cast_nullable_to_non_nullable
              as FondoPantallaTipo,
      rutaArchivo: freezed == rutaArchivo
          ? _value.rutaArchivo
          : rutaArchivo // ignore: cast_nullable_to_non_nullable
              as String?,
      colorHex: freezed == colorHex
          ? _value.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as String?,
      esPredeterminado: null == esPredeterminado
          ? _value.esPredeterminado
          : esPredeterminado // ignore: cast_nullable_to_non_nullable
              as bool,
      activo: null == activo
          ? _value.activo
          : activo // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FondoPantallaImplCopyWith<$Res>
    implements $FondoPantallaCopyWith<$Res> {
  factory _$$FondoPantallaImplCopyWith(
          _$FondoPantallaImpl value, $Res Function(_$FondoPantallaImpl) then) =
      __$$FondoPantallaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String nombre,
      FondoPantallaTipo tipo,
      String? rutaArchivo,
      String? colorHex,
      bool esPredeterminado,
      bool activo});
}

/// @nodoc
class __$$FondoPantallaImplCopyWithImpl<$Res>
    extends _$FondoPantallaCopyWithImpl<$Res, _$FondoPantallaImpl>
    implements _$$FondoPantallaImplCopyWith<$Res> {
  __$$FondoPantallaImplCopyWithImpl(
      _$FondoPantallaImpl _value, $Res Function(_$FondoPantallaImpl) _then)
      : super(_value, _then);

  /// Create a copy of FondoPantalla
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nombre = null,
    Object? tipo = null,
    Object? rutaArchivo = freezed,
    Object? colorHex = freezed,
    Object? esPredeterminado = null,
    Object? activo = null,
  }) {
    return _then(_$FondoPantallaImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      nombre: null == nombre
          ? _value.nombre
          : nombre // ignore: cast_nullable_to_non_nullable
              as String,
      tipo: null == tipo
          ? _value.tipo
          : tipo // ignore: cast_nullable_to_non_nullable
              as FondoPantallaTipo,
      rutaArchivo: freezed == rutaArchivo
          ? _value.rutaArchivo
          : rutaArchivo // ignore: cast_nullable_to_non_nullable
              as String?,
      colorHex: freezed == colorHex
          ? _value.colorHex
          : colorHex // ignore: cast_nullable_to_non_nullable
              as String?,
      esPredeterminado: null == esPredeterminado
          ? _value.esPredeterminado
          : esPredeterminado // ignore: cast_nullable_to_non_nullable
              as bool,
      activo: null == activo
          ? _value.activo
          : activo // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$FondoPantallaImpl implements _FondoPantalla {
  const _$FondoPantallaImpl(
      {required this.id,
      required this.nombre,
      required this.tipo,
      this.rutaArchivo,
      this.colorHex,
      this.esPredeterminado = false,
      this.activo = true});

  @override
  final int id;
  @override
  final String nombre;
  @override
  final FondoPantallaTipo tipo;
  @override
  final String? rutaArchivo;
  @override
  final String? colorHex;
  @override
  @JsonKey()
  final bool esPredeterminado;
  @override
  @JsonKey()
  final bool activo;

  @override
  String toString() {
    return 'FondoPantalla(id: $id, nombre: $nombre, tipo: $tipo, rutaArchivo: $rutaArchivo, colorHex: $colorHex, esPredeterminado: $esPredeterminado, activo: $activo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FondoPantallaImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nombre, nombre) || other.nombre == nombre) &&
            (identical(other.tipo, tipo) || other.tipo == tipo) &&
            (identical(other.rutaArchivo, rutaArchivo) ||
                other.rutaArchivo == rutaArchivo) &&
            (identical(other.colorHex, colorHex) ||
                other.colorHex == colorHex) &&
            (identical(other.esPredeterminado, esPredeterminado) ||
                other.esPredeterminado == esPredeterminado) &&
            (identical(other.activo, activo) || other.activo == activo));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, nombre, tipo, rutaArchivo,
      colorHex, esPredeterminado, activo);

  /// Create a copy of FondoPantalla
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FondoPantallaImplCopyWith<_$FondoPantallaImpl> get copyWith =>
      __$$FondoPantallaImplCopyWithImpl<_$FondoPantallaImpl>(this, _$identity);
}

abstract class _FondoPantalla implements FondoPantalla {
  const factory _FondoPantalla(
      {required final int id,
      required final String nombre,
      required final FondoPantallaTipo tipo,
      final String? rutaArchivo,
      final String? colorHex,
      final bool esPredeterminado,
      final bool activo}) = _$FondoPantallaImpl;

  @override
  int get id;
  @override
  String get nombre;
  @override
  FondoPantallaTipo get tipo;
  @override
  String? get rutaArchivo;
  @override
  String? get colorHex;
  @override
  bool get esPredeterminado;
  @override
  bool get activo;

  /// Create a copy of FondoPantalla
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FondoPantallaImplCopyWith<_$FondoPantallaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
