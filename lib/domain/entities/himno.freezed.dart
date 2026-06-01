// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'himno.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Himno {
  int get id => throw _privateConstructorUsedError;
  String get titulo => throw _privateConstructorUsedError;
  int? get numero => throw _privateConstructorUsedError;
  HimnoTipo get tipo => throw _privateConstructorUsedError;
  bool get activo => throw _privateConstructorUsedError;
  List<VersionPais> get versiones => throw _privateConstructorUsedError;
  List<Categoria>? get categorias => throw _privateConstructorUsedError;

  /// Create a copy of Himno
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HimnoCopyWith<Himno> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HimnoCopyWith<$Res> {
  factory $HimnoCopyWith(Himno value, $Res Function(Himno) then) =
      _$HimnoCopyWithImpl<$Res, Himno>;
  @useResult
  $Res call(
      {int id,
      String titulo,
      int? numero,
      HimnoTipo tipo,
      bool activo,
      List<VersionPais> versiones,
      List<Categoria>? categorias});
}

/// @nodoc
class _$HimnoCopyWithImpl<$Res, $Val extends Himno>
    implements $HimnoCopyWith<$Res> {
  _$HimnoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Himno
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? titulo = null,
    Object? numero = freezed,
    Object? tipo = null,
    Object? activo = null,
    Object? versiones = null,
    Object? categorias = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      titulo: null == titulo
          ? _value.titulo
          : titulo // ignore: cast_nullable_to_non_nullable
              as String,
      numero: freezed == numero
          ? _value.numero
          : numero // ignore: cast_nullable_to_non_nullable
              as int?,
      tipo: null == tipo
          ? _value.tipo
          : tipo // ignore: cast_nullable_to_non_nullable
              as HimnoTipo,
      activo: null == activo
          ? _value.activo
          : activo // ignore: cast_nullable_to_non_nullable
              as bool,
      versiones: null == versiones
          ? _value.versiones
          : versiones // ignore: cast_nullable_to_non_nullable
              as List<VersionPais>,
      categorias: freezed == categorias
          ? _value.categorias
          : categorias // ignore: cast_nullable_to_non_nullable
              as List<Categoria>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HimnoImplCopyWith<$Res> implements $HimnoCopyWith<$Res> {
  factory _$$HimnoImplCopyWith(
          _$HimnoImpl value, $Res Function(_$HimnoImpl) then) =
      __$$HimnoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String titulo,
      int? numero,
      HimnoTipo tipo,
      bool activo,
      List<VersionPais> versiones,
      List<Categoria>? categorias});
}

/// @nodoc
class __$$HimnoImplCopyWithImpl<$Res>
    extends _$HimnoCopyWithImpl<$Res, _$HimnoImpl>
    implements _$$HimnoImplCopyWith<$Res> {
  __$$HimnoImplCopyWithImpl(
      _$HimnoImpl _value, $Res Function(_$HimnoImpl) _then)
      : super(_value, _then);

  /// Create a copy of Himno
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? titulo = null,
    Object? numero = freezed,
    Object? tipo = null,
    Object? activo = null,
    Object? versiones = null,
    Object? categorias = freezed,
  }) {
    return _then(_$HimnoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      titulo: null == titulo
          ? _value.titulo
          : titulo // ignore: cast_nullable_to_non_nullable
              as String,
      numero: freezed == numero
          ? _value.numero
          : numero // ignore: cast_nullable_to_non_nullable
              as int?,
      tipo: null == tipo
          ? _value.tipo
          : tipo // ignore: cast_nullable_to_non_nullable
              as HimnoTipo,
      activo: null == activo
          ? _value.activo
          : activo // ignore: cast_nullable_to_non_nullable
              as bool,
      versiones: null == versiones
          ? _value._versiones
          : versiones // ignore: cast_nullable_to_non_nullable
              as List<VersionPais>,
      categorias: freezed == categorias
          ? _value._categorias
          : categorias // ignore: cast_nullable_to_non_nullable
              as List<Categoria>?,
    ));
  }
}

/// @nodoc

class _$HimnoImpl extends _Himno {
  const _$HimnoImpl(
      {required this.id,
      required this.titulo,
      this.numero,
      required this.tipo,
      this.activo = true,
      final List<VersionPais> versiones = const [],
      final List<Categoria>? categorias = const []})
      : _versiones = versiones,
        _categorias = categorias,
        super._();

  @override
  final int id;
  @override
  final String titulo;
  @override
  final int? numero;
  @override
  final HimnoTipo tipo;
  @override
  @JsonKey()
  final bool activo;
  final List<VersionPais> _versiones;
  @override
  @JsonKey()
  List<VersionPais> get versiones {
    if (_versiones is EqualUnmodifiableListView) return _versiones;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_versiones);
  }

  final List<Categoria>? _categorias;
  @override
  @JsonKey()
  List<Categoria>? get categorias {
    final value = _categorias;
    if (value == null) return null;
    if (_categorias is EqualUnmodifiableListView) return _categorias;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'Himno(id: $id, titulo: $titulo, numero: $numero, tipo: $tipo, activo: $activo, versiones: $versiones, categorias: $categorias)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HimnoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.titulo, titulo) || other.titulo == titulo) &&
            (identical(other.numero, numero) || other.numero == numero) &&
            (identical(other.tipo, tipo) || other.tipo == tipo) &&
            (identical(other.activo, activo) || other.activo == activo) &&
            const DeepCollectionEquality()
                .equals(other._versiones, _versiones) &&
            const DeepCollectionEquality()
                .equals(other._categorias, _categorias));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      titulo,
      numero,
      tipo,
      activo,
      const DeepCollectionEquality().hash(_versiones),
      const DeepCollectionEquality().hash(_categorias));

  /// Create a copy of Himno
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HimnoImplCopyWith<_$HimnoImpl> get copyWith =>
      __$$HimnoImplCopyWithImpl<_$HimnoImpl>(this, _$identity);
}

abstract class _Himno extends Himno {
  const factory _Himno(
      {required final int id,
      required final String titulo,
      final int? numero,
      required final HimnoTipo tipo,
      final bool activo,
      final List<VersionPais> versiones,
      final List<Categoria>? categorias}) = _$HimnoImpl;
  const _Himno._() : super._();

  @override
  int get id;
  @override
  String get titulo;
  @override
  int? get numero;
  @override
  HimnoTipo get tipo;
  @override
  bool get activo;
  @override
  List<VersionPais> get versiones;
  @override
  List<Categoria>? get categorias;

  /// Create a copy of Himno
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HimnoImplCopyWith<_$HimnoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
