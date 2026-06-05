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
    required TResult Function(String libroNombre, int capitulo) bibleTitle,
    required TResult Function(
            int numero, String texto, String referencia, int totalVersiculos)
        verse,
    required TResult Function(String libroNombre, int capitulo) bibleEnd,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Himno himno)? title,
    TResult? Function(Estrofa estrofa)? lyrics,
    TResult? Function()? amen,
    TResult? Function(String libroNombre, int capitulo)? bibleTitle,
    TResult? Function(
            int numero, String texto, String referencia, int totalVersiculos)?
        verse,
    TResult? Function(String libroNombre, int capitulo)? bibleEnd,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Himno himno)? title,
    TResult Function(Estrofa estrofa)? lyrics,
    TResult Function()? amen,
    TResult Function(String libroNombre, int capitulo)? bibleTitle,
    TResult Function(
            int numero, String texto, String referencia, int totalVersiculos)?
        verse,
    TResult Function(String libroNombre, int capitulo)? bibleEnd,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TitleSlide value) title,
    required TResult Function(LyricsSlide value) lyrics,
    required TResult Function(AmenSlide value) amen,
    required TResult Function(BibleTitleSlide value) bibleTitle,
    required TResult Function(VerseSlide value) verse,
    required TResult Function(BibleEndSlide value) bibleEnd,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TitleSlide value)? title,
    TResult? Function(LyricsSlide value)? lyrics,
    TResult? Function(AmenSlide value)? amen,
    TResult? Function(BibleTitleSlide value)? bibleTitle,
    TResult? Function(VerseSlide value)? verse,
    TResult? Function(BibleEndSlide value)? bibleEnd,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TitleSlide value)? title,
    TResult Function(LyricsSlide value)? lyrics,
    TResult Function(AmenSlide value)? amen,
    TResult Function(BibleTitleSlide value)? bibleTitle,
    TResult Function(VerseSlide value)? verse,
    TResult Function(BibleEndSlide value)? bibleEnd,
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
    required TResult Function(String libroNombre, int capitulo) bibleTitle,
    required TResult Function(
            int numero, String texto, String referencia, int totalVersiculos)
        verse,
    required TResult Function(String libroNombre, int capitulo) bibleEnd,
  }) {
    return title(himno);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Himno himno)? title,
    TResult? Function(Estrofa estrofa)? lyrics,
    TResult? Function()? amen,
    TResult? Function(String libroNombre, int capitulo)? bibleTitle,
    TResult? Function(
            int numero, String texto, String referencia, int totalVersiculos)?
        verse,
    TResult? Function(String libroNombre, int capitulo)? bibleEnd,
  }) {
    return title?.call(himno);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Himno himno)? title,
    TResult Function(Estrofa estrofa)? lyrics,
    TResult Function()? amen,
    TResult Function(String libroNombre, int capitulo)? bibleTitle,
    TResult Function(
            int numero, String texto, String referencia, int totalVersiculos)?
        verse,
    TResult Function(String libroNombre, int capitulo)? bibleEnd,
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
    required TResult Function(BibleTitleSlide value) bibleTitle,
    required TResult Function(VerseSlide value) verse,
    required TResult Function(BibleEndSlide value) bibleEnd,
  }) {
    return title(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TitleSlide value)? title,
    TResult? Function(LyricsSlide value)? lyrics,
    TResult? Function(AmenSlide value)? amen,
    TResult? Function(BibleTitleSlide value)? bibleTitle,
    TResult? Function(VerseSlide value)? verse,
    TResult? Function(BibleEndSlide value)? bibleEnd,
  }) {
    return title?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TitleSlide value)? title,
    TResult Function(LyricsSlide value)? lyrics,
    TResult Function(AmenSlide value)? amen,
    TResult Function(BibleTitleSlide value)? bibleTitle,
    TResult Function(VerseSlide value)? verse,
    TResult Function(BibleEndSlide value)? bibleEnd,
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
    required TResult Function(String libroNombre, int capitulo) bibleTitle,
    required TResult Function(
            int numero, String texto, String referencia, int totalVersiculos)
        verse,
    required TResult Function(String libroNombre, int capitulo) bibleEnd,
  }) {
    return lyrics(estrofa);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Himno himno)? title,
    TResult? Function(Estrofa estrofa)? lyrics,
    TResult? Function()? amen,
    TResult? Function(String libroNombre, int capitulo)? bibleTitle,
    TResult? Function(
            int numero, String texto, String referencia, int totalVersiculos)?
        verse,
    TResult? Function(String libroNombre, int capitulo)? bibleEnd,
  }) {
    return lyrics?.call(estrofa);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Himno himno)? title,
    TResult Function(Estrofa estrofa)? lyrics,
    TResult Function()? amen,
    TResult Function(String libroNombre, int capitulo)? bibleTitle,
    TResult Function(
            int numero, String texto, String referencia, int totalVersiculos)?
        verse,
    TResult Function(String libroNombre, int capitulo)? bibleEnd,
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
    required TResult Function(BibleTitleSlide value) bibleTitle,
    required TResult Function(VerseSlide value) verse,
    required TResult Function(BibleEndSlide value) bibleEnd,
  }) {
    return lyrics(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TitleSlide value)? title,
    TResult? Function(LyricsSlide value)? lyrics,
    TResult? Function(AmenSlide value)? amen,
    TResult? Function(BibleTitleSlide value)? bibleTitle,
    TResult? Function(VerseSlide value)? verse,
    TResult? Function(BibleEndSlide value)? bibleEnd,
  }) {
    return lyrics?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TitleSlide value)? title,
    TResult Function(LyricsSlide value)? lyrics,
    TResult Function(AmenSlide value)? amen,
    TResult Function(BibleTitleSlide value)? bibleTitle,
    TResult Function(VerseSlide value)? verse,
    TResult Function(BibleEndSlide value)? bibleEnd,
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
    required TResult Function(String libroNombre, int capitulo) bibleTitle,
    required TResult Function(
            int numero, String texto, String referencia, int totalVersiculos)
        verse,
    required TResult Function(String libroNombre, int capitulo) bibleEnd,
  }) {
    return amen();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Himno himno)? title,
    TResult? Function(Estrofa estrofa)? lyrics,
    TResult? Function()? amen,
    TResult? Function(String libroNombre, int capitulo)? bibleTitle,
    TResult? Function(
            int numero, String texto, String referencia, int totalVersiculos)?
        verse,
    TResult? Function(String libroNombre, int capitulo)? bibleEnd,
  }) {
    return amen?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Himno himno)? title,
    TResult Function(Estrofa estrofa)? lyrics,
    TResult Function()? amen,
    TResult Function(String libroNombre, int capitulo)? bibleTitle,
    TResult Function(
            int numero, String texto, String referencia, int totalVersiculos)?
        verse,
    TResult Function(String libroNombre, int capitulo)? bibleEnd,
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
    required TResult Function(BibleTitleSlide value) bibleTitle,
    required TResult Function(VerseSlide value) verse,
    required TResult Function(BibleEndSlide value) bibleEnd,
  }) {
    return amen(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TitleSlide value)? title,
    TResult? Function(LyricsSlide value)? lyrics,
    TResult? Function(AmenSlide value)? amen,
    TResult? Function(BibleTitleSlide value)? bibleTitle,
    TResult? Function(VerseSlide value)? verse,
    TResult? Function(BibleEndSlide value)? bibleEnd,
  }) {
    return amen?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TitleSlide value)? title,
    TResult Function(LyricsSlide value)? lyrics,
    TResult Function(AmenSlide value)? amen,
    TResult Function(BibleTitleSlide value)? bibleTitle,
    TResult Function(VerseSlide value)? verse,
    TResult Function(BibleEndSlide value)? bibleEnd,
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

/// @nodoc
abstract class _$$BibleTitleSlideImplCopyWith<$Res> {
  factory _$$BibleTitleSlideImplCopyWith(_$BibleTitleSlideImpl value,
          $Res Function(_$BibleTitleSlideImpl) then) =
      __$$BibleTitleSlideImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String libroNombre, int capitulo});
}

/// @nodoc
class __$$BibleTitleSlideImplCopyWithImpl<$Res>
    extends _$ProjectionSlideCopyWithImpl<$Res, _$BibleTitleSlideImpl>
    implements _$$BibleTitleSlideImplCopyWith<$Res> {
  __$$BibleTitleSlideImplCopyWithImpl(
      _$BibleTitleSlideImpl _value, $Res Function(_$BibleTitleSlideImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? libroNombre = null,
    Object? capitulo = null,
  }) {
    return _then(_$BibleTitleSlideImpl(
      libroNombre: null == libroNombre
          ? _value.libroNombre
          : libroNombre // ignore: cast_nullable_to_non_nullable
              as String,
      capitulo: null == capitulo
          ? _value.capitulo
          : capitulo // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$BibleTitleSlideImpl extends BibleTitleSlide {
  const _$BibleTitleSlideImpl(
      {required this.libroNombre, required this.capitulo})
      : super._();

  @override
  final String libroNombre;
  @override
  final int capitulo;

  @override
  String toString() {
    return 'ProjectionSlide.bibleTitle(libroNombre: $libroNombre, capitulo: $capitulo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BibleTitleSlideImpl &&
            (identical(other.libroNombre, libroNombre) ||
                other.libroNombre == libroNombre) &&
            (identical(other.capitulo, capitulo) ||
                other.capitulo == capitulo));
  }

  @override
  int get hashCode => Object.hash(runtimeType, libroNombre, capitulo);

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BibleTitleSlideImplCopyWith<_$BibleTitleSlideImpl> get copyWith =>
      __$$BibleTitleSlideImplCopyWithImpl<_$BibleTitleSlideImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Himno himno) title,
    required TResult Function(Estrofa estrofa) lyrics,
    required TResult Function() amen,
    required TResult Function(String libroNombre, int capitulo) bibleTitle,
    required TResult Function(
            int numero, String texto, String referencia, int totalVersiculos)
        verse,
    required TResult Function(String libroNombre, int capitulo) bibleEnd,
  }) {
    return bibleTitle(libroNombre, capitulo);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Himno himno)? title,
    TResult? Function(Estrofa estrofa)? lyrics,
    TResult? Function()? amen,
    TResult? Function(String libroNombre, int capitulo)? bibleTitle,
    TResult? Function(
            int numero, String texto, String referencia, int totalVersiculos)?
        verse,
    TResult? Function(String libroNombre, int capitulo)? bibleEnd,
  }) {
    return bibleTitle?.call(libroNombre, capitulo);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Himno himno)? title,
    TResult Function(Estrofa estrofa)? lyrics,
    TResult Function()? amen,
    TResult Function(String libroNombre, int capitulo)? bibleTitle,
    TResult Function(
            int numero, String texto, String referencia, int totalVersiculos)?
        verse,
    TResult Function(String libroNombre, int capitulo)? bibleEnd,
    required TResult orElse(),
  }) {
    if (bibleTitle != null) {
      return bibleTitle(libroNombre, capitulo);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TitleSlide value) title,
    required TResult Function(LyricsSlide value) lyrics,
    required TResult Function(AmenSlide value) amen,
    required TResult Function(BibleTitleSlide value) bibleTitle,
    required TResult Function(VerseSlide value) verse,
    required TResult Function(BibleEndSlide value) bibleEnd,
  }) {
    return bibleTitle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TitleSlide value)? title,
    TResult? Function(LyricsSlide value)? lyrics,
    TResult? Function(AmenSlide value)? amen,
    TResult? Function(BibleTitleSlide value)? bibleTitle,
    TResult? Function(VerseSlide value)? verse,
    TResult? Function(BibleEndSlide value)? bibleEnd,
  }) {
    return bibleTitle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TitleSlide value)? title,
    TResult Function(LyricsSlide value)? lyrics,
    TResult Function(AmenSlide value)? amen,
    TResult Function(BibleTitleSlide value)? bibleTitle,
    TResult Function(VerseSlide value)? verse,
    TResult Function(BibleEndSlide value)? bibleEnd,
    required TResult orElse(),
  }) {
    if (bibleTitle != null) {
      return bibleTitle(this);
    }
    return orElse();
  }
}

abstract class BibleTitleSlide extends ProjectionSlide {
  const factory BibleTitleSlide(
      {required final String libroNombre,
      required final int capitulo}) = _$BibleTitleSlideImpl;
  const BibleTitleSlide._() : super._();

  String get libroNombre;
  int get capitulo;

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BibleTitleSlideImplCopyWith<_$BibleTitleSlideImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VerseSlideImplCopyWith<$Res> {
  factory _$$VerseSlideImplCopyWith(
          _$VerseSlideImpl value, $Res Function(_$VerseSlideImpl) then) =
      __$$VerseSlideImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int numero, String texto, String referencia, int totalVersiculos});
}

/// @nodoc
class __$$VerseSlideImplCopyWithImpl<$Res>
    extends _$ProjectionSlideCopyWithImpl<$Res, _$VerseSlideImpl>
    implements _$$VerseSlideImplCopyWith<$Res> {
  __$$VerseSlideImplCopyWithImpl(
      _$VerseSlideImpl _value, $Res Function(_$VerseSlideImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? numero = null,
    Object? texto = null,
    Object? referencia = null,
    Object? totalVersiculos = null,
  }) {
    return _then(_$VerseSlideImpl(
      numero: null == numero
          ? _value.numero
          : numero // ignore: cast_nullable_to_non_nullable
              as int,
      texto: null == texto
          ? _value.texto
          : texto // ignore: cast_nullable_to_non_nullable
              as String,
      referencia: null == referencia
          ? _value.referencia
          : referencia // ignore: cast_nullable_to_non_nullable
              as String,
      totalVersiculos: null == totalVersiculos
          ? _value.totalVersiculos
          : totalVersiculos // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$VerseSlideImpl extends VerseSlide {
  const _$VerseSlideImpl(
      {required this.numero,
      required this.texto,
      required this.referencia,
      required this.totalVersiculos})
      : super._();

  @override
  final int numero;
  @override
  final String texto;
  @override
  final String referencia;
  @override
  final int totalVersiculos;

  @override
  String toString() {
    return 'ProjectionSlide.verse(numero: $numero, texto: $texto, referencia: $referencia, totalVersiculos: $totalVersiculos)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VerseSlideImpl &&
            (identical(other.numero, numero) || other.numero == numero) &&
            (identical(other.texto, texto) || other.texto == texto) &&
            (identical(other.referencia, referencia) ||
                other.referencia == referencia) &&
            (identical(other.totalVersiculos, totalVersiculos) ||
                other.totalVersiculos == totalVersiculos));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, numero, texto, referencia, totalVersiculos);

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VerseSlideImplCopyWith<_$VerseSlideImpl> get copyWith =>
      __$$VerseSlideImplCopyWithImpl<_$VerseSlideImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Himno himno) title,
    required TResult Function(Estrofa estrofa) lyrics,
    required TResult Function() amen,
    required TResult Function(String libroNombre, int capitulo) bibleTitle,
    required TResult Function(
            int numero, String texto, String referencia, int totalVersiculos)
        verse,
    required TResult Function(String libroNombre, int capitulo) bibleEnd,
  }) {
    return verse(numero, texto, referencia, totalVersiculos);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Himno himno)? title,
    TResult? Function(Estrofa estrofa)? lyrics,
    TResult? Function()? amen,
    TResult? Function(String libroNombre, int capitulo)? bibleTitle,
    TResult? Function(
            int numero, String texto, String referencia, int totalVersiculos)?
        verse,
    TResult? Function(String libroNombre, int capitulo)? bibleEnd,
  }) {
    return verse?.call(numero, texto, referencia, totalVersiculos);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Himno himno)? title,
    TResult Function(Estrofa estrofa)? lyrics,
    TResult Function()? amen,
    TResult Function(String libroNombre, int capitulo)? bibleTitle,
    TResult Function(
            int numero, String texto, String referencia, int totalVersiculos)?
        verse,
    TResult Function(String libroNombre, int capitulo)? bibleEnd,
    required TResult orElse(),
  }) {
    if (verse != null) {
      return verse(numero, texto, referencia, totalVersiculos);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TitleSlide value) title,
    required TResult Function(LyricsSlide value) lyrics,
    required TResult Function(AmenSlide value) amen,
    required TResult Function(BibleTitleSlide value) bibleTitle,
    required TResult Function(VerseSlide value) verse,
    required TResult Function(BibleEndSlide value) bibleEnd,
  }) {
    return verse(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TitleSlide value)? title,
    TResult? Function(LyricsSlide value)? lyrics,
    TResult? Function(AmenSlide value)? amen,
    TResult? Function(BibleTitleSlide value)? bibleTitle,
    TResult? Function(VerseSlide value)? verse,
    TResult? Function(BibleEndSlide value)? bibleEnd,
  }) {
    return verse?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TitleSlide value)? title,
    TResult Function(LyricsSlide value)? lyrics,
    TResult Function(AmenSlide value)? amen,
    TResult Function(BibleTitleSlide value)? bibleTitle,
    TResult Function(VerseSlide value)? verse,
    TResult Function(BibleEndSlide value)? bibleEnd,
    required TResult orElse(),
  }) {
    if (verse != null) {
      return verse(this);
    }
    return orElse();
  }
}

abstract class VerseSlide extends ProjectionSlide {
  const factory VerseSlide(
      {required final int numero,
      required final String texto,
      required final String referencia,
      required final int totalVersiculos}) = _$VerseSlideImpl;
  const VerseSlide._() : super._();

  int get numero;
  String get texto;
  String get referencia;
  int get totalVersiculos;

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VerseSlideImplCopyWith<_$VerseSlideImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$BibleEndSlideImplCopyWith<$Res> {
  factory _$$BibleEndSlideImplCopyWith(
          _$BibleEndSlideImpl value, $Res Function(_$BibleEndSlideImpl) then) =
      __$$BibleEndSlideImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String libroNombre, int capitulo});
}

/// @nodoc
class __$$BibleEndSlideImplCopyWithImpl<$Res>
    extends _$ProjectionSlideCopyWithImpl<$Res, _$BibleEndSlideImpl>
    implements _$$BibleEndSlideImplCopyWith<$Res> {
  __$$BibleEndSlideImplCopyWithImpl(
      _$BibleEndSlideImpl _value, $Res Function(_$BibleEndSlideImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? libroNombre = null,
    Object? capitulo = null,
  }) {
    return _then(_$BibleEndSlideImpl(
      libroNombre: null == libroNombre
          ? _value.libroNombre
          : libroNombre // ignore: cast_nullable_to_non_nullable
              as String,
      capitulo: null == capitulo
          ? _value.capitulo
          : capitulo // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$BibleEndSlideImpl extends BibleEndSlide {
  const _$BibleEndSlideImpl({required this.libroNombre, required this.capitulo})
      : super._();

  @override
  final String libroNombre;
  @override
  final int capitulo;

  @override
  String toString() {
    return 'ProjectionSlide.bibleEnd(libroNombre: $libroNombre, capitulo: $capitulo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BibleEndSlideImpl &&
            (identical(other.libroNombre, libroNombre) ||
                other.libroNombre == libroNombre) &&
            (identical(other.capitulo, capitulo) ||
                other.capitulo == capitulo));
  }

  @override
  int get hashCode => Object.hash(runtimeType, libroNombre, capitulo);

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BibleEndSlideImplCopyWith<_$BibleEndSlideImpl> get copyWith =>
      __$$BibleEndSlideImplCopyWithImpl<_$BibleEndSlideImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Himno himno) title,
    required TResult Function(Estrofa estrofa) lyrics,
    required TResult Function() amen,
    required TResult Function(String libroNombre, int capitulo) bibleTitle,
    required TResult Function(
            int numero, String texto, String referencia, int totalVersiculos)
        verse,
    required TResult Function(String libroNombre, int capitulo) bibleEnd,
  }) {
    return bibleEnd(libroNombre, capitulo);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Himno himno)? title,
    TResult? Function(Estrofa estrofa)? lyrics,
    TResult? Function()? amen,
    TResult? Function(String libroNombre, int capitulo)? bibleTitle,
    TResult? Function(
            int numero, String texto, String referencia, int totalVersiculos)?
        verse,
    TResult? Function(String libroNombre, int capitulo)? bibleEnd,
  }) {
    return bibleEnd?.call(libroNombre, capitulo);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Himno himno)? title,
    TResult Function(Estrofa estrofa)? lyrics,
    TResult Function()? amen,
    TResult Function(String libroNombre, int capitulo)? bibleTitle,
    TResult Function(
            int numero, String texto, String referencia, int totalVersiculos)?
        verse,
    TResult Function(String libroNombre, int capitulo)? bibleEnd,
    required TResult orElse(),
  }) {
    if (bibleEnd != null) {
      return bibleEnd(libroNombre, capitulo);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TitleSlide value) title,
    required TResult Function(LyricsSlide value) lyrics,
    required TResult Function(AmenSlide value) amen,
    required TResult Function(BibleTitleSlide value) bibleTitle,
    required TResult Function(VerseSlide value) verse,
    required TResult Function(BibleEndSlide value) bibleEnd,
  }) {
    return bibleEnd(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TitleSlide value)? title,
    TResult? Function(LyricsSlide value)? lyrics,
    TResult? Function(AmenSlide value)? amen,
    TResult? Function(BibleTitleSlide value)? bibleTitle,
    TResult? Function(VerseSlide value)? verse,
    TResult? Function(BibleEndSlide value)? bibleEnd,
  }) {
    return bibleEnd?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TitleSlide value)? title,
    TResult Function(LyricsSlide value)? lyrics,
    TResult Function(AmenSlide value)? amen,
    TResult Function(BibleTitleSlide value)? bibleTitle,
    TResult Function(VerseSlide value)? verse,
    TResult Function(BibleEndSlide value)? bibleEnd,
    required TResult orElse(),
  }) {
    if (bibleEnd != null) {
      return bibleEnd(this);
    }
    return orElse();
  }
}

abstract class BibleEndSlide extends ProjectionSlide {
  const factory BibleEndSlide(
      {required final String libroNombre,
      required final int capitulo}) = _$BibleEndSlideImpl;
  const BibleEndSlide._() : super._();

  String get libroNombre;
  int get capitulo;

  /// Create a copy of ProjectionSlide
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BibleEndSlideImplCopyWith<_$BibleEndSlideImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
