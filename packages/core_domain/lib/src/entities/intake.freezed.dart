// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'intake.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StartedSession {

 String get sessionId; RouteMode get mode; SessionStatus get status; String get reply; double get progress;
/// Create a copy of StartedSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StartedSessionCopyWith<StartedSession> get copyWith => _$StartedSessionCopyWithImpl<StartedSession>(this as StartedSession, _$identity);

  /// Serializes this StartedSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StartedSession;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StartedSession&&(identical(other.sessionId, _this.sessionId) || other.sessionId == _this.sessionId)&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.reply, _this.reply) || other.reply == _this.reply)&&(identical(other.progress, _this.progress) || other.progress == _this.progress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StartedSession;
  return Object.hash(runtimeType,_this.sessionId,_this.mode,_this.status,_this.reply,_this.progress);
}

@override
String toString() {
  final _this = this as StartedSession;
  return 'StartedSession(sessionId: ${_this.sessionId}, mode: ${_this.mode}, status: ${_this.status}, reply: ${_this.reply}, progress: ${_this.progress})';
}


}

/// @nodoc
abstract mixin class $StartedSessionCopyWith<$Res>  {
  factory $StartedSessionCopyWith(StartedSession value, $Res Function(StartedSession) _then) = _$StartedSessionCopyWithImpl;
@useResult
$Res call({
 String sessionId, RouteMode mode, SessionStatus status, String reply, double progress
});




}
/// @nodoc
class _$StartedSessionCopyWithImpl<$Res>
    implements $StartedSessionCopyWith<$Res> {
  _$StartedSessionCopyWithImpl(this._self, this._then);

  final StartedSession _self;
  final $Res Function(StartedSession) _then;

/// Create a copy of StartedSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? mode = null,Object? status = null,Object? reply = null,Object? progress = null,}) {
  return _then(StartedSession(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as RouteMode,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,reply: null == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [StartedSession].
extension StartedSessionPatterns on StartedSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StartedSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StartedSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StartedSession value)  $default,){
final _that = this;
switch (_that) {
case _StartedSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StartedSession value)?  $default,){
final _that = this;
switch (_that) {
case _StartedSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  RouteMode mode,  SessionStatus status,  String reply,  double progress)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StartedSession() when $default != null:
return $default(_that.sessionId,_that.mode,_that.status,_that.reply,_that.progress);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  RouteMode mode,  SessionStatus status,  String reply,  double progress)  $default,) {final _that = this;
switch (_that) {
case _StartedSession():
return $default(_that.sessionId,_that.mode,_that.status,_that.reply,_that.progress);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  RouteMode mode,  SessionStatus status,  String reply,  double progress)?  $default,) {final _that = this;
switch (_that) {
case _StartedSession() when $default != null:
return $default(_that.sessionId,_that.mode,_that.status,_that.reply,_that.progress);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StartedSession implements StartedSession {
  const _StartedSession({required this.sessionId, required this.mode, this.status = SessionStatus.inProgress, this.reply = '', this.progress = 0});
  factory _StartedSession.fromJson(Map<String, dynamic> json) => _$StartedSessionFromJson(json);

@override final  String sessionId;
@override final  RouteMode mode;
@override@JsonKey() final  SessionStatus status;
@override@JsonKey() final  String reply;
@override@JsonKey() final  double progress;

/// Create a copy of StartedSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StartedSessionCopyWith<_StartedSession> get copyWith => __$StartedSessionCopyWithImpl<_StartedSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StartedSessionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StartedSession&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.status, status) || other.status == status)&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.progress, progress) || other.progress == progress));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,sessionId,mode,status,reply,progress);
}

@override
String toString() {
    return 'StartedSession(sessionId: $sessionId, mode: $mode, status: $status, reply: $reply, progress: $progress)';
}


}

/// @nodoc
abstract mixin class _$StartedSessionCopyWith<$Res> implements $StartedSessionCopyWith<$Res> {
  factory _$StartedSessionCopyWith(_StartedSession value, $Res Function(_StartedSession) _then) = __$StartedSessionCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, RouteMode mode, SessionStatus status, String reply, double progress
});




}
/// @nodoc
class __$StartedSessionCopyWithImpl<$Res>
    implements _$StartedSessionCopyWith<$Res> {
  __$StartedSessionCopyWithImpl(this._self, this._then);

  final _StartedSession _self;
  final $Res Function(_StartedSession) _then;

/// Create a copy of StartedSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? mode = null,Object? status = null,Object? reply = null,Object? progress = null,}) {
  return _then(_StartedSession(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as RouteMode,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,reply: null == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$UrgentAction {

 String get label; String get tel;
/// Create a copy of UrgentAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UrgentActionCopyWith<UrgentAction> get copyWith => _$UrgentActionCopyWithImpl<UrgentAction>(this as UrgentAction, _$identity);

  /// Serializes this UrgentAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UrgentAction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UrgentAction&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.tel, _this.tel) || other.tel == _this.tel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UrgentAction;
  return Object.hash(runtimeType,_this.label,_this.tel);
}

@override
String toString() {
  final _this = this as UrgentAction;
  return 'UrgentAction(label: ${_this.label}, tel: ${_this.tel})';
}


}

/// @nodoc
abstract mixin class $UrgentActionCopyWith<$Res>  {
  factory $UrgentActionCopyWith(UrgentAction value, $Res Function(UrgentAction) _then) = _$UrgentActionCopyWithImpl;
@useResult
$Res call({
 String label, String tel
});




}
/// @nodoc
class _$UrgentActionCopyWithImpl<$Res>
    implements $UrgentActionCopyWith<$Res> {
  _$UrgentActionCopyWithImpl(this._self, this._then);

  final UrgentAction _self;
  final $Res Function(UrgentAction) _then;

/// Create a copy of UrgentAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? tel = null,}) {
  return _then(UrgentAction(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,tel: null == tel ? _self.tel : tel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UrgentAction].
extension UrgentActionPatterns on UrgentAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UrgentAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UrgentAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UrgentAction value)  $default,){
final _that = this;
switch (_that) {
case _UrgentAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UrgentAction value)?  $default,){
final _that = this;
switch (_that) {
case _UrgentAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String tel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UrgentAction() when $default != null:
return $default(_that.label,_that.tel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String tel)  $default,) {final _that = this;
switch (_that) {
case _UrgentAction():
return $default(_that.label,_that.tel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String tel)?  $default,) {final _that = this;
switch (_that) {
case _UrgentAction() when $default != null:
return $default(_that.label,_that.tel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UrgentAction implements UrgentAction {
  const _UrgentAction({required this.label, required this.tel});
  factory _UrgentAction.fromJson(Map<String, dynamic> json) => _$UrgentActionFromJson(json);

@override final  String label;
@override final  String tel;

/// Create a copy of UrgentAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UrgentActionCopyWith<_UrgentAction> get copyWith => __$UrgentActionCopyWithImpl<_UrgentAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UrgentActionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UrgentAction&&(identical(other.label, label) || other.label == label)&&(identical(other.tel, tel) || other.tel == tel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,label,tel);
}

@override
String toString() {
    return 'UrgentAction(label: $label, tel: $tel)';
}


}

/// @nodoc
abstract mixin class _$UrgentActionCopyWith<$Res> implements $UrgentActionCopyWith<$Res> {
  factory _$UrgentActionCopyWith(_UrgentAction value, $Res Function(_UrgentAction) _then) = __$UrgentActionCopyWithImpl;
@override @useResult
$Res call({
 String label, String tel
});




}
/// @nodoc
class __$UrgentActionCopyWithImpl<$Res>
    implements _$UrgentActionCopyWith<$Res> {
  __$UrgentActionCopyWithImpl(this._self, this._then);

  final _UrgentAction _self;
  final $Res Function(_UrgentAction) _then;

/// Create a copy of UrgentAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? tel = null,}) {
  return _then(_UrgentAction(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,tel: null == tel ? _self.tel : tel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$UrgentMessage {

 String get title; String get body; List<UrgentAction> get actions; RedFlagRule? get ruleId; String? get support;
/// Create a copy of UrgentMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UrgentMessageCopyWith<UrgentMessage> get copyWith => _$UrgentMessageCopyWithImpl<UrgentMessage>(this as UrgentMessage, _$identity);

  /// Serializes this UrgentMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as UrgentMessage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UrgentMessage&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.body, _this.body) || other.body == _this.body)&&const DeepCollectionEquality().equals(other.actions, _this.actions)&&(identical(other.ruleId, _this.ruleId) || other.ruleId == _this.ruleId)&&(identical(other.support, _this.support) || other.support == _this.support));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UrgentMessage;
  return Object.hash(runtimeType,_this.title,_this.body,const DeepCollectionEquality().hash(_this.actions),_this.ruleId,_this.support);
}

@override
String toString() {
  final _this = this as UrgentMessage;
  return 'UrgentMessage(title: ${_this.title}, body: ${_this.body}, actions: ${_this.actions}, ruleId: ${_this.ruleId}, support: ${_this.support})';
}


}

/// @nodoc
abstract mixin class $UrgentMessageCopyWith<$Res>  {
  factory $UrgentMessageCopyWith(UrgentMessage value, $Res Function(UrgentMessage) _then) = _$UrgentMessageCopyWithImpl;
@useResult
$Res call({
 String title, String body, List<UrgentAction> actions, RedFlagRule? ruleId, String? support
});




}
/// @nodoc
class _$UrgentMessageCopyWithImpl<$Res>
    implements $UrgentMessageCopyWith<$Res> {
  _$UrgentMessageCopyWithImpl(this._self, this._then);

  final UrgentMessage _self;
  final $Res Function(UrgentMessage) _then;

/// Create a copy of UrgentMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? body = null,Object? actions = null,Object? ruleId = freezed,Object? support = freezed,}) {
  return _then(UrgentMessage(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,actions: null == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as List<UrgentAction>,ruleId: freezed == ruleId ? _self.ruleId : ruleId // ignore: cast_nullable_to_non_nullable
as RedFlagRule?,support: freezed == support ? _self.support : support // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UrgentMessage].
extension UrgentMessagePatterns on UrgentMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UrgentMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UrgentMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UrgentMessage value)  $default,){
final _that = this;
switch (_that) {
case _UrgentMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UrgentMessage value)?  $default,){
final _that = this;
switch (_that) {
case _UrgentMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String body,  List<UrgentAction> actions,  RedFlagRule? ruleId,  String? support)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UrgentMessage() when $default != null:
return $default(_that.title,_that.body,_that.actions,_that.ruleId,_that.support);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String body,  List<UrgentAction> actions,  RedFlagRule? ruleId,  String? support)  $default,) {final _that = this;
switch (_that) {
case _UrgentMessage():
return $default(_that.title,_that.body,_that.actions,_that.ruleId,_that.support);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String body,  List<UrgentAction> actions,  RedFlagRule? ruleId,  String? support)?  $default,) {final _that = this;
switch (_that) {
case _UrgentMessage() when $default != null:
return $default(_that.title,_that.body,_that.actions,_that.ruleId,_that.support);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UrgentMessage implements UrgentMessage {
  const _UrgentMessage({required this.title, required this.body,  List<UrgentAction> actions = const <UrgentAction>[], this.ruleId, this.support}): _actions = actions;
  factory _UrgentMessage.fromJson(Map<String, dynamic> json) => _$UrgentMessageFromJson(json);

@override final  String title;
@override final  String body;
 final  List<UrgentAction> _actions;
@override@JsonKey() List<UrgentAction> get actions {
  if (_actions is EqualUnmodifiableListView) return _actions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actions);
}

@override final  RedFlagRule? ruleId;
@override final  String? support;

/// Create a copy of UrgentMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UrgentMessageCopyWith<_UrgentMessage> get copyWith => __$UrgentMessageCopyWithImpl<_UrgentMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UrgentMessageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UrgentMessage&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other.actions, _actions)&&(identical(other.ruleId, ruleId) || other.ruleId == ruleId)&&(identical(other.support, support) || other.support == support));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,body,const DeepCollectionEquality().hash(_actions),ruleId,support);
}

@override
String toString() {
    return 'UrgentMessage(title: $title, body: $body, actions: $actions, ruleId: $ruleId, support: $support)';
}


}

/// @nodoc
abstract mixin class _$UrgentMessageCopyWith<$Res> implements $UrgentMessageCopyWith<$Res> {
  factory _$UrgentMessageCopyWith(_UrgentMessage value, $Res Function(_UrgentMessage) _then) = __$UrgentMessageCopyWithImpl;
@override @useResult
$Res call({
 String title, String body, List<UrgentAction> actions, RedFlagRule? ruleId, String? support
});




}
/// @nodoc
class __$UrgentMessageCopyWithImpl<$Res>
    implements _$UrgentMessageCopyWith<$Res> {
  __$UrgentMessageCopyWithImpl(this._self, this._then);

  final _UrgentMessage _self;
  final $Res Function(_UrgentMessage) _then;

/// Create a copy of UrgentMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? body = null,Object? actions = null,Object? ruleId = freezed,Object? support = freezed,}) {
  return _then(_UrgentMessage(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,actions: null == actions ? _self._actions : actions // ignore: cast_nullable_to_non_nullable
as List<UrgentAction>,ruleId: freezed == ruleId ? _self.ruleId : ruleId // ignore: cast_nullable_to_non_nullable
as RedFlagRule?,support: freezed == support ? _self.support : support // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$IntakeTurn {

 String get reply; SessionStatus get status; double get progress;/// True when the patient flow ends (urgent, or intake finished).
 bool get done; UrgentMessage? get urgent;/// Optional diagnostics: how this turn's intake output was obtained.
/// Null when absent, null or an unknown value.
@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ParsePath? get parsePath;/// Optional diagnostics, set only on the turn that drafted the brief.
@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ParsePath? get briefParsePath;
/// Create a copy of IntakeTurn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntakeTurnCopyWith<IntakeTurn> get copyWith => _$IntakeTurnCopyWithImpl<IntakeTurn>(this as IntakeTurn, _$identity);

  /// Serializes this IntakeTurn to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IntakeTurn;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IntakeTurn&&(identical(other.reply, _this.reply) || other.reply == _this.reply)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.progress, _this.progress) || other.progress == _this.progress)&&(identical(other.done, _this.done) || other.done == _this.done)&&(identical(other.urgent, _this.urgent) || other.urgent == _this.urgent)&&(identical(other.parsePath, _this.parsePath) || other.parsePath == _this.parsePath)&&(identical(other.briefParsePath, _this.briefParsePath) || other.briefParsePath == _this.briefParsePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IntakeTurn;
  return Object.hash(runtimeType,_this.reply,_this.status,_this.progress,_this.done,_this.urgent,_this.parsePath,_this.briefParsePath);
}

@override
String toString() {
  final _this = this as IntakeTurn;
  return 'IntakeTurn(reply: ${_this.reply}, status: ${_this.status}, progress: ${_this.progress}, done: ${_this.done}, urgent: ${_this.urgent}, parsePath: ${_this.parsePath}, briefParsePath: ${_this.briefParsePath})';
}


}

/// @nodoc
abstract mixin class $IntakeTurnCopyWith<$Res>  {
  factory $IntakeTurnCopyWith(IntakeTurn value, $Res Function(IntakeTurn) _then) = _$IntakeTurnCopyWithImpl;
@useResult
$Res call({
 String reply, SessionStatus status, double progress, bool done, UrgentMessage? urgent,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ParsePath? parsePath,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ParsePath? briefParsePath
});


$UrgentMessageCopyWith<$Res>? get urgent;

}
/// @nodoc
class _$IntakeTurnCopyWithImpl<$Res>
    implements $IntakeTurnCopyWith<$Res> {
  _$IntakeTurnCopyWithImpl(this._self, this._then);

  final IntakeTurn _self;
  final $Res Function(IntakeTurn) _then;

/// Create a copy of IntakeTurn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reply = null,Object? status = null,Object? progress = null,Object? done = null,Object? urgent = freezed,Object? parsePath = freezed,Object? briefParsePath = freezed,}) {
  return _then(IntakeTurn(
reply: null == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,urgent: freezed == urgent ? _self.urgent : urgent // ignore: cast_nullable_to_non_nullable
as UrgentMessage?,parsePath: freezed == parsePath ? _self.parsePath : parsePath // ignore: cast_nullable_to_non_nullable
as ParsePath?,briefParsePath: freezed == briefParsePath ? _self.briefParsePath : briefParsePath // ignore: cast_nullable_to_non_nullable
as ParsePath?,
  ));
}
/// Create a copy of IntakeTurn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UrgentMessageCopyWith<$Res>? get urgent {
    if (_self.urgent == null) {
    return null;
  }

  return $UrgentMessageCopyWith<$Res>(_self.urgent!, (value) {
    return _then(_self.copyWith(urgent: value));
  });
}
}


/// Adds pattern-matching-related methods to [IntakeTurn].
extension IntakeTurnPatterns on IntakeTurn {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IntakeTurn value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IntakeTurn() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IntakeTurn value)  $default,){
final _that = this;
switch (_that) {
case _IntakeTurn():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IntakeTurn value)?  $default,){
final _that = this;
switch (_that) {
case _IntakeTurn() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String reply,  SessionStatus status,  double progress,  bool done,  UrgentMessage? urgent, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ParsePath? parsePath, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ParsePath? briefParsePath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IntakeTurn() when $default != null:
return $default(_that.reply,_that.status,_that.progress,_that.done,_that.urgent,_that.parsePath,_that.briefParsePath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String reply,  SessionStatus status,  double progress,  bool done,  UrgentMessage? urgent, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ParsePath? parsePath, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ParsePath? briefParsePath)  $default,) {final _that = this;
switch (_that) {
case _IntakeTurn():
return $default(_that.reply,_that.status,_that.progress,_that.done,_that.urgent,_that.parsePath,_that.briefParsePath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String reply,  SessionStatus status,  double progress,  bool done,  UrgentMessage? urgent, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ParsePath? parsePath, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  ParsePath? briefParsePath)?  $default,) {final _that = this;
switch (_that) {
case _IntakeTurn() when $default != null:
return $default(_that.reply,_that.status,_that.progress,_that.done,_that.urgent,_that.parsePath,_that.briefParsePath);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IntakeTurn implements IntakeTurn {
  const _IntakeTurn({required this.reply, required this.status, this.progress = 0, this.done = false, this.urgent, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.parsePath, @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.briefParsePath});
  factory _IntakeTurn.fromJson(Map<String, dynamic> json) => _$IntakeTurnFromJson(json);

@override final  String reply;
@override final  SessionStatus status;
@override@JsonKey() final  double progress;
/// True when the patient flow ends (urgent, or intake finished).
@override@JsonKey() final  bool done;
@override final  UrgentMessage? urgent;
/// Optional diagnostics: how this turn's intake output was obtained.
/// Null when absent, null or an unknown value.
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  ParsePath? parsePath;
/// Optional diagnostics, set only on the turn that drafted the brief.
@override@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  ParsePath? briefParsePath;

/// Create a copy of IntakeTurn
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IntakeTurnCopyWith<_IntakeTurn> get copyWith => __$IntakeTurnCopyWithImpl<_IntakeTurn>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IntakeTurnToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IntakeTurn&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.done, done) || other.done == done)&&(identical(other.urgent, urgent) || other.urgent == urgent)&&(identical(other.parsePath, parsePath) || other.parsePath == parsePath)&&(identical(other.briefParsePath, briefParsePath) || other.briefParsePath == briefParsePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,reply,status,progress,done,urgent,parsePath,briefParsePath);
}

@override
String toString() {
    return 'IntakeTurn(reply: $reply, status: $status, progress: $progress, done: $done, urgent: $urgent, parsePath: $parsePath, briefParsePath: $briefParsePath)';
}


}

/// @nodoc
abstract mixin class _$IntakeTurnCopyWith<$Res> implements $IntakeTurnCopyWith<$Res> {
  factory _$IntakeTurnCopyWith(_IntakeTurn value, $Res Function(_IntakeTurn) _then) = __$IntakeTurnCopyWithImpl;
@override @useResult
$Res call({
 String reply, SessionStatus status, double progress, bool done, UrgentMessage? urgent,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ParsePath? parsePath,@JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue) ParsePath? briefParsePath
});


@override $UrgentMessageCopyWith<$Res>? get urgent;

}
/// @nodoc
class __$IntakeTurnCopyWithImpl<$Res>
    implements _$IntakeTurnCopyWith<$Res> {
  __$IntakeTurnCopyWithImpl(this._self, this._then);

  final _IntakeTurn _self;
  final $Res Function(_IntakeTurn) _then;

/// Create a copy of IntakeTurn
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reply = null,Object? status = null,Object? progress = null,Object? done = null,Object? urgent = freezed,Object? parsePath = freezed,Object? briefParsePath = freezed,}) {
  return _then(_IntakeTurn(
reply: null == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,urgent: freezed == urgent ? _self.urgent : urgent // ignore: cast_nullable_to_non_nullable
as UrgentMessage?,parsePath: freezed == parsePath ? _self.parsePath : parsePath // ignore: cast_nullable_to_non_nullable
as ParsePath?,briefParsePath: freezed == briefParsePath ? _self.briefParsePath : briefParsePath // ignore: cast_nullable_to_non_nullable
as ParsePath?,
  ));
}

/// Create a copy of IntakeTurn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UrgentMessageCopyWith<$Res>? get urgent {
    if (_self.urgent == null) {
    return null;
  }

  return $UrgentMessageCopyWith<$Res>(_self.urgent!, (value) {
    return _then(_self.copyWith(urgent: value));
  });
}
}

// dart format on
