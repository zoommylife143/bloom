// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionSummary {

@JsonKey(readValue: _readId) String get id; SessionStatus get status; DateTime? get createdAt; DateTime? get updatedAt;@JsonKey(name: 'red_flag_rule') RedFlagRule? get redFlag; String? get scenarioId; String? get briefId;/// Null until a brief exists.
 ReviewStatus? get reviewStatus; String? get ageBand;/// Truncated to 120 characters by the server.
 String? get reasonForVisit; RouteMode? get mode;
/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionSummaryCopyWith<SessionSummary> get copyWith => _$SessionSummaryCopyWithImpl<SessionSummary>(this as SessionSummary, _$identity);

  /// Serializes this SessionSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SessionSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.redFlag, _this.redFlag) || other.redFlag == _this.redFlag)&&(identical(other.scenarioId, _this.scenarioId) || other.scenarioId == _this.scenarioId)&&(identical(other.briefId, _this.briefId) || other.briefId == _this.briefId)&&(identical(other.reviewStatus, _this.reviewStatus) || other.reviewStatus == _this.reviewStatus)&&(identical(other.ageBand, _this.ageBand) || other.ageBand == _this.ageBand)&&(identical(other.reasonForVisit, _this.reasonForVisit) || other.reasonForVisit == _this.reasonForVisit)&&(identical(other.mode, _this.mode) || other.mode == _this.mode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SessionSummary;
  return Object.hash(runtimeType,_this.id,_this.status,_this.createdAt,_this.updatedAt,_this.redFlag,_this.scenarioId,_this.briefId,_this.reviewStatus,_this.ageBand,_this.reasonForVisit,_this.mode);
}

@override
String toString() {
  final _this = this as SessionSummary;
  return 'SessionSummary(id: ${_this.id}, status: ${_this.status}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt}, redFlag: ${_this.redFlag}, scenarioId: ${_this.scenarioId}, briefId: ${_this.briefId}, reviewStatus: ${_this.reviewStatus}, ageBand: ${_this.ageBand}, reasonForVisit: ${_this.reasonForVisit}, mode: ${_this.mode})';
}


}

/// @nodoc
abstract mixin class $SessionSummaryCopyWith<$Res>  {
  factory $SessionSummaryCopyWith(SessionSummary value, $Res Function(SessionSummary) _then) = _$SessionSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(readValue: _readId) String id, SessionStatus status, DateTime? createdAt, DateTime? updatedAt,@JsonKey(name: 'red_flag_rule') RedFlagRule? redFlag, String? scenarioId, String? briefId, ReviewStatus? reviewStatus, String? ageBand, String? reasonForVisit, RouteMode? mode
});




}
/// @nodoc
class _$SessionSummaryCopyWithImpl<$Res>
    implements $SessionSummaryCopyWith<$Res> {
  _$SessionSummaryCopyWithImpl(this._self, this._then);

  final SessionSummary _self;
  final $Res Function(SessionSummary) _then;

/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? redFlag = freezed,Object? scenarioId = freezed,Object? briefId = freezed,Object? reviewStatus = freezed,Object? ageBand = freezed,Object? reasonForVisit = freezed,Object? mode = freezed,}) {
  return _then(SessionSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,redFlag: freezed == redFlag ? _self.redFlag : redFlag // ignore: cast_nullable_to_non_nullable
as RedFlagRule?,scenarioId: freezed == scenarioId ? _self.scenarioId : scenarioId // ignore: cast_nullable_to_non_nullable
as String?,briefId: freezed == briefId ? _self.briefId : briefId // ignore: cast_nullable_to_non_nullable
as String?,reviewStatus: freezed == reviewStatus ? _self.reviewStatus : reviewStatus // ignore: cast_nullable_to_non_nullable
as ReviewStatus?,ageBand: freezed == ageBand ? _self.ageBand : ageBand // ignore: cast_nullable_to_non_nullable
as String?,reasonForVisit: freezed == reasonForVisit ? _self.reasonForVisit : reasonForVisit // ignore: cast_nullable_to_non_nullable
as String?,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as RouteMode?,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionSummary].
extension SessionSummaryPatterns on SessionSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionSummary value)  $default,){
final _that = this;
switch (_that) {
case _SessionSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionSummary value)?  $default,){
final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(readValue: _readId)  String id,  SessionStatus status,  DateTime? createdAt,  DateTime? updatedAt, @JsonKey(name: 'red_flag_rule')  RedFlagRule? redFlag,  String? scenarioId,  String? briefId,  ReviewStatus? reviewStatus,  String? ageBand,  String? reasonForVisit,  RouteMode? mode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
return $default(_that.id,_that.status,_that.createdAt,_that.updatedAt,_that.redFlag,_that.scenarioId,_that.briefId,_that.reviewStatus,_that.ageBand,_that.reasonForVisit,_that.mode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(readValue: _readId)  String id,  SessionStatus status,  DateTime? createdAt,  DateTime? updatedAt, @JsonKey(name: 'red_flag_rule')  RedFlagRule? redFlag,  String? scenarioId,  String? briefId,  ReviewStatus? reviewStatus,  String? ageBand,  String? reasonForVisit,  RouteMode? mode)  $default,) {final _that = this;
switch (_that) {
case _SessionSummary():
return $default(_that.id,_that.status,_that.createdAt,_that.updatedAt,_that.redFlag,_that.scenarioId,_that.briefId,_that.reviewStatus,_that.ageBand,_that.reasonForVisit,_that.mode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(readValue: _readId)  String id,  SessionStatus status,  DateTime? createdAt,  DateTime? updatedAt, @JsonKey(name: 'red_flag_rule')  RedFlagRule? redFlag,  String? scenarioId,  String? briefId,  ReviewStatus? reviewStatus,  String? ageBand,  String? reasonForVisit,  RouteMode? mode)?  $default,) {final _that = this;
switch (_that) {
case _SessionSummary() when $default != null:
return $default(_that.id,_that.status,_that.createdAt,_that.updatedAt,_that.redFlag,_that.scenarioId,_that.briefId,_that.reviewStatus,_that.ageBand,_that.reasonForVisit,_that.mode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionSummary implements SessionSummary {
  const _SessionSummary({@JsonKey(readValue: _readId) required this.id, required this.status, this.createdAt, this.updatedAt, @JsonKey(name: 'red_flag_rule') this.redFlag, this.scenarioId, this.briefId, this.reviewStatus, this.ageBand, this.reasonForVisit, this.mode});
  factory _SessionSummary.fromJson(Map<String, dynamic> json) => _$SessionSummaryFromJson(json);

@override@JsonKey(readValue: _readId) final  String id;
@override final  SessionStatus status;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;
@override@JsonKey(name: 'red_flag_rule') final  RedFlagRule? redFlag;
@override final  String? scenarioId;
@override final  String? briefId;
/// Null until a brief exists.
@override final  ReviewStatus? reviewStatus;
@override final  String? ageBand;
/// Truncated to 120 characters by the server.
@override final  String? reasonForVisit;
@override final  RouteMode? mode;

/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionSummaryCopyWith<_SessionSummary> get copyWith => __$SessionSummaryCopyWithImpl<_SessionSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.redFlag, redFlag) || other.redFlag == redFlag)&&(identical(other.scenarioId, scenarioId) || other.scenarioId == scenarioId)&&(identical(other.briefId, briefId) || other.briefId == briefId)&&(identical(other.reviewStatus, reviewStatus) || other.reviewStatus == reviewStatus)&&(identical(other.ageBand, ageBand) || other.ageBand == ageBand)&&(identical(other.reasonForVisit, reasonForVisit) || other.reasonForVisit == reasonForVisit)&&(identical(other.mode, mode) || other.mode == mode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,status,createdAt,updatedAt,redFlag,scenarioId,briefId,reviewStatus,ageBand,reasonForVisit,mode);
}

@override
String toString() {
    return 'SessionSummary(id: $id, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, redFlag: $redFlag, scenarioId: $scenarioId, briefId: $briefId, reviewStatus: $reviewStatus, ageBand: $ageBand, reasonForVisit: $reasonForVisit, mode: $mode)';
}


}

/// @nodoc
abstract mixin class _$SessionSummaryCopyWith<$Res> implements $SessionSummaryCopyWith<$Res> {
  factory _$SessionSummaryCopyWith(_SessionSummary value, $Res Function(_SessionSummary) _then) = __$SessionSummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(readValue: _readId) String id, SessionStatus status, DateTime? createdAt, DateTime? updatedAt,@JsonKey(name: 'red_flag_rule') RedFlagRule? redFlag, String? scenarioId, String? briefId, ReviewStatus? reviewStatus, String? ageBand, String? reasonForVisit, RouteMode? mode
});




}
/// @nodoc
class __$SessionSummaryCopyWithImpl<$Res>
    implements _$SessionSummaryCopyWith<$Res> {
  __$SessionSummaryCopyWithImpl(this._self, this._then);

  final _SessionSummary _self;
  final $Res Function(_SessionSummary) _then;

/// Create a copy of SessionSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? redFlag = freezed,Object? scenarioId = freezed,Object? briefId = freezed,Object? reviewStatus = freezed,Object? ageBand = freezed,Object? reasonForVisit = freezed,Object? mode = freezed,}) {
  return _then(_SessionSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,redFlag: freezed == redFlag ? _self.redFlag : redFlag // ignore: cast_nullable_to_non_nullable
as RedFlagRule?,scenarioId: freezed == scenarioId ? _self.scenarioId : scenarioId // ignore: cast_nullable_to_non_nullable
as String?,briefId: freezed == briefId ? _self.briefId : briefId // ignore: cast_nullable_to_non_nullable
as String?,reviewStatus: freezed == reviewStatus ? _self.reviewStatus : reviewStatus // ignore: cast_nullable_to_non_nullable
as ReviewStatus?,ageBand: freezed == ageBand ? _self.ageBand : ageBand // ignore: cast_nullable_to_non_nullable
as String?,reasonForVisit: freezed == reasonForVisit ? _self.reasonForVisit : reasonForVisit // ignore: cast_nullable_to_non_nullable
as String?,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as RouteMode?,
  ));
}


}


/// @nodoc
mixin _$RedFlagSummary {

 String get sessionId; RedFlagRule get ruleId; List<String> get matched; String? get source; DateTime? get createdAt; String? get title; String? get body;
/// Create a copy of RedFlagSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RedFlagSummaryCopyWith<RedFlagSummary> get copyWith => _$RedFlagSummaryCopyWithImpl<RedFlagSummary>(this as RedFlagSummary, _$identity);

  /// Serializes this RedFlagSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RedFlagSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RedFlagSummary&&(identical(other.sessionId, _this.sessionId) || other.sessionId == _this.sessionId)&&(identical(other.ruleId, _this.ruleId) || other.ruleId == _this.ruleId)&&const DeepCollectionEquality().equals(other.matched, _this.matched)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.body, _this.body) || other.body == _this.body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RedFlagSummary;
  return Object.hash(runtimeType,_this.sessionId,_this.ruleId,const DeepCollectionEquality().hash(_this.matched),_this.source,_this.createdAt,_this.title,_this.body);
}

@override
String toString() {
  final _this = this as RedFlagSummary;
  return 'RedFlagSummary(sessionId: ${_this.sessionId}, ruleId: ${_this.ruleId}, matched: ${_this.matched}, source: ${_this.source}, createdAt: ${_this.createdAt}, title: ${_this.title}, body: ${_this.body})';
}


}

/// @nodoc
abstract mixin class $RedFlagSummaryCopyWith<$Res>  {
  factory $RedFlagSummaryCopyWith(RedFlagSummary value, $Res Function(RedFlagSummary) _then) = _$RedFlagSummaryCopyWithImpl;
@useResult
$Res call({
 String sessionId, RedFlagRule ruleId, List<String> matched, String? source, DateTime? createdAt, String? title, String? body
});




}
/// @nodoc
class _$RedFlagSummaryCopyWithImpl<$Res>
    implements $RedFlagSummaryCopyWith<$Res> {
  _$RedFlagSummaryCopyWithImpl(this._self, this._then);

  final RedFlagSummary _self;
  final $Res Function(RedFlagSummary) _then;

/// Create a copy of RedFlagSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? ruleId = null,Object? matched = null,Object? source = freezed,Object? createdAt = freezed,Object? title = freezed,Object? body = freezed,}) {
  return _then(RedFlagSummary(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,ruleId: null == ruleId ? _self.ruleId : ruleId // ignore: cast_nullable_to_non_nullable
as RedFlagRule,matched: null == matched ? _self.matched : matched // ignore: cast_nullable_to_non_nullable
as List<String>,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RedFlagSummary].
extension RedFlagSummaryPatterns on RedFlagSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RedFlagSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RedFlagSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RedFlagSummary value)  $default,){
final _that = this;
switch (_that) {
case _RedFlagSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RedFlagSummary value)?  $default,){
final _that = this;
switch (_that) {
case _RedFlagSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  RedFlagRule ruleId,  List<String> matched,  String? source,  DateTime? createdAt,  String? title,  String? body)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RedFlagSummary() when $default != null:
return $default(_that.sessionId,_that.ruleId,_that.matched,_that.source,_that.createdAt,_that.title,_that.body);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  RedFlagRule ruleId,  List<String> matched,  String? source,  DateTime? createdAt,  String? title,  String? body)  $default,) {final _that = this;
switch (_that) {
case _RedFlagSummary():
return $default(_that.sessionId,_that.ruleId,_that.matched,_that.source,_that.createdAt,_that.title,_that.body);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  RedFlagRule ruleId,  List<String> matched,  String? source,  DateTime? createdAt,  String? title,  String? body)?  $default,) {final _that = this;
switch (_that) {
case _RedFlagSummary() when $default != null:
return $default(_that.sessionId,_that.ruleId,_that.matched,_that.source,_that.createdAt,_that.title,_that.body);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RedFlagSummary implements RedFlagSummary {
  const _RedFlagSummary({required this.sessionId, required this.ruleId,  List<String> matched = const <String>[], this.source, this.createdAt, this.title, this.body}): _matched = matched;
  factory _RedFlagSummary.fromJson(Map<String, dynamic> json) => _$RedFlagSummaryFromJson(json);

@override final  String sessionId;
@override final  RedFlagRule ruleId;
 final  List<String> _matched;
@override@JsonKey() List<String> get matched {
  if (_matched is EqualUnmodifiableListView) return _matched;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_matched);
}

@override final  String? source;
@override final  DateTime? createdAt;
@override final  String? title;
@override final  String? body;

/// Create a copy of RedFlagSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RedFlagSummaryCopyWith<_RedFlagSummary> get copyWith => __$RedFlagSummaryCopyWithImpl<_RedFlagSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RedFlagSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RedFlagSummary&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.ruleId, ruleId) || other.ruleId == ruleId)&&const DeepCollectionEquality().equals(other.matched, _matched)&&(identical(other.source, source) || other.source == source)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,sessionId,ruleId,const DeepCollectionEquality().hash(_matched),source,createdAt,title,body);
}

@override
String toString() {
    return 'RedFlagSummary(sessionId: $sessionId, ruleId: $ruleId, matched: $matched, source: $source, createdAt: $createdAt, title: $title, body: $body)';
}


}

/// @nodoc
abstract mixin class _$RedFlagSummaryCopyWith<$Res> implements $RedFlagSummaryCopyWith<$Res> {
  factory _$RedFlagSummaryCopyWith(_RedFlagSummary value, $Res Function(_RedFlagSummary) _then) = __$RedFlagSummaryCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, RedFlagRule ruleId, List<String> matched, String? source, DateTime? createdAt, String? title, String? body
});




}
/// @nodoc
class __$RedFlagSummaryCopyWithImpl<$Res>
    implements _$RedFlagSummaryCopyWith<$Res> {
  __$RedFlagSummaryCopyWithImpl(this._self, this._then);

  final _RedFlagSummary _self;
  final $Res Function(_RedFlagSummary) _then;

/// Create a copy of RedFlagSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? ruleId = null,Object? matched = null,Object? source = freezed,Object? createdAt = freezed,Object? title = freezed,Object? body = freezed,}) {
  return _then(_RedFlagSummary(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,ruleId: null == ruleId ? _self.ruleId : ruleId // ignore: cast_nullable_to_non_nullable
as RedFlagRule,matched: null == matched ? _self._matched : matched // ignore: cast_nullable_to_non_nullable
as List<String>,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ScenarioRun {

 String get sessionId; SessionStatus get status; String? get scenarioId; int get turnsRun; String? get briefId;
/// Create a copy of ScenarioRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScenarioRunCopyWith<ScenarioRun> get copyWith => _$ScenarioRunCopyWithImpl<ScenarioRun>(this as ScenarioRun, _$identity);

  /// Serializes this ScenarioRun to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ScenarioRun;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScenarioRun&&(identical(other.sessionId, _this.sessionId) || other.sessionId == _this.sessionId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.scenarioId, _this.scenarioId) || other.scenarioId == _this.scenarioId)&&(identical(other.turnsRun, _this.turnsRun) || other.turnsRun == _this.turnsRun)&&(identical(other.briefId, _this.briefId) || other.briefId == _this.briefId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ScenarioRun;
  return Object.hash(runtimeType,_this.sessionId,_this.status,_this.scenarioId,_this.turnsRun,_this.briefId);
}

@override
String toString() {
  final _this = this as ScenarioRun;
  return 'ScenarioRun(sessionId: ${_this.sessionId}, status: ${_this.status}, scenarioId: ${_this.scenarioId}, turnsRun: ${_this.turnsRun}, briefId: ${_this.briefId})';
}


}

/// @nodoc
abstract mixin class $ScenarioRunCopyWith<$Res>  {
  factory $ScenarioRunCopyWith(ScenarioRun value, $Res Function(ScenarioRun) _then) = _$ScenarioRunCopyWithImpl;
@useResult
$Res call({
 String sessionId, SessionStatus status, String? scenarioId, int turnsRun, String? briefId
});




}
/// @nodoc
class _$ScenarioRunCopyWithImpl<$Res>
    implements $ScenarioRunCopyWith<$Res> {
  _$ScenarioRunCopyWithImpl(this._self, this._then);

  final ScenarioRun _self;
  final $Res Function(ScenarioRun) _then;

/// Create a copy of ScenarioRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? status = null,Object? scenarioId = freezed,Object? turnsRun = null,Object? briefId = freezed,}) {
  return _then(ScenarioRun(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,scenarioId: freezed == scenarioId ? _self.scenarioId : scenarioId // ignore: cast_nullable_to_non_nullable
as String?,turnsRun: null == turnsRun ? _self.turnsRun : turnsRun // ignore: cast_nullable_to_non_nullable
as int,briefId: freezed == briefId ? _self.briefId : briefId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScenarioRun].
extension ScenarioRunPatterns on ScenarioRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScenarioRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScenarioRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScenarioRun value)  $default,){
final _that = this;
switch (_that) {
case _ScenarioRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScenarioRun value)?  $default,){
final _that = this;
switch (_that) {
case _ScenarioRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  SessionStatus status,  String? scenarioId,  int turnsRun,  String? briefId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScenarioRun() when $default != null:
return $default(_that.sessionId,_that.status,_that.scenarioId,_that.turnsRun,_that.briefId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  SessionStatus status,  String? scenarioId,  int turnsRun,  String? briefId)  $default,) {final _that = this;
switch (_that) {
case _ScenarioRun():
return $default(_that.sessionId,_that.status,_that.scenarioId,_that.turnsRun,_that.briefId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  SessionStatus status,  String? scenarioId,  int turnsRun,  String? briefId)?  $default,) {final _that = this;
switch (_that) {
case _ScenarioRun() when $default != null:
return $default(_that.sessionId,_that.status,_that.scenarioId,_that.turnsRun,_that.briefId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScenarioRun implements ScenarioRun {
  const _ScenarioRun({required this.sessionId, required this.status, this.scenarioId, this.turnsRun = 0, this.briefId});
  factory _ScenarioRun.fromJson(Map<String, dynamic> json) => _$ScenarioRunFromJson(json);

@override final  String sessionId;
@override final  SessionStatus status;
@override final  String? scenarioId;
@override@JsonKey() final  int turnsRun;
@override final  String? briefId;

/// Create a copy of ScenarioRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScenarioRunCopyWith<_ScenarioRun> get copyWith => __$ScenarioRunCopyWithImpl<_ScenarioRun>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScenarioRunToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScenarioRun&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.status, status) || other.status == status)&&(identical(other.scenarioId, scenarioId) || other.scenarioId == scenarioId)&&(identical(other.turnsRun, turnsRun) || other.turnsRun == turnsRun)&&(identical(other.briefId, briefId) || other.briefId == briefId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,sessionId,status,scenarioId,turnsRun,briefId);
}

@override
String toString() {
    return 'ScenarioRun(sessionId: $sessionId, status: $status, scenarioId: $scenarioId, turnsRun: $turnsRun, briefId: $briefId)';
}


}

/// @nodoc
abstract mixin class _$ScenarioRunCopyWith<$Res> implements $ScenarioRunCopyWith<$Res> {
  factory _$ScenarioRunCopyWith(_ScenarioRun value, $Res Function(_ScenarioRun) _then) = __$ScenarioRunCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, SessionStatus status, String? scenarioId, int turnsRun, String? briefId
});




}
/// @nodoc
class __$ScenarioRunCopyWithImpl<$Res>
    implements _$ScenarioRunCopyWith<$Res> {
  __$ScenarioRunCopyWithImpl(this._self, this._then);

  final _ScenarioRun _self;
  final $Res Function(_ScenarioRun) _then;

/// Create a copy of ScenarioRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? status = null,Object? scenarioId = freezed,Object? turnsRun = null,Object? briefId = freezed,}) {
  return _then(_ScenarioRun(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,scenarioId: freezed == scenarioId ? _self.scenarioId : scenarioId // ignore: cast_nullable_to_non_nullable
as String?,turnsRun: null == turnsRun ? _self.turnsRun : turnsRun // ignore: cast_nullable_to_non_nullable
as int,briefId: freezed == briefId ? _self.briefId : briefId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$HealthStatus {

 bool get ok; RouteMode get mode; bool get trustedrouterConfigured;
/// Create a copy of HealthStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthStatusCopyWith<HealthStatus> get copyWith => _$HealthStatusCopyWithImpl<HealthStatus>(this as HealthStatus, _$identity);

  /// Serializes this HealthStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HealthStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthStatus&&(identical(other.ok, _this.ok) || other.ok == _this.ok)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.trustedrouterConfigured, _this.trustedrouterConfigured) || other.trustedrouterConfigured == _this.trustedrouterConfigured));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HealthStatus;
  return Object.hash(runtimeType,_this.ok,_this.mode,_this.trustedrouterConfigured);
}

@override
String toString() {
  final _this = this as HealthStatus;
  return 'HealthStatus(ok: ${_this.ok}, mode: ${_this.mode}, trustedrouterConfigured: ${_this.trustedrouterConfigured})';
}


}

/// @nodoc
abstract mixin class $HealthStatusCopyWith<$Res>  {
  factory $HealthStatusCopyWith(HealthStatus value, $Res Function(HealthStatus) _then) = _$HealthStatusCopyWithImpl;
@useResult
$Res call({
 bool ok, RouteMode mode, bool trustedrouterConfigured
});




}
/// @nodoc
class _$HealthStatusCopyWithImpl<$Res>
    implements $HealthStatusCopyWith<$Res> {
  _$HealthStatusCopyWithImpl(this._self, this._then);

  final HealthStatus _self;
  final $Res Function(HealthStatus) _then;

/// Create a copy of HealthStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ok = null,Object? mode = null,Object? trustedrouterConfigured = null,}) {
  return _then(HealthStatus(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as RouteMode,trustedrouterConfigured: null == trustedrouterConfigured ? _self.trustedrouterConfigured : trustedrouterConfigured // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [HealthStatus].
extension HealthStatusPatterns on HealthStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HealthStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HealthStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HealthStatus value)  $default,){
final _that = this;
switch (_that) {
case _HealthStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HealthStatus value)?  $default,){
final _that = this;
switch (_that) {
case _HealthStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool ok,  RouteMode mode,  bool trustedrouterConfigured)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HealthStatus() when $default != null:
return $default(_that.ok,_that.mode,_that.trustedrouterConfigured);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool ok,  RouteMode mode,  bool trustedrouterConfigured)  $default,) {final _that = this;
switch (_that) {
case _HealthStatus():
return $default(_that.ok,_that.mode,_that.trustedrouterConfigured);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool ok,  RouteMode mode,  bool trustedrouterConfigured)?  $default,) {final _that = this;
switch (_that) {
case _HealthStatus() when $default != null:
return $default(_that.ok,_that.mode,_that.trustedrouterConfigured);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HealthStatus implements HealthStatus {
  const _HealthStatus({required this.ok, required this.mode, this.trustedrouterConfigured = false});
  factory _HealthStatus.fromJson(Map<String, dynamic> json) => _$HealthStatusFromJson(json);

@override final  bool ok;
@override final  RouteMode mode;
@override@JsonKey() final  bool trustedrouterConfigured;

/// Create a copy of HealthStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthStatusCopyWith<_HealthStatus> get copyWith => __$HealthStatusCopyWithImpl<_HealthStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HealthStatusToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthStatus&&(identical(other.ok, ok) || other.ok == ok)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.trustedrouterConfigured, trustedrouterConfigured) || other.trustedrouterConfigured == trustedrouterConfigured));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,ok,mode,trustedrouterConfigured);
}

@override
String toString() {
    return 'HealthStatus(ok: $ok, mode: $mode, trustedrouterConfigured: $trustedrouterConfigured)';
}


}

/// @nodoc
abstract mixin class _$HealthStatusCopyWith<$Res> implements $HealthStatusCopyWith<$Res> {
  factory _$HealthStatusCopyWith(_HealthStatus value, $Res Function(_HealthStatus) _then) = __$HealthStatusCopyWithImpl;
@override @useResult
$Res call({
 bool ok, RouteMode mode, bool trustedrouterConfigured
});




}
/// @nodoc
class __$HealthStatusCopyWithImpl<$Res>
    implements _$HealthStatusCopyWith<$Res> {
  __$HealthStatusCopyWithImpl(this._self, this._then);

  final _HealthStatus _self;
  final $Res Function(_HealthStatus) _then;

/// Create a copy of HealthStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ok = null,Object? mode = null,Object? trustedrouterConfigured = null,}) {
  return _then(_HealthStatus(
ok: null == ok ? _self.ok : ok // ignore: cast_nullable_to_non_nullable
as bool,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as RouteMode,trustedrouterConfigured: null == trustedrouterConfigured ? _self.trustedrouterConfigured : trustedrouterConfigured // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
