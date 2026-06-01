// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'projection_slide.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ProjectionSlide {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Himno himno) title,
    required TResult Function(Estrofa estrofa) lyrics,
    required TResult Function() amen,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Himno himno)? title,
    TResult? Function(Estrofa estrofa)? lyrics,
    TResult? Function()? amen,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Himno himno)? title,
    TResult Function(Estrofa estrofa)? lyrics,
    TResult Function()? amen,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TitleSlide value) title,
    required TResult Function(LyricsSlide value) lyrics,
    required TResult Function(AmenSlide value) amen,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TitleSlide value)? title,
    TResult? Function(LyricsSlide value)? lyrics,
    TResult? Function(AmenSlide value)? amen,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TitleSlide value)? title,
    TResult Function(LyricsSlide value)? lyrics,
    TResult Function(AmenSlide value)? amen,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectionSlideCopyWith<$Res> {
  factory $ProjectionSlideCopyWith(
          ProjectionSlide value, $Res Function(ProjectionSlide) then) =
      _$ProjectionSlideCopyWithImpl<$Res, ProjectionSlide>;
}

/// @nodoc
class _$ProjectionSlideCopyWithImpl<$Res, $Val extends ProjectionSlide>
    implements $ProjectionSlideCopyWith<$Res> {
  _$ProjectionSlideCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$TitleSlideImplCopyWith<$Res> {
  factory _$$TitleSlideImplCopyWith(
          _$TitleSlideImpl value, $Res Function(_$TitleSlideImpl) then) =
      __$$TitleSlideImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Himno himno});

  $HimnoCopyWith<$Res> get himno;
}

/// @nodoc
class __$$TitleSlideImplCopyWithImpl<$Res>
    extends _$ProjectionSlideCopyWithImpl<$Res, _$TitleSlideImpl>
    implements _$$TitleSlideImplCopyWith<$Res> {
  __$$TitleSlideImplCopyWithImpl(
      _$TitleSlideImpl _value, $Res Function(_$TitleSlideImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? himno = null,
  }) {
    return _then(_$TitleSlideImpl(
      himno: null == himno
          ? _value.himno
          : himno // ignore: cast_nullable_to_non_nullable
              as Himno,
    ));
  }

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HimnoCopyWith<$Res> get himno {
    return $HimnoCopyWith<$Res>(_value.himno, (value) {
      return _then(_value.copyWith(himno: value));
    });
  }
}

/// @nodoc

class _$TitleSlideImpl extends TitleSlide {
  const _$TitleSlideImpl({required this.himno}) : super._();

  @override
  final Himno himno;

  @override
  String toString() {
    return 'ProjectionSlide.title(himno: $himno)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TitleSlideImpl &&
            (identical(other.himno, himno) || other.himno == himno));
  }

  @override
  int get hashCode => Object.hash(runtimeType, himno);

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TitleSlideImplCopyWith<_$TitleSlideImpl> get copyWith =>
      __$$TitleSlideImplCopyWithImpl<_$TitleSlideImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Himno himno) title,
    required TResult Function(Estrofa estrofa) lyrics,
    required TResult Function() amen,
  }) {
    return title(himno);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Himno himno)? title,
    TResult? Function(Estrofa estrofa)? lyrics,
    TResult? Function()? amen,
  }) {
    return title?.call(himno);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Himno himno)? title,
    TResult Function(Estrofa estrofa)? lyrics,
    TResult Function()? amen,
    required TResult orElse(),
  }) {
    if (title != null) {
      return title(himno);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TitleSlide value) title,
    required TResult Function(LyricsSlide value) lyrics,
    required TResult Function(AmenSlide value) amen,
  }) {
    return title(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TitleSlide value)? title,
    TResult? Function(LyricsSlide value)? lyrics,
    TResult? Function(AmenSlide value)? amen,
  }) {
    return title?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TitleSlide value)? title,
    TResult Function(LyricsSlide value)? lyrics,
    TResult Function(AmenSlide value)? amen,
    required TResult orElse(),
  }) {
    if (title != null) {
      return title(this);
    }
    return orElse();
  }
}

abstract class TitleSlide extends ProjectionSlide {
  const factory TitleSlide({required final Himno himno}) = _$TitleSlideImpl;
  const TitleSlide._() : super._();

  Himno get himno;

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TitleSlideImplCopyWith<_$TitleSlideImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LyricsSlideImplCopyWith<$Res> {
  factory _$$LyricsSlideImplCopyWith(
          _$LyricsSlideImpl value, $Res Function(_$LyricsSlideImpl) then) =
      __$$LyricsSlideImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Estrofa estrofa});

  $EstrofaCopyWith<$Res> get estrofa;
}

/// @nodoc
class __$$LyricsSlideImplCopyWithImpl<$Res>
    extends _$ProjectionSlideCopyWithImpl<$Res, _$LyricsSlideImpl>
    implements _$$LyricsSlideImplCopyWith<$Res> {
  __$$LyricsSlideImplCopyWithImpl(
      _$LyricsSlideImpl _value, $Res Function(_$LyricsSlideImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? estrofa = null,
  }) {
    return _then(_$LyricsSlideImpl(
      estrofa: null == estrofa
          ? _value.estrofa
          : estrofa // ignore: cast_nullable_to_non_nullable
              as Estrofa,
    ));
  }

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EstrofaCopyWith<$Res> get estrofa {
    return $EstrofaCopyWith<$Res>(_value.estrofa, (value) {
      return _then(_value.copyWith(estrofa: value));
    });
  }
}

/// @nodoc

class _$LyricsSlideImpl extends LyricsSlide {
  const _$LyricsSlideImpl({required this.estrofa}) : super._();

  @override
  final Estrofa estrofa;

  @override
  String toString() {
    return 'ProjectionSlide.lyrics(estrofa: $estrofa)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LyricsSlideImpl &&
            (identical(other.estrofa, estrofa) || other.estrofa == estrofa));
  }

  @override
  int get hashCode => Object.hash(runtimeType, estrofa);

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LyricsSlideImplCopyWith<_$LyricsSlideImpl> get copyWith =>
      __$$LyricsSlideImplCopyWithImpl<_$LyricsSlideImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Himno himno) title,
    required TResult Function(Estrofa estrofa) lyrics,
    required TResult Function() amen,
  }) {
    return lyrics(estrofa);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Himno himno)? title,
    TResult? Function(Estrofa estrofa)? lyrics,
    TResult? Function()? amen,
  }) {
    return lyrics?.call(estrofa);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Himno himno)? title,
    TResult Function(Estrofa estrofa)? lyrics,
    TResult Function()? amen,
    required TResult orElse(),
  }) {
    if (lyrics != null) {
      return lyrics(estrofa);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TitleSlide value) title,
    required TResult Function(LyricsSlide value) lyrics,
    required TResult Function(AmenSlide value) amen,
  }) {
    return lyrics(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TitleSlide value)? title,
    TResult? Function(LyricsSlide value)? lyrics,
    TResult? Function(AmenSlide value)? amen,
  }) {
    return lyrics?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TitleSlide value)? title,
    TResult Function(LyricsSlide value)? lyrics,
    TResult Function(AmenSlide value)? amen,
    required TResult orElse(),
  }) {
    if (lyrics != null) {
      return lyrics(this);
    }
    return orElse();
  }
}

abstract class LyricsSlide extends ProjectionSlide {
  const factory LyricsSlide({required final Estrofa estrofa}) =
      _$LyricsSlideImpl;
  const LyricsSlide._() : super._();

  Estrofa get estrofa;

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LyricsSlideImplCopyWith<_$LyricsSlideImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AmenSlideImplCopyWith<$Res> {
  factory _$$AmenSlideImplCopyWith(
          _$AmenSlideImpl value, $Res Function(_$AmenSlideImpl) then) =
      __$$AmenSlideImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AmenSlideImplCopyWithImpl<$Res>
    extends _$ProjectionSlideCopyWithImpl<$Res, _$AmenSlideImpl>
    implements _$$AmenSlideImplCopyWith<$Res> {
  __$$AmenSlideImplCopyWithImpl(
      _$AmenSlideImpl _value, $Res Function(_$AmenSlideImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$AmenSlideImpl extends AmenSlide {
  const _$AmenSlideImpl() : super._();

  @override
  String toString() {
    return 'ProjectionSlide.amen()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$AmenSlideImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Himno himno) title,
    required TResult Function(Estrofa estrofa) lyrics,
    required TResult Function() amen,
  }) {
    return amen();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Himno himno)? title,
    TResult? Function(Estrofa estrofa)? lyrics,
    TResult? Function()? amen,
  }) {
    return amen?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Himno himno)? title,
    TResult Function(Estrofa estrofa)? lyrics,
    TResult Function()? amen,
    required TResult orElse(),
  }) {
    if (amen != null) {
      return amen();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TitleSlide value) title,
    required TResult Function(LyricsSlide value) lyrics,
    required TResult Function(AmenSlide value) amen,
  }) {
    return amen(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TitleSlide value)? title,
    TResult? Function(LyricsSlide value)? lyrics,
    TResult? Function(AmenSlide value)? amen,
  }) {
    return amen?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TitleSlide value)? title,
    TResult Function(LyricsSlide value)? lyrics,
    TResult Function(AmenSlide value)? amen,
    required TResult orElse(),
  }) {
    if (amen != null) {
      return amen(this);
    }
    return orElse();
  }
}

abstract class AmenSlide extends ProjectionSlide {
  const factory AmenSlide() = _$AmenSlideImpl;
  const AmenSlide._() : super._();
}
