// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trust.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrustEvent {

 String get node; RouteMode get mode; String get policyRequired; TrustOutcome get outcome; String? get sessionId; String? get modelId; String? get route; Map<String, dynamic> get evidence; String? get requestId; int? get latencyMs; DateTime? get createdAt;
/// Create a copy of TrustEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrustEventCopyWith<TrustEvent> get copyWith => _$TrustEventCopyWithImpl<TrustEvent>(this as TrustEvent, _$identity);

  /// Serializes this TrustEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TrustEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrustEvent&&(identical(other.node, _this.node) || other.node == _this.node)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.policyRequired, _this.policyRequired) || other.policyRequired == _this.policyRequired)&&(identical(other.outcome, _this.outcome) || other.outcome == _this.outcome)&&(identical(other.sessionId, _this.sessionId) || other.sessionId == _this.sessionId)&&(identical(other.modelId, _this.modelId) || other.modelId == _this.modelId)&&(identical(other.route, _this.route) || other.route == _this.route)&&const DeepCollectionEquality().equals(other.evidence, _this.evidence)&&(identical(other.requestId, _this.requestId) || other.requestId == _this.requestId)&&(identical(other.latencyMs, _this.latencyMs) || other.latencyMs == _this.latencyMs)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TrustEvent;
  return Object.hash(runtimeType,_this.node,_this.mode,_this.policyRequired,_this.outcome,_this.sessionId,_this.modelId,_this.route,const DeepCollectionEquality().hash(_this.evidence),_this.requestId,_this.latencyMs,_this.createdAt);
}

@override
String toString() {
  final _this = this as TrustEvent;
  return 'TrustEvent(node: ${_this.node}, mode: ${_this.mode}, policyRequired: ${_this.policyRequired}, outcome: ${_this.outcome}, sessionId: ${_this.sessionId}, modelId: ${_this.modelId}, route: ${_this.route}, evidence: ${_this.evidence}, requestId: ${_this.requestId}, latencyMs: ${_this.latencyMs}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $TrustEventCopyWith<$Res>  {
  factory $TrustEventCopyWith(TrustEvent value, $Res Function(TrustEvent) _then) = _$TrustEventCopyWithImpl;
@useResult
$Res call({
 String node, RouteMode mode, String policyRequired, TrustOutcome outcome, String? sessionId, String? modelId, String? route, Map<String, dynamic> evidence, String? requestId, int? latencyMs, DateTime? createdAt
});




}
/// @nodoc
class _$TrustEventCopyWithImpl<$Res>
    implements $TrustEventCopyWith<$Res> {
  _$TrustEventCopyWithImpl(this._self, this._then);

  final TrustEvent _self;
  final $Res Function(TrustEvent) _then;

/// Create a copy of TrustEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? node = null,Object? mode = null,Object? policyRequired = null,Object? outcome = null,Object? sessionId = freezed,Object? modelId = freezed,Object? route = freezed,Object? evidence = null,Object? requestId = freezed,Object? latencyMs = freezed,Object? createdAt = freezed,}) {
  return _then(TrustEvent(
node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as RouteMode,policyRequired: null == policyRequired ? _self.policyRequired : policyRequired // ignore: cast_nullable_to_non_nullable
as String,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as TrustOutcome,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,modelId: freezed == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String?,route: freezed == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String?,evidence: null == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String?,latencyMs: freezed == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrustEvent].
extension TrustEventPatterns on TrustEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrustEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrustEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrustEvent value)  $default,){
final _that = this;
switch (_that) {
case _TrustEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrustEvent value)?  $default,){
final _that = this;
switch (_that) {
case _TrustEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String node,  RouteMode mode,  String policyRequired,  TrustOutcome outcome,  String? sessionId,  String? modelId,  String? route,  Map<String, dynamic> evidence,  String? requestId,  int? latencyMs,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrustEvent() when $default != null:
return $default(_that.node,_that.mode,_that.policyRequired,_that.outcome,_that.sessionId,_that.modelId,_that.route,_that.evidence,_that.requestId,_that.latencyMs,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String node,  RouteMode mode,  String policyRequired,  TrustOutcome outcome,  String? sessionId,  String? modelId,  String? route,  Map<String, dynamic> evidence,  String? requestId,  int? latencyMs,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _TrustEvent():
return $default(_that.node,_that.mode,_that.policyRequired,_that.outcome,_that.sessionId,_that.modelId,_that.route,_that.evidence,_that.requestId,_that.latencyMs,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String node,  RouteMode mode,  String policyRequired,  TrustOutcome outcome,  String? sessionId,  String? modelId,  String? route,  Map<String, dynamic> evidence,  String? requestId,  int? latencyMs,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _TrustEvent() when $default != null:
return $default(_that.node,_that.mode,_that.policyRequired,_that.outcome,_that.sessionId,_that.modelId,_that.route,_that.evidence,_that.requestId,_that.latencyMs,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrustEvent implements TrustEvent {
  const _TrustEvent({required this.node, required this.mode, required this.policyRequired, required this.outcome, this.sessionId, this.modelId, this.route,  Map<String, dynamic> evidence = const <String, dynamic>{}, this.requestId, this.latencyMs, this.createdAt}): _evidence = evidence;
  factory _TrustEvent.fromJson(Map<String, dynamic> json) => _$TrustEventFromJson(json);

@override final  String node;
@override final  RouteMode mode;
@override final  String policyRequired;
@override final  TrustOutcome outcome;
@override final  String? sessionId;
@override final  String? modelId;
@override final  String? route;
 final  Map<String, dynamic> _evidence;
@override@JsonKey() Map<String, dynamic> get evidence {
  if (_evidence is EqualUnmodifiableMapView) return _evidence;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_evidence);
}

@override final  String? requestId;
@override final  int? latencyMs;
@override final  DateTime? createdAt;

/// Create a copy of TrustEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrustEventCopyWith<_TrustEvent> get copyWith => __$TrustEventCopyWithImpl<_TrustEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrustEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrustEvent&&(identical(other.node, node) || other.node == node)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.policyRequired, policyRequired) || other.policyRequired == policyRequired)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.modelId, modelId) || other.modelId == modelId)&&(identical(other.route, route) || other.route == route)&&const DeepCollectionEquality().equals(other.evidence, _evidence)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,node,mode,policyRequired,outcome,sessionId,modelId,route,const DeepCollectionEquality().hash(_evidence),requestId,latencyMs,createdAt);
}

@override
String toString() {
    return 'TrustEvent(node: $node, mode: $mode, policyRequired: $policyRequired, outcome: $outcome, sessionId: $sessionId, modelId: $modelId, route: $route, evidence: $evidence, requestId: $requestId, latencyMs: $latencyMs, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TrustEventCopyWith<$Res> implements $TrustEventCopyWith<$Res> {
  factory _$TrustEventCopyWith(_TrustEvent value, $Res Function(_TrustEvent) _then) = __$TrustEventCopyWithImpl;
@override @useResult
$Res call({
 String node, RouteMode mode, String policyRequired, TrustOutcome outcome, String? sessionId, String? modelId, String? route, Map<String, dynamic> evidence, String? requestId, int? latencyMs, DateTime? createdAt
});




}
/// @nodoc
class __$TrustEventCopyWithImpl<$Res>
    implements _$TrustEventCopyWith<$Res> {
  __$TrustEventCopyWithImpl(this._self, this._then);

  final _TrustEvent _self;
  final $Res Function(_TrustEvent) _then;

/// Create a copy of TrustEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? node = null,Object? mode = null,Object? policyRequired = null,Object? outcome = null,Object? sessionId = freezed,Object? modelId = freezed,Object? route = freezed,Object? evidence = null,Object? requestId = freezed,Object? latencyMs = freezed,Object? createdAt = freezed,}) {
  return _then(_TrustEvent(
node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as RouteMode,policyRequired: null == policyRequired ? _self.policyRequired : policyRequired // ignore: cast_nullable_to_non_nullable
as String,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as TrustOutcome,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,modelId: freezed == modelId ? _self.modelId : modelId // ignore: cast_nullable_to_non_nullable
as String?,route: freezed == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String?,evidence: null == evidence ? _self._evidence : evidence // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String?,latencyMs: freezed == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$TrustReport {

 String? get sessionId; RouteMode? get mode; List<TrustEvent> get events; Map<String, dynamic> get attestation;
/// Create a copy of TrustReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrustReportCopyWith<TrustReport> get copyWith => _$TrustReportCopyWithImpl<TrustReport>(this as TrustReport, _$identity);

  /// Serializes this TrustReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TrustReport;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrustReport&&(identical(other.sessionId, _this.sessionId) || other.sessionId == _this.sessionId)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&const DeepCollectionEquality().equals(other.events, _this.events)&&const DeepCollectionEquality().equals(other.attestation, _this.attestation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TrustReport;
  return Object.hash(runtimeType,_this.sessionId,_this.mode,const DeepCollectionEquality().hash(_this.events),const DeepCollectionEquality().hash(_this.attestation));
}

@override
String toString() {
  final _this = this as TrustReport;
  return 'TrustReport(sessionId: ${_this.sessionId}, mode: ${_this.mode}, events: ${_this.events}, attestation: ${_this.attestation})';
}


}

/// @nodoc
abstract mixin class $TrustReportCopyWith<$Res>  {
  factory $TrustReportCopyWith(TrustReport value, $Res Function(TrustReport) _then) = _$TrustReportCopyWithImpl;
@useResult
$Res call({
 String? sessionId, RouteMode? mode, List<TrustEvent> events, Map<String, dynamic> attestation
});




}
/// @nodoc
class _$TrustReportCopyWithImpl<$Res>
    implements $TrustReportCopyWith<$Res> {
  _$TrustReportCopyWithImpl(this._self, this._then);

  final TrustReport _self;
  final $Res Function(TrustReport) _then;

/// Create a copy of TrustReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = freezed,Object? mode = freezed,Object? events = null,Object? attestation = null,}) {
  return _then(TrustReport(
sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as RouteMode?,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<TrustEvent>,attestation: null == attestation ? _self.attestation : attestation // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [TrustReport].
extension TrustReportPatterns on TrustReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrustReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrustReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrustReport value)  $default,){
final _that = this;
switch (_that) {
case _TrustReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrustReport value)?  $default,){
final _that = this;
switch (_that) {
case _TrustReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? sessionId,  RouteMode? mode,  List<TrustEvent> events,  Map<String, dynamic> attestation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrustReport() when $default != null:
return $default(_that.sessionId,_that.mode,_that.events,_that.attestation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? sessionId,  RouteMode? mode,  List<TrustEvent> events,  Map<String, dynamic> attestation)  $default,) {final _that = this;
switch (_that) {
case _TrustReport():
return $default(_that.sessionId,_that.mode,_that.events,_that.attestation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? sessionId,  RouteMode? mode,  List<TrustEvent> events,  Map<String, dynamic> attestation)?  $default,) {final _that = this;
switch (_that) {
case _TrustReport() when $default != null:
return $default(_that.sessionId,_that.mode,_that.events,_that.attestation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrustReport implements TrustReport {
  const _TrustReport({this.sessionId, this.mode,  List<TrustEvent> events = const <TrustEvent>[],  Map<String, dynamic> attestation = const <String, dynamic>{}}): _events = events,_attestation = attestation;
  factory _TrustReport.fromJson(Map<String, dynamic> json) => _$TrustReportFromJson(json);

@override final  String? sessionId;
@override final  RouteMode? mode;
 final  List<TrustEvent> _events;
@override@JsonKey() List<TrustEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}

 final  Map<String, dynamic> _attestation;
@override@JsonKey() Map<String, dynamic> get attestation {
  if (_attestation is EqualUnmodifiableMapView) return _attestation;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_attestation);
}


/// Create a copy of TrustReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrustReportCopyWith<_TrustReport> get copyWith => __$TrustReportCopyWithImpl<_TrustReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrustReportToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrustReport&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.mode, mode) || other.mode == mode)&&const DeepCollectionEquality().equals(other.events, _events)&&const DeepCollectionEquality().equals(other.attestation, _attestation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,sessionId,mode,const DeepCollectionEquality().hash(_events),const DeepCollectionEquality().hash(_attestation));
}

@override
String toString() {
    return 'TrustReport(sessionId: $sessionId, mode: $mode, events: $events, attestation: $attestation)';
}


}

/// @nodoc
abstract mixin class _$TrustReportCopyWith<$Res> implements $TrustReportCopyWith<$Res> {
  factory _$TrustReportCopyWith(_TrustReport value, $Res Function(_TrustReport) _then) = __$TrustReportCopyWithImpl;
@override @useResult
$Res call({
 String? sessionId, RouteMode? mode, List<TrustEvent> events, Map<String, dynamic> attestation
});




}
/// @nodoc
class __$TrustReportCopyWithImpl<$Res>
    implements _$TrustReportCopyWith<$Res> {
  __$TrustReportCopyWithImpl(this._self, this._then);

  final _TrustReport _self;
  final $Res Function(_TrustReport) _then;

/// Create a copy of TrustReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = freezed,Object? mode = freezed,Object? events = null,Object? attestation = null,}) {
  return _then(_TrustReport(
sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,mode: freezed == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as RouteMode?,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<TrustEvent>,attestation: null == attestation ? _self._attestation : attestation // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$AuditRow {

 String get action; int? get id; String? get sessionId; String? get actor; DateTime? get createdAt;
/// Create a copy of AuditRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuditRowCopyWith<AuditRow> get copyWith => _$AuditRowCopyWithImpl<AuditRow>(this as AuditRow, _$identity);

  /// Serializes this AuditRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AuditRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuditRow&&(identical(other.action, _this.action) || other.action == _this.action)&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.sessionId, _this.sessionId) || other.sessionId == _this.sessionId)&&(identical(other.actor, _this.actor) || other.actor == _this.actor)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AuditRow;
  return Object.hash(runtimeType,_this.action,_this.id,_this.sessionId,_this.actor,_this.createdAt);
}

@override
String toString() {
  final _this = this as AuditRow;
  return 'AuditRow(action: ${_this.action}, id: ${_this.id}, sessionId: ${_this.sessionId}, actor: ${_this.actor}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $AuditRowCopyWith<$Res>  {
  factory $AuditRowCopyWith(AuditRow value, $Res Function(AuditRow) _then) = _$AuditRowCopyWithImpl;
@useResult
$Res call({
 String action, int? id, String? sessionId, String? actor, DateTime? createdAt
});




}
/// @nodoc
class _$AuditRowCopyWithImpl<$Res>
    implements $AuditRowCopyWith<$Res> {
  _$AuditRowCopyWithImpl(this._self, this._then);

  final AuditRow _self;
  final $Res Function(AuditRow) _then;

/// Create a copy of AuditRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? action = null,Object? id = freezed,Object? sessionId = freezed,Object? actor = freezed,Object? createdAt = freezed,}) {
  return _then(AuditRow(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AuditRow].
extension AuditRowPatterns on AuditRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuditRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuditRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuditRow value)  $default,){
final _that = this;
switch (_that) {
case _AuditRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuditRow value)?  $default,){
final _that = this;
switch (_that) {
case _AuditRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String action,  int? id,  String? sessionId,  String? actor,  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuditRow() when $default != null:
return $default(_that.action,_that.id,_that.sessionId,_that.actor,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String action,  int? id,  String? sessionId,  String? actor,  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _AuditRow():
return $default(_that.action,_that.id,_that.sessionId,_that.actor,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String action,  int? id,  String? sessionId,  String? actor,  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _AuditRow() when $default != null:
return $default(_that.action,_that.id,_that.sessionId,_that.actor,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuditRow implements AuditRow {
  const _AuditRow({required this.action, this.id, this.sessionId, this.actor, this.createdAt});
  factory _AuditRow.fromJson(Map<String, dynamic> json) => _$AuditRowFromJson(json);

@override final  String action;
@override final  int? id;
@override final  String? sessionId;
@override final  String? actor;
@override final  DateTime? createdAt;

/// Create a copy of AuditRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuditRowCopyWith<_AuditRow> get copyWith => __$AuditRowCopyWithImpl<_AuditRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuditRowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuditRow&&(identical(other.action, action) || other.action == action)&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,action,id,sessionId,actor,createdAt);
}

@override
String toString() {
    return 'AuditRow(action: $action, id: $id, sessionId: $sessionId, actor: $actor, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$AuditRowCopyWith<$Res> implements $AuditRowCopyWith<$Res> {
  factory _$AuditRowCopyWith(_AuditRow value, $Res Function(_AuditRow) _then) = __$AuditRowCopyWithImpl;
@override @useResult
$Res call({
 String action, int? id, String? sessionId, String? actor, DateTime? createdAt
});




}
/// @nodoc
class __$AuditRowCopyWithImpl<$Res>
    implements _$AuditRowCopyWith<$Res> {
  __$AuditRowCopyWithImpl(this._self, this._then);

  final _AuditRow _self;
  final $Res Function(_AuditRow) _then;

/// Create a copy of AuditRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? action = null,Object? id = freezed,Object? sessionId = freezed,Object? actor = freezed,Object? createdAt = freezed,}) {
  return _then(_AuditRow(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,actor: freezed == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
