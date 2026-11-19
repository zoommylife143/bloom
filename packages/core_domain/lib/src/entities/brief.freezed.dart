// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'brief.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScreeningLine {

 String get text; String? get sourceUrl;
/// Create a copy of ScreeningLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScreeningLineCopyWith<ScreeningLine> get copyWith => _$ScreeningLineCopyWithImpl<ScreeningLine>(this as ScreeningLine, _$identity);

  /// Serializes this ScreeningLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ScreeningLine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScreeningLine&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.sourceUrl, _this.sourceUrl) || other.sourceUrl == _this.sourceUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ScreeningLine;
  return Object.hash(runtimeType,_this.text,_this.sourceUrl);
}

@override
String toString() {
  final _this = this as ScreeningLine;
  return 'ScreeningLine(text: ${_this.text}, sourceUrl: ${_this.sourceUrl})';
}


}

/// @nodoc
abstract mixin class $ScreeningLineCopyWith<$Res>  {
  factory $ScreeningLineCopyWith(ScreeningLine value, $Res Function(ScreeningLine) _then) = _$ScreeningLineCopyWithImpl;
@useResult
$Res call({
 String text, String? sourceUrl
});




}
/// @nodoc
class _$ScreeningLineCopyWithImpl<$Res>
    implements $ScreeningLineCopyWith<$Res> {
  _$ScreeningLineCopyWithImpl(this._self, this._then);

  final ScreeningLine _self;
  final $Res Function(ScreeningLine) _then;

/// Create a copy of ScreeningLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? sourceUrl = freezed,}) {
  return _then(ScreeningLine(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScreeningLine].
extension ScreeningLinePatterns on ScreeningLine {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScreeningLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScreeningLine() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScreeningLine value)  $default,){
final _that = this;
switch (_that) {
case _ScreeningLine():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScreeningLine value)?  $default,){
final _that = this;
switch (_that) {
case _ScreeningLine() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  String? sourceUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScreeningLine() when $default != null:
return $default(_that.text,_that.sourceUrl);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  String? sourceUrl)  $default,) {final _that = this;
switch (_that) {
case _ScreeningLine():
return $default(_that.text,_that.sourceUrl);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  String? sourceUrl)?  $default,) {final _that = this;
switch (_that) {
case _ScreeningLine() when $default != null:
return $default(_that.text,_that.sourceUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScreeningLine implements ScreeningLine {
  const _ScreeningLine({required this.text, this.sourceUrl});
  factory _ScreeningLine.fromJson(Map<String, dynamic> json) => _$ScreeningLineFromJson(json);

@override final  String text;
@override final  String? sourceUrl;

/// Create a copy of ScreeningLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScreeningLineCopyWith<_ScreeningLine> get copyWith => __$ScreeningLineCopyWithImpl<_ScreeningLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScreeningLineToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScreeningLine&&(identical(other.text, text) || other.text == text)&&(identical(other.sourceUrl, sourceUrl) || other.sourceUrl == sourceUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,text,sourceUrl);
}

@override
String toString() {
    return 'ScreeningLine(text: $text, sourceUrl: $sourceUrl)';
}


}

/// @nodoc
abstract mixin class _$ScreeningLineCopyWith<$Res> implements $ScreeningLineCopyWith<$Res> {
  factory _$ScreeningLineCopyWith(_ScreeningLine value, $Res Function(_ScreeningLine) _then) = __$ScreeningLineCopyWithImpl;
@override @useResult
$Res call({
 String text, String? sourceUrl
});




}
/// @nodoc
class __$ScreeningLineCopyWithImpl<$Res>
    implements _$ScreeningLineCopyWith<$Res> {
  __$ScreeningLineCopyWithImpl(this._self, this._then);

  final _ScreeningLine _self;
  final $Res Function(_ScreeningLine) _then;

/// Create a copy of ScreeningLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? sourceUrl = freezed,}) {
  return _then(_ScreeningLine(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,sourceUrl: freezed == sourceUrl ? _self.sourceUrl : sourceUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Brief {

 String get subjective; String get objective; String get assessmentConsiderations; String get planConsiderations; List<String> get flags; List<ScreeningLine> get screeningsPossiblyDue; List<String> get suggestedQuestions;
/// Create a copy of Brief
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BriefCopyWith<Brief> get copyWith => _$BriefCopyWithImpl<Brief>(this as Brief, _$identity);

  /// Serializes this Brief to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Brief;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Brief&&(identical(other.subjective, _this.subjective) || other.subjective == _this.subjective)&&(identical(other.objective, _this.objective) || other.objective == _this.objective)&&(identical(other.assessmentConsiderations, _this.assessmentConsiderations) || other.assessmentConsiderations == _this.assessmentConsiderations)&&(identical(other.planConsiderations, _this.planConsiderations) || other.planConsiderations == _this.planConsiderations)&&const DeepCollectionEquality().equals(other.flags, _this.flags)&&const DeepCollectionEquality().equals(other.screeningsPossiblyDue, _this.screeningsPossiblyDue)&&const DeepCollectionEquality().equals(other.suggestedQuestions, _this.suggestedQuestions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Brief;
  return Object.hash(runtimeType,_this.subjective,_this.objective,_this.assessmentConsiderations,_this.planConsiderations,const DeepCollectionEquality().hash(_this.flags),const DeepCollectionEquality().hash(_this.screeningsPossiblyDue),const DeepCollectionEquality().hash(_this.suggestedQuestions));
}

@override
String toString() {
  final _this = this as Brief;
  return 'Brief(subjective: ${_this.subjective}, objective: ${_this.objective}, assessmentConsiderations: ${_this.assessmentConsiderations}, planConsiderations: ${_this.planConsiderations}, flags: ${_this.flags}, screeningsPossiblyDue: ${_this.screeningsPossiblyDue}, suggestedQuestions: ${_this.suggestedQuestions})';
}


}

/// @nodoc
abstract mixin class $BriefCopyWith<$Res>  {
  factory $BriefCopyWith(Brief value, $Res Function(Brief) _then) = _$BriefCopyWithImpl;
@useResult
$Res call({
 String subjective, String objective, String assessmentConsiderations, String planConsiderations, List<String> flags, List<ScreeningLine> screeningsPossiblyDue, List<String> suggestedQuestions
});




}
/// @nodoc
class _$BriefCopyWithImpl<$Res>
    implements $BriefCopyWith<$Res> {
  _$BriefCopyWithImpl(this._self, this._then);

  final Brief _self;
  final $Res Function(Brief) _then;

/// Create a copy of Brief
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subjective = null,Object? objective = null,Object? assessmentConsiderations = null,Object? planConsiderations = null,Object? flags = null,Object? screeningsPossiblyDue = null,Object? suggestedQuestions = null,}) {
  return _then(Brief(
subjective: null == subjective ? _self.subjective : subjective // ignore: cast_nullable_to_non_nullable
as String,objective: null == objective ? _self.objective : objective // ignore: cast_nullable_to_non_nullable
as String,assessmentConsiderations: null == assessmentConsiderations ? _self.assessmentConsiderations : assessmentConsiderations // ignore: cast_nullable_to_non_nullable
as String,planConsiderations: null == planConsiderations ? _self.planConsiderations : planConsiderations // ignore: cast_nullable_to_non_nullable
as String,flags: null == flags ? _self.flags : flags // ignore: cast_nullable_to_non_nullable
as List<String>,screeningsPossiblyDue: null == screeningsPossiblyDue ? _self.screeningsPossiblyDue : screeningsPossiblyDue // ignore: cast_nullable_to_non_nullable
as List<ScreeningLine>,suggestedQuestions: null == suggestedQuestions ? _self.suggestedQuestions : suggestedQuestions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Brief].
extension BriefPatterns on Brief {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Brief value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Brief() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Brief value)  $default,){
final _that = this;
switch (_that) {
case _Brief():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Brief value)?  $default,){
final _that = this;
switch (_that) {
case _Brief() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String subjective,  String objective,  String assessmentConsiderations,  String planConsiderations,  List<String> flags,  List<ScreeningLine> screeningsPossiblyDue,  List<String> suggestedQuestions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Brief() when $default != null:
return $default(_that.subjective,_that.objective,_that.assessmentConsiderations,_that.planConsiderations,_that.flags,_that.screeningsPossiblyDue,_that.suggestedQuestions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String subjective,  String objective,  String assessmentConsiderations,  String planConsiderations,  List<String> flags,  List<ScreeningLine> screeningsPossiblyDue,  List<String> suggestedQuestions)  $default,) {final _that = this;
switch (_that) {
case _Brief():
return $default(_that.subjective,_that.objective,_that.assessmentConsiderations,_that.planConsiderations,_that.flags,_that.screeningsPossiblyDue,_that.suggestedQuestions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String subjective,  String objective,  String assessmentConsiderations,  String planConsiderations,  List<String> flags,  List<ScreeningLine> screeningsPossiblyDue,  List<String> suggestedQuestions)?  $default,) {final _that = this;
switch (_that) {
case _Brief() when $default != null:
return $default(_that.subjective,_that.objective,_that.assessmentConsiderations,_that.planConsiderations,_that.flags,_that.screeningsPossiblyDue,_that.suggestedQuestions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Brief implements Brief {
  const _Brief({required this.subjective, required this.objective, required this.assessmentConsiderations, required this.planConsiderations,  List<String> flags = const <String>[],  List<ScreeningLine> screeningsPossiblyDue = const <ScreeningLine>[],  List<String> suggestedQuestions = const <String>[]}): _flags = flags,_screeningsPossiblyDue = screeningsPossiblyDue,_suggestedQuestions = suggestedQuestions;
  factory _Brief.fromJson(Map<String, dynamic> json) => _$BriefFromJson(json);

@override final  String subjective;
@override final  String objective;
@override final  String assessmentConsiderations;
@override final  String planConsiderations;
 final  List<String> _flags;
@override@JsonKey() List<String> get flags {
  if (_flags is EqualUnmodifiableListView) return _flags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_flags);
}

 final  List<ScreeningLine> _screeningsPossiblyDue;
@override@JsonKey() List<ScreeningLine> get screeningsPossiblyDue {
  if (_screeningsPossiblyDue is EqualUnmodifiableListView) return _screeningsPossiblyDue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_screeningsPossiblyDue);
}

 final  List<String> _suggestedQuestions;
@override@JsonKey() List<String> get suggestedQuestions {
  if (_suggestedQuestions is EqualUnmodifiableListView) return _suggestedQuestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_suggestedQuestions);
}


/// Create a copy of Brief
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BriefCopyWith<_Brief> get copyWith => __$BriefCopyWithImpl<_Brief>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BriefToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Brief&&(identical(other.subjective, subjective) || other.subjective == subjective)&&(identical(other.objective, objective) || other.objective == objective)&&(identical(other.assessmentConsiderations, assessmentConsiderations) || other.assessmentConsiderations == assessmentConsiderations)&&(identical(other.planConsiderations, planConsiderations) || other.planConsiderations == planConsiderations)&&const DeepCollectionEquality().equals(other.flags, _flags)&&const DeepCollectionEquality().equals(other.screeningsPossiblyDue, _screeningsPossiblyDue)&&const DeepCollectionEquality().equals(other.suggestedQuestions, _suggestedQuestions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,subjective,objective,assessmentConsiderations,planConsiderations,const DeepCollectionEquality().hash(_flags),const DeepCollectionEquality().hash(_screeningsPossiblyDue),const DeepCollectionEquality().hash(_suggestedQuestions));
}

@override
String toString() {
    return 'Brief(subjective: $subjective, objective: $objective, assessmentConsiderations: $assessmentConsiderations, planConsiderations: $planConsiderations, flags: $flags, screeningsPossiblyDue: $screeningsPossiblyDue, suggestedQuestions: $suggestedQuestions)';
}


}

/// @nodoc
abstract mixin class _$BriefCopyWith<$Res> implements $BriefCopyWith<$Res> {
  factory _$BriefCopyWith(_Brief value, $Res Function(_Brief) _then) = __$BriefCopyWithImpl;
@override @useResult
$Res call({
 String subjective, String objective, String assessmentConsiderations, String planConsiderations, List<String> flags, List<ScreeningLine> screeningsPossiblyDue, List<String> suggestedQuestions
});




}
/// @nodoc
class __$BriefCopyWithImpl<$Res>
    implements _$BriefCopyWith<$Res> {
  __$BriefCopyWithImpl(this._self, this._then);

  final _Brief _self;
  final $Res Function(_Brief) _then;

/// Create a copy of Brief
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subjective = null,Object? objective = null,Object? assessmentConsiderations = null,Object? planConsiderations = null,Object? flags = null,Object? screeningsPossiblyDue = null,Object? suggestedQuestions = null,}) {
  return _then(_Brief(
subjective: null == subjective ? _self.subjective : subjective // ignore: cast_nullable_to_non_nullable
as String,objective: null == objective ? _self.objective : objective // ignore: cast_nullable_to_non_nullable
as String,assessmentConsiderations: null == assessmentConsiderations ? _self.assessmentConsiderations : assessmentConsiderations // ignore: cast_nullable_to_non_nullable
as String,planConsiderations: null == planConsiderations ? _self.planConsiderations : planConsiderations // ignore: cast_nullable_to_non_nullable
as String,flags: null == flags ? _self._flags : flags // ignore: cast_nullable_to_non_nullable
as List<String>,screeningsPossiblyDue: null == screeningsPossiblyDue ? _self._screeningsPossiblyDue : screeningsPossiblyDue // ignore: cast_nullable_to_non_nullable
as List<ScreeningLine>,suggestedQuestions: null == suggestedQuestions ? _self._suggestedQuestions : suggestedQuestions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$Provenance {

 String get generatedBy; List<String> get evidenceUrls; DateTime? get createdAt; ReviewStatus get reviewStatus; String? get reviewedBy; DateTime? get reviewedAt;/// `model` or `fallback` (deterministic DRAFT, no AI). Null when absent
/// (older servers, read as model) or an unknown value.
@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) BriefSource? get source;
/// Create a copy of Provenance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProvenanceCopyWith<Provenance> get copyWith => _$ProvenanceCopyWithImpl<Provenance>(this as Provenance, _$identity);

  /// Serializes this Provenance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Provenance;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Provenance&&(identical(other.generatedBy, _this.generatedBy) || other.generatedBy == _this.generatedBy)&&const DeepCollectionEquality().equals(other.evidenceUrls, _this.evidenceUrls)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.reviewStatus, _this.reviewStatus) || other.reviewStatus == _this.reviewStatus)&&(identical(other.reviewedBy, _this.reviewedBy) || other.reviewedBy == _this.reviewedBy)&&(identical(other.reviewedAt, _this.reviewedAt) || other.reviewedAt == _this.reviewedAt)&&(identical(other.source, _this.source) || other.source == _this.source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Provenance;
  return Object.hash(runtimeType,_this.generatedBy,const DeepCollectionEquality().hash(_this.evidenceUrls),_this.createdAt,_this.reviewStatus,_this.reviewedBy,_this.reviewedAt,_this.source);
}

@override
String toString() {
  final _this = this as Provenance;
  return 'Provenance(generatedBy: ${_this.generatedBy}, evidenceUrls: ${_this.evidenceUrls}, createdAt: ${_this.createdAt}, reviewStatus: ${_this.reviewStatus}, reviewedBy: ${_this.reviewedBy}, reviewedAt: ${_this.reviewedAt}, source: ${_this.source})';
}


}

/// @nodoc
abstract mixin class $ProvenanceCopyWith<$Res>  {
  factory $ProvenanceCopyWith(Provenance value, $Res Function(Provenance) _then) = _$ProvenanceCopyWithImpl;
@useResult
$Res call({
 String generatedBy, List<String> evidenceUrls, DateTime? createdAt, ReviewStatus reviewStatus, String? reviewedBy, DateTime? reviewedAt,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) BriefSource? source
});




}
/// @nodoc
class _$ProvenanceCopyWithImpl<$Res>
    implements $ProvenanceCopyWith<$Res> {
  _$ProvenanceCopyWithImpl(this._self, this._then);

  final Provenance _self;
  final $Res Function(Provenance) _then;

/// Create a copy of Provenance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? generatedBy = null,Object? evidenceUrls = null,Object? createdAt = freezed,Object? reviewStatus = null,Object? reviewedBy = freezed,Object? reviewedAt = freezed,Object? source = freezed,}) {
  return _then(Provenance(
generatedBy: null == generatedBy ? _self.generatedBy : generatedBy // ignore: cast_nullable_to_non_nullable
as String,evidenceUrls: null == evidenceUrls ? _self.evidenceUrls : evidenceUrls // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewStatus: null == reviewStatus ? _self.reviewStatus : reviewStatus // ignore: cast_nullable_to_non_nullable
as ReviewStatus,reviewedBy: freezed == reviewedBy ? _self.reviewedBy : reviewedBy // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as BriefSource?,
  ));
}

}


/// Adds pattern-matching-related methods to [Provenance].
extension ProvenancePatterns on Provenance {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Provenance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Provenance() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Provenance value)  $default,){
final _that = this;
switch (_that) {
case _Provenance():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Provenance value)?  $default,){
final _that = this;
switch (_that) {
case _Provenance() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String generatedBy,  List<String> evidenceUrls,  DateTime? createdAt,  ReviewStatus reviewStatus,  String? reviewedBy,  DateTime? reviewedAt, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  BriefSource? source)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Provenance() when $default != null:
return $default(_that.generatedBy,_that.evidenceUrls,_that.createdAt,_that.reviewStatus,_that.reviewedBy,_that.reviewedAt,_that.source);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String generatedBy,  List<String> evidenceUrls,  DateTime? createdAt,  ReviewStatus reviewStatus,  String? reviewedBy,  DateTime? reviewedAt, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  BriefSource? source)  $default,) {final _that = this;
switch (_that) {
case _Provenance():
return $default(_that.generatedBy,_that.evidenceUrls,_that.createdAt,_that.reviewStatus,_that.reviewedBy,_that.reviewedAt,_that.source);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String generatedBy,  List<String> evidenceUrls,  DateTime? createdAt,  ReviewStatus reviewStatus,  String? reviewedBy,  DateTime? reviewedAt, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  BriefSource? source)?  $default,) {final _that = this;
switch (_that) {
case _Provenance() when $default != null:
return $default(_that.generatedBy,_that.evidenceUrls,_that.createdAt,_that.reviewStatus,_that.reviewedBy,_that.reviewedAt,_that.source);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Provenance implements Provenance {
  const _Provenance({required this.generatedBy,  List<String> evidenceUrls = const <String>[], this.createdAt, this.reviewStatus = ReviewStatus.draft, this.reviewedBy, this.reviewedAt, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.source}): _evidenceUrls = evidenceUrls;
  factory _Provenance.fromJson(Map<String, dynamic> json) => _$ProvenanceFromJson(json);

@override final  String generatedBy;
 final  List<String> _evidenceUrls;
@override@JsonKey() List<String> get evidenceUrls {
  if (_evidenceUrls is EqualUnmodifiableListView) return _evidenceUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_evidenceUrls);
}

@override final  DateTime? createdAt;
@override@JsonKey() final  ReviewStatus reviewStatus;
@override final  String? reviewedBy;
@override final  DateTime? reviewedAt;
/// `model` or `fallback` (deterministic DRAFT, no AI). Null when absent
/// (older servers, read as model) or an unknown value.
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  BriefSource? source;

/// Create a copy of Provenance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProvenanceCopyWith<_Provenance> get copyWith => __$ProvenanceCopyWithImpl<_Provenance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProvenanceToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Provenance&&(identical(other.generatedBy, generatedBy) || other.generatedBy == generatedBy)&&const DeepCollectionEquality().equals(other.evidenceUrls, _evidenceUrls)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewStatus, reviewStatus) || other.reviewStatus == reviewStatus)&&(identical(other.reviewedBy, reviewedBy) || other.reviewedBy == reviewedBy)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,generatedBy,const DeepCollectionEquality().hash(_evidenceUrls),createdAt,reviewStatus,reviewedBy,reviewedAt,source);
}

@override
String toString() {
    return 'Provenance(generatedBy: $generatedBy, evidenceUrls: $evidenceUrls, createdAt: $createdAt, reviewStatus: $reviewStatus, reviewedBy: $reviewedBy, reviewedAt: $reviewedAt, source: $source)';
}


}

/// @nodoc
abstract mixin class _$ProvenanceCopyWith<$Res> implements $ProvenanceCopyWith<$Res> {
  factory _$ProvenanceCopyWith(_Provenance value, $Res Function(_Provenance) _then) = __$ProvenanceCopyWithImpl;
@override @useResult
$Res call({
 String generatedBy, List<String> evidenceUrls, DateTime? createdAt, ReviewStatus reviewStatus, String? reviewedBy, DateTime? reviewedAt,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) BriefSource? source
});




}
/// @nodoc
class __$ProvenanceCopyWithImpl<$Res>
    implements _$ProvenanceCopyWith<$Res> {
  __$ProvenanceCopyWithImpl(this._self, this._then);

  final _Provenance _self;
  final $Res Function(_Provenance) _then;

/// Create a copy of Provenance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? generatedBy = null,Object? evidenceUrls = null,Object? createdAt = freezed,Object? reviewStatus = null,Object? reviewedBy = freezed,Object? reviewedAt = freezed,Object? source = freezed,}) {
  return _then(_Provenance(
generatedBy: null == generatedBy ? _self.generatedBy : generatedBy // ignore: cast_nullable_to_non_nullable
as String,evidenceUrls: null == evidenceUrls ? _self._evidenceUrls : evidenceUrls // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewStatus: null == reviewStatus ? _self.reviewStatus : reviewStatus // ignore: cast_nullable_to_non_nullable
as ReviewStatus,reviewedBy: freezed == reviewedBy ? _self.reviewedBy : reviewedBy // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as BriefSource?,
  ));
}


}


/// @nodoc
mixin _$EvidenceItem {

 String get url; String get query; String? get title; String get passage; DateTime? get retrievedAt;
/// Create a copy of EvidenceItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EvidenceItemCopyWith<EvidenceItem> get copyWith => _$EvidenceItemCopyWithImpl<EvidenceItem>(this as EvidenceItem, _$identity);

  /// Serializes this EvidenceItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EvidenceItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EvidenceItem&&(identical(other.url, _this.url) || other.url == _this.url)&&(identical(other.query, _this.query) || other.query == _this.query)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.passage, _this.passage) || other.passage == _this.passage)&&(identical(other.retrievedAt, _this.retrievedAt) || other.retrievedAt == _this.retrievedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EvidenceItem;
  return Object.hash(runtimeType,_this.url,_this.query,_this.title,_this.passage,_this.retrievedAt);
}

@override
String toString() {
  final _this = this as EvidenceItem;
  return 'EvidenceItem(url: ${_this.url}, query: ${_this.query}, title: ${_this.title}, passage: ${_this.passage}, retrievedAt: ${_this.retrievedAt})';
}


}

/// @nodoc
abstract mixin class $EvidenceItemCopyWith<$Res>  {
  factory $EvidenceItemCopyWith(EvidenceItem value, $Res Function(EvidenceItem) _then) = _$EvidenceItemCopyWithImpl;
@useResult
$Res call({
 String url, String query, String? title, String passage, DateTime? retrievedAt
});




}
/// @nodoc
class _$EvidenceItemCopyWithImpl<$Res>
    implements $EvidenceItemCopyWith<$Res> {
  _$EvidenceItemCopyWithImpl(this._self, this._then);

  final EvidenceItem _self;
  final $Res Function(EvidenceItem) _then;

/// Create a copy of EvidenceItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? query = null,Object? title = freezed,Object? passage = null,Object? retrievedAt = freezed,}) {
  return _then(EvidenceItem(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,passage: null == passage ? _self.passage : passage // ignore: cast_nullable_to_non_nullable
as String,retrievedAt: freezed == retrievedAt ? _self.retrievedAt : retrievedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [EvidenceItem].
extension EvidenceItemPatterns on EvidenceItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EvidenceItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EvidenceItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EvidenceItem value)  $default,){
final _that = this;
switch (_that) {
case _EvidenceItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EvidenceItem value)?  $default,){
final _that = this;
switch (_that) {
case _EvidenceItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String query,  String? title,  String passage,  DateTime? retrievedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EvidenceItem() when $default != null:
return $default(_that.url,_that.query,_that.title,_that.passage,_that.retrievedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String query,  String? title,  String passage,  DateTime? retrievedAt)  $default,) {final _that = this;
switch (_that) {
case _EvidenceItem():
return $default(_that.url,_that.query,_that.title,_that.passage,_that.retrievedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String query,  String? title,  String passage,  DateTime? retrievedAt)?  $default,) {final _that = this;
switch (_that) {
case _EvidenceItem() when $default != null:
return $default(_that.url,_that.query,_that.title,_that.passage,_that.retrievedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EvidenceItem implements EvidenceItem {
  const _EvidenceItem({required this.url, this.query = '', this.title, this.passage = '', this.retrievedAt});
  factory _EvidenceItem.fromJson(Map<String, dynamic> json) => _$EvidenceItemFromJson(json);

@override final  String url;
@override@JsonKey() final  String query;
@override final  String? title;
@override@JsonKey() final  String passage;
@override final  DateTime? retrievedAt;

/// Create a copy of EvidenceItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EvidenceItemCopyWith<_EvidenceItem> get copyWith => __$EvidenceItemCopyWithImpl<_EvidenceItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EvidenceItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EvidenceItem&&(identical(other.url, url) || other.url == url)&&(identical(other.query, query) || other.query == query)&&(identical(other.title, title) || other.title == title)&&(identical(other.passage, passage) || other.passage == passage)&&(identical(other.retrievedAt, retrievedAt) || other.retrievedAt == retrievedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,url,query,title,passage,retrievedAt);
}

@override
String toString() {
    return 'EvidenceItem(url: $url, query: $query, title: $title, passage: $passage, retrievedAt: $retrievedAt)';
}


}

/// @nodoc
abstract mixin class _$EvidenceItemCopyWith<$Res> implements $EvidenceItemCopyWith<$Res> {
  factory _$EvidenceItemCopyWith(_EvidenceItem value, $Res Function(_EvidenceItem) _then) = __$EvidenceItemCopyWithImpl;
@override @useResult
$Res call({
 String url, String query, String? title, String passage, DateTime? retrievedAt
});




}
/// @nodoc
class __$EvidenceItemCopyWithImpl<$Res>
    implements _$EvidenceItemCopyWith<$Res> {
  __$EvidenceItemCopyWithImpl(this._self, this._then);

  final _EvidenceItem _self;
  final $Res Function(_EvidenceItem) _then;

/// Create a copy of EvidenceItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? query = null,Object? title = freezed,Object? passage = null,Object? retrievedAt = freezed,}) {
  return _then(_EvidenceItem(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,passage: null == passage ? _self.passage : passage // ignore: cast_nullable_to_non_nullable
as String,retrievedAt: freezed == retrievedAt ? _self.retrievedAt : retrievedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$BriefBundle {

 String get briefId; String get sessionId;/// What to display: the edited version after an edit, else the draft.
 Brief get brief; Provenance get provenance;/// The AI draft, never overwritten.
 Brief? get originalBrief; bool get edited; List<EvidenceItem> get evidence;/// Optional: cited evidence URLs whose guideline page changed recently
/// (Context.dev Monitor). Absent from older servers.
 List<String> get guidelineUpdates;
/// Create a copy of BriefBundle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BriefBundleCopyWith<BriefBundle> get copyWith => _$BriefBundleCopyWithImpl<BriefBundle>(this as BriefBundle, _$identity);

  /// Serializes this BriefBundle to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BriefBundle;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BriefBundle&&(identical(other.briefId, _this.briefId) || other.briefId == _this.briefId)&&(identical(other.sessionId, _this.sessionId) || other.sessionId == _this.sessionId)&&(identical(other.brief, _this.brief) || other.brief == _this.brief)&&(identical(other.provenance, _this.provenance) || other.provenance == _this.provenance)&&(identical(other.originalBrief, _this.originalBrief) || other.originalBrief == _this.originalBrief)&&(identical(other.edited, _this.edited) || other.edited == _this.edited)&&const DeepCollectionEquality().equals(other.evidence, _this.evidence)&&const DeepCollectionEquality().equals(other.guidelineUpdates, _this.guidelineUpdates));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BriefBundle;
  return Object.hash(runtimeType,_this.briefId,_this.sessionId,_this.brief,_this.provenance,_this.originalBrief,_this.edited,const DeepCollectionEquality().hash(_this.evidence),const DeepCollectionEquality().hash(_this.guidelineUpdates));
}

@override
String toString() {
  final _this = this as BriefBundle;
  return 'BriefBundle(briefId: ${_this.briefId}, sessionId: ${_this.sessionId}, brief: ${_this.brief}, provenance: ${_this.provenance}, originalBrief: ${_this.originalBrief}, edited: ${_this.edited}, evidence: ${_this.evidence}, guidelineUpdates: ${_this.guidelineUpdates})';
}


}

/// @nodoc
abstract mixin class $BriefBundleCopyWith<$Res>  {
  factory $BriefBundleCopyWith(BriefBundle value, $Res Function(BriefBundle) _then) = _$BriefBundleCopyWithImpl;
@useResult
$Res call({
 String briefId, String sessionId, Brief brief, Provenance provenance, Brief? originalBrief, bool edited, List<EvidenceItem> evidence, List<String> guidelineUpdates
});


$BriefCopyWith<$Res> get brief;$ProvenanceCopyWith<$Res> get provenance;$BriefCopyWith<$Res>? get originalBrief;

}
/// @nodoc
class _$BriefBundleCopyWithImpl<$Res>
    implements $BriefBundleCopyWith<$Res> {
  _$BriefBundleCopyWithImpl(this._self, this._then);

  final BriefBundle _self;
  final $Res Function(BriefBundle) _then;

/// Create a copy of BriefBundle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? briefId = null,Object? sessionId = null,Object? brief = null,Object? provenance = null,Object? originalBrief = freezed,Object? edited = null,Object? evidence = null,Object? guidelineUpdates = null,}) {
  return _then(BriefBundle(
briefId: null == briefId ? _self.briefId : briefId // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,brief: null == brief ? _self.brief : brief // ignore: cast_nullable_to_non_nullable
as Brief,provenance: null == provenance ? _self.provenance : provenance // ignore: cast_nullable_to_non_nullable
as Provenance,originalBrief: freezed == originalBrief ? _self.originalBrief : originalBrief // ignore: cast_nullable_to_non_nullable
as Brief?,edited: null == edited ? _self.edited : edited // ignore: cast_nullable_to_non_nullable
as bool,evidence: null == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as List<EvidenceItem>,guidelineUpdates: null == guidelineUpdates ? _self.guidelineUpdates : guidelineUpdates // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of BriefBundle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BriefCopyWith<$Res> get brief {
  
  return $BriefCopyWith<$Res>(_self.brief, (value) {
    return _then(_self.copyWith(brief: value));
  });
}/// Create a copy of BriefBundle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProvenanceCopyWith<$Res> get provenance {
  
  return $ProvenanceCopyWith<$Res>(_self.provenance, (value) {
    return _then(_self.copyWith(provenance: value));
  });
}/// Create a copy of BriefBundle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BriefCopyWith<$Res>? get originalBrief {
    if (_self.originalBrief == null) {
    return null;
  }

  return $BriefCopyWith<$Res>(_self.originalBrief!, (value) {
    return _then(_self.copyWith(originalBrief: value));
  });
}
}


/// Adds pattern-matching-related methods to [BriefBundle].
extension BriefBundlePatterns on BriefBundle {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BriefBundle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BriefBundle() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BriefBundle value)  $default,){
final _that = this;
switch (_that) {
case _BriefBundle():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BriefBundle value)?  $default,){
final _that = this;
switch (_that) {
case _BriefBundle() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String briefId,  String sessionId,  Brief brief,  Provenance provenance,  Brief? originalBrief,  bool edited,  List<EvidenceItem> evidence,  List<String> guidelineUpdates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BriefBundle() when $default != null:
return $default(_that.briefId,_that.sessionId,_that.brief,_that.provenance,_that.originalBrief,_that.edited,_that.evidence,_that.guidelineUpdates);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String briefId,  String sessionId,  Brief brief,  Provenance provenance,  Brief? originalBrief,  bool edited,  List<EvidenceItem> evidence,  List<String> guidelineUpdates)  $default,) {final _that = this;
switch (_that) {
case _BriefBundle():
return $default(_that.briefId,_that.sessionId,_that.brief,_that.provenance,_that.originalBrief,_that.edited,_that.evidence,_that.guidelineUpdates);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String briefId,  String sessionId,  Brief brief,  Provenance provenance,  Brief? originalBrief,  bool edited,  List<EvidenceItem> evidence,  List<String> guidelineUpdates)?  $default,) {final _that = this;
switch (_that) {
case _BriefBundle() when $default != null:
return $default(_that.briefId,_that.sessionId,_that.brief,_that.provenance,_that.originalBrief,_that.edited,_that.evidence,_that.guidelineUpdates);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BriefBundle implements BriefBundle {
  const _BriefBundle({required this.briefId, required this.sessionId, required this.brief, required this.provenance, this.originalBrief, this.edited = false,  List<EvidenceItem> evidence = const <EvidenceItem>[],  List<String> guidelineUpdates = const <String>[]}): _evidence = evidence,_guidelineUpdates = guidelineUpdates;
  factory _BriefBundle.fromJson(Map<String, dynamic> json) => _$BriefBundleFromJson(json);

@override final  String briefId;
@override final  String sessionId;
/// What to display: the edited version after an edit, else the draft.
@override final  Brief brief;
@override final  Provenance provenance;
/// The AI draft, never overwritten.
@override final  Brief? originalBrief;
@override@JsonKey() final  bool edited;
 final  List<EvidenceItem> _evidence;
@override@JsonKey() List<EvidenceItem> get evidence {
  if (_evidence is EqualUnmodifiableListView) return _evidence;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_evidence);
}

/// Optional: cited evidence URLs whose guideline page changed recently
/// (Context.dev Monitor). Absent from older servers.
 final  List<String> _guidelineUpdates;
/// Optional: cited evidence URLs whose guideline page changed recently
/// (Context.dev Monitor). Absent from older servers.
@override@JsonKey() List<String> get guidelineUpdates {
  if (_guidelineUpdates is EqualUnmodifiableListView) return _guidelineUpdates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_guidelineUpdates);
}


/// Create a copy of BriefBundle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BriefBundleCopyWith<_BriefBundle> get copyWith => __$BriefBundleCopyWithImpl<_BriefBundle>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BriefBundleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BriefBundle&&(identical(other.briefId, briefId) || other.briefId == briefId)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.brief, brief) || other.brief == brief)&&(identical(other.provenance, provenance) || other.provenance == provenance)&&(identical(other.originalBrief, originalBrief) || other.originalBrief == originalBrief)&&(identical(other.edited, edited) || other.edited == edited)&&const DeepCollectionEquality().equals(other.evidence, _evidence)&&const DeepCollectionEquality().equals(other.guidelineUpdates, _guidelineUpdates));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,briefId,sessionId,brief,provenance,originalBrief,edited,const DeepCollectionEquality().hash(_evidence),const DeepCollectionEquality().hash(_guidelineUpdates));
}

@override
String toString() {
    return 'BriefBundle(briefId: $briefId, sessionId: $sessionId, brief: $brief, provenance: $provenance, originalBrief: $originalBrief, edited: $edited, evidence: $evidence, guidelineUpdates: $guidelineUpdates)';
}


}

/// @nodoc
abstract mixin class _$BriefBundleCopyWith<$Res> implements $BriefBundleCopyWith<$Res> {
  factory _$BriefBundleCopyWith(_BriefBundle value, $Res Function(_BriefBundle) _then) = __$BriefBundleCopyWithImpl;
@override @useResult
$Res call({
 String briefId, String sessionId, Brief brief, Provenance provenance, Brief? originalBrief, bool edited, List<EvidenceItem> evidence, List<String> guidelineUpdates
});


@override $BriefCopyWith<$Res> get brief;@override $ProvenanceCopyWith<$Res> get provenance;@override $BriefCopyWith<$Res>? get originalBrief;

}
/// @nodoc
class __$BriefBundleCopyWithImpl<$Res>
    implements _$BriefBundleCopyWith<$Res> {
  __$BriefBundleCopyWithImpl(this._self, this._then);

  final _BriefBundle _self;
  final $Res Function(_BriefBundle) _then;

/// Create a copy of BriefBundle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? briefId = null,Object? sessionId = null,Object? brief = null,Object? provenance = null,Object? originalBrief = freezed,Object? edited = null,Object? evidence = null,Object? guidelineUpdates = null,}) {
  return _then(_BriefBundle(
briefId: null == briefId ? _self.briefId : briefId // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,brief: null == brief ? _self.brief : brief // ignore: cast_nullable_to_non_nullable
as Brief,provenance: null == provenance ? _self.provenance : provenance // ignore: cast_nullable_to_non_nullable
as Provenance,originalBrief: freezed == originalBrief ? _self.originalBrief : originalBrief // ignore: cast_nullable_to_non_nullable
as Brief?,edited: null == edited ? _self.edited : edited // ignore: cast_nullable_to_non_nullable
as bool,evidence: null == evidence ? _self._evidence : evidence // ignore: cast_nullable_to_non_nullable
as List<EvidenceItem>,guidelineUpdates: null == guidelineUpdates ? _self._guidelineUpdates : guidelineUpdates // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of BriefBundle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BriefCopyWith<$Res> get brief {
  
  return $BriefCopyWith<$Res>(_self.brief, (value) {
    return _then(_self.copyWith(brief: value));
  });
}/// Create a copy of BriefBundle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProvenanceCopyWith<$Res> get provenance {
  
  return $ProvenanceCopyWith<$Res>(_self.provenance, (value) {
    return _then(_self.copyWith(provenance: value));
  });
}/// Create a copy of BriefBundle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BriefCopyWith<$Res>? get originalBrief {
    if (_self.originalBrief == null) {
    return null;
  }

  return $BriefCopyWith<$Res>(_self.originalBrief!, (value) {
    return _then(_self.copyWith(originalBrief: value));
  });
}
}

// dart format on
