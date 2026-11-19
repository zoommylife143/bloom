// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'intake_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IntakeState {

 IntakeConversation get conversation;
/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntakeStateCopyWith<IntakeState> get copyWith => _$IntakeStateCopyWithImpl<IntakeState>(this as IntakeState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as IntakeState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IntakeState&&(identical(other.conversation, _this.conversation) || other.conversation == _this.conversation));
}


@override
int get hashCode {
  final _this = this as IntakeState;
  return Object.hash(runtimeType,_this.conversation);
}

@override
String toString() {
  final _this = this as IntakeState;
  return 'IntakeState(conversation: ${_this.conversation})';
}


}

/// @nodoc
abstract mixin class $IntakeStateCopyWith<$Res>  {
  factory $IntakeStateCopyWith(IntakeState value, $Res Function(IntakeState) _then) = _$IntakeStateCopyWithImpl;
@useResult
$Res call({
 IntakeConversation conversation
});




}
/// @nodoc
class _$IntakeStateCopyWithImpl<$Res>
    implements $IntakeStateCopyWith<$Res> {
  _$IntakeStateCopyWithImpl(this._self, this._then);

  final IntakeState _self;
  final $Res Function(IntakeState) _then;

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversation = null,}) {
  return _then(_self.copyWith(
conversation: null == conversation ? _self.conversation : conversation // ignore: cast_nullable_to_non_nullable
as IntakeConversation,
  ));
}

}


/// Adds pattern-matching-related methods to [IntakeState].
extension IntakeStatePatterns on IntakeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( IntakeIdle value)?  idle,TResult Function( IntakeSending value)?  sending,TResult Function( IntakeWaiting value)?  waiting,TResult Function( IntakeError value)?  error,TResult Function( IntakeRouteRefused value)?  routeRefused,TResult Function( IntakeUrgent value)?  urgent,TResult Function( IntakeDone value)?  done,TResult Function( IntakeLocked value)?  locked,required TResult orElse(),}){
final _that = this;
switch (_that) {
case IntakeIdle() when idle != null:
return idle(_that);case IntakeSending() when sending != null:
return sending(_that);case IntakeWaiting() when waiting != null:
return waiting(_that);case IntakeError() when error != null:
return error(_that);case IntakeRouteRefused() when routeRefused != null:
return routeRefused(_that);case IntakeUrgent() when urgent != null:
return urgent(_that);case IntakeDone() when done != null:
return done(_that);case IntakeLocked() when locked != null:
return locked(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( IntakeIdle value)  idle,required TResult Function( IntakeSending value)  sending,required TResult Function( IntakeWaiting value)  waiting,required TResult Function( IntakeError value)  error,required TResult Function( IntakeRouteRefused value)  routeRefused,required TResult Function( IntakeUrgent value)  urgent,required TResult Function( IntakeDone value)  done,required TResult Function( IntakeLocked value)  locked,}){
final _that = this;
switch (_that) {
case IntakeIdle():
return idle(_that);case IntakeSending():
return sending(_that);case IntakeWaiting():
return waiting(_that);case IntakeError():
return error(_that);case IntakeRouteRefused():
return routeRefused(_that);case IntakeUrgent():
return urgent(_that);case IntakeDone():
return done(_that);case IntakeLocked():
return locked(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( IntakeIdle value)?  idle,TResult? Function( IntakeSending value)?  sending,TResult? Function( IntakeWaiting value)?  waiting,TResult? Function( IntakeError value)?  error,TResult? Function( IntakeRouteRefused value)?  routeRefused,TResult? Function( IntakeUrgent value)?  urgent,TResult? Function( IntakeDone value)?  done,TResult? Function( IntakeLocked value)?  locked,}){
final _that = this;
switch (_that) {
case IntakeIdle() when idle != null:
return idle(_that);case IntakeSending() when sending != null:
return sending(_that);case IntakeWaiting() when waiting != null:
return waiting(_that);case IntakeError() when error != null:
return error(_that);case IntakeRouteRefused() when routeRefused != null:
return routeRefused(_that);case IntakeUrgent() when urgent != null:
return urgent(_that);case IntakeDone() when done != null:
return done(_that);case IntakeLocked() when locked != null:
return locked(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( IntakeConversation conversation)?  idle,TResult Function( IntakeConversation conversation)?  sending,TResult Function( IntakeConversation conversation,  String pendingText)?  waiting,TResult Function( IntakeConversation conversation,  AppFailure failure,  String? pendingText)?  error,TResult Function( IntakeConversation conversation,  String? pendingText)?  routeRefused,TResult Function( IntakeConversation conversation,  UrgentMessage message)?  urgent,TResult Function( IntakeConversation conversation)?  done,TResult Function( IntakeConversation conversation)?  locked,required TResult orElse(),}) {final _that = this;
switch (_that) {
case IntakeIdle() when idle != null:
return idle(_that.conversation);case IntakeSending() when sending != null:
return sending(_that.conversation);case IntakeWaiting() when waiting != null:
return waiting(_that.conversation,_that.pendingText);case IntakeError() when error != null:
return error(_that.conversation,_that.failure,_that.pendingText);case IntakeRouteRefused() when routeRefused != null:
return routeRefused(_that.conversation,_that.pendingText);case IntakeUrgent() when urgent != null:
return urgent(_that.conversation,_that.message);case IntakeDone() when done != null:
return done(_that.conversation);case IntakeLocked() when locked != null:
return locked(_that.conversation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( IntakeConversation conversation)  idle,required TResult Function( IntakeConversation conversation)  sending,required TResult Function( IntakeConversation conversation,  String pendingText)  waiting,required TResult Function( IntakeConversation conversation,  AppFailure failure,  String? pendingText)  error,required TResult Function( IntakeConversation conversation,  String? pendingText)  routeRefused,required TResult Function( IntakeConversation conversation,  UrgentMessage message)  urgent,required TResult Function( IntakeConversation conversation)  done,required TResult Function( IntakeConversation conversation)  locked,}) {final _that = this;
switch (_that) {
case IntakeIdle():
return idle(_that.conversation);case IntakeSending():
return sending(_that.conversation);case IntakeWaiting():
return waiting(_that.conversation,_that.pendingText);case IntakeError():
return error(_that.conversation,_that.failure,_that.pendingText);case IntakeRouteRefused():
return routeRefused(_that.conversation,_that.pendingText);case IntakeUrgent():
return urgent(_that.conversation,_that.message);case IntakeDone():
return done(_that.conversation);case IntakeLocked():
return locked(_that.conversation);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( IntakeConversation conversation)?  idle,TResult? Function( IntakeConversation conversation)?  sending,TResult? Function( IntakeConversation conversation,  String pendingText)?  waiting,TResult? Function( IntakeConversation conversation,  AppFailure failure,  String? pendingText)?  error,TResult? Function( IntakeConversation conversation,  String? pendingText)?  routeRefused,TResult? Function( IntakeConversation conversation,  UrgentMessage message)?  urgent,TResult? Function( IntakeConversation conversation)?  done,TResult? Function( IntakeConversation conversation)?  locked,}) {final _that = this;
switch (_that) {
case IntakeIdle() when idle != null:
return idle(_that.conversation);case IntakeSending() when sending != null:
return sending(_that.conversation);case IntakeWaiting() when waiting != null:
return waiting(_that.conversation,_that.pendingText);case IntakeError() when error != null:
return error(_that.conversation,_that.failure,_that.pendingText);case IntakeRouteRefused() when routeRefused != null:
return routeRefused(_that.conversation,_that.pendingText);case IntakeUrgent() when urgent != null:
return urgent(_that.conversation,_that.message);case IntakeDone() when done != null:
return done(_that.conversation);case IntakeLocked() when locked != null:
return locked(_that.conversation);case _:
  return null;

}
}

}

/// @nodoc


class IntakeIdle implements IntakeState {
  const IntakeIdle({this.conversation = IntakeConversation.empty});
  

@override@JsonKey() final  IntakeConversation conversation;

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntakeIdleCopyWith<IntakeIdle> get copyWith => _$IntakeIdleCopyWithImpl<IntakeIdle>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is IntakeIdle&&(identical(other.conversation, conversation) || other.conversation == conversation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,conversation);
}

@override
String toString() {
    return 'IntakeState.idle(conversation: $conversation)';
}


}

/// @nodoc
abstract mixin class $IntakeIdleCopyWith<$Res> implements $IntakeStateCopyWith<$Res> {
  factory $IntakeIdleCopyWith(IntakeIdle value, $Res Function(IntakeIdle) _then) = _$IntakeIdleCopyWithImpl;
@override @useResult
$Res call({
 IntakeConversation conversation
});




}
/// @nodoc
class _$IntakeIdleCopyWithImpl<$Res>
    implements $IntakeIdleCopyWith<$Res> {
  _$IntakeIdleCopyWithImpl(this._self, this._then);

  final IntakeIdle _self;
  final $Res Function(IntakeIdle) _then;

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversation = null,}) {
  return _then(IntakeIdle(
conversation: null == conversation ? _self.conversation : conversation // ignore: cast_nullable_to_non_nullable
as IntakeConversation,
  ));
}


}

/// @nodoc


class IntakeSending implements IntakeState {
  const IntakeSending({this.conversation = IntakeConversation.empty});
  

@override@JsonKey() final  IntakeConversation conversation;

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntakeSendingCopyWith<IntakeSending> get copyWith => _$IntakeSendingCopyWithImpl<IntakeSending>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is IntakeSending&&(identical(other.conversation, conversation) || other.conversation == conversation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,conversation);
}

@override
String toString() {
    return 'IntakeState.sending(conversation: $conversation)';
}


}

/// @nodoc
abstract mixin class $IntakeSendingCopyWith<$Res> implements $IntakeStateCopyWith<$Res> {
  factory $IntakeSendingCopyWith(IntakeSending value, $Res Function(IntakeSending) _then) = _$IntakeSendingCopyWithImpl;
@override @useResult
$Res call({
 IntakeConversation conversation
});




}
/// @nodoc
class _$IntakeSendingCopyWithImpl<$Res>
    implements $IntakeSendingCopyWith<$Res> {
  _$IntakeSendingCopyWithImpl(this._self, this._then);

  final IntakeSending _self;
  final $Res Function(IntakeSending) _then;

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversation = null,}) {
  return _then(IntakeSending(
conversation: null == conversation ? _self.conversation : conversation // ignore: cast_nullable_to_non_nullable
as IntakeConversation,
  ));
}


}

/// @nodoc


class IntakeWaiting implements IntakeState {
  const IntakeWaiting({required this.conversation, required this.pendingText});
  

@override final  IntakeConversation conversation;
 final  String pendingText;

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntakeWaitingCopyWith<IntakeWaiting> get copyWith => _$IntakeWaitingCopyWithImpl<IntakeWaiting>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is IntakeWaiting&&(identical(other.conversation, conversation) || other.conversation == conversation)&&(identical(other.pendingText, pendingText) || other.pendingText == pendingText));
}


@override
int get hashCode {
    return Object.hash(runtimeType,conversation,pendingText);
}

@override
String toString() {
    return 'IntakeState.waiting(conversation: $conversation, pendingText: $pendingText)';
}


}

/// @nodoc
abstract mixin class $IntakeWaitingCopyWith<$Res> implements $IntakeStateCopyWith<$Res> {
  factory $IntakeWaitingCopyWith(IntakeWaiting value, $Res Function(IntakeWaiting) _then) = _$IntakeWaitingCopyWithImpl;
@override @useResult
$Res call({
 IntakeConversation conversation, String pendingText
});




}
/// @nodoc
class _$IntakeWaitingCopyWithImpl<$Res>
    implements $IntakeWaitingCopyWith<$Res> {
  _$IntakeWaitingCopyWithImpl(this._self, this._then);

  final IntakeWaiting _self;
  final $Res Function(IntakeWaiting) _then;

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversation = null,Object? pendingText = null,}) {
  return _then(IntakeWaiting(
conversation: null == conversation ? _self.conversation : conversation // ignore: cast_nullable_to_non_nullable
as IntakeConversation,pendingText: null == pendingText ? _self.pendingText : pendingText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class IntakeError implements IntakeState {
  const IntakeError({required this.conversation, required this.failure, this.pendingText});
  

@override final  IntakeConversation conversation;
 final  AppFailure failure;
 final  String? pendingText;

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntakeErrorCopyWith<IntakeError> get copyWith => _$IntakeErrorCopyWithImpl<IntakeError>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is IntakeError&&(identical(other.conversation, conversation) || other.conversation == conversation)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.pendingText, pendingText) || other.pendingText == pendingText));
}


@override
int get hashCode {
    return Object.hash(runtimeType,conversation,failure,pendingText);
}

@override
String toString() {
    return 'IntakeState.error(conversation: $conversation, failure: $failure, pendingText: $pendingText)';
}


}

/// @nodoc
abstract mixin class $IntakeErrorCopyWith<$Res> implements $IntakeStateCopyWith<$Res> {
  factory $IntakeErrorCopyWith(IntakeError value, $Res Function(IntakeError) _then) = _$IntakeErrorCopyWithImpl;
@override @useResult
$Res call({
 IntakeConversation conversation, AppFailure failure, String? pendingText
});




}
/// @nodoc
class _$IntakeErrorCopyWithImpl<$Res>
    implements $IntakeErrorCopyWith<$Res> {
  _$IntakeErrorCopyWithImpl(this._self, this._then);

  final IntakeError _self;
  final $Res Function(IntakeError) _then;

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversation = null,Object? failure = null,Object? pendingText = freezed,}) {
  return _then(IntakeError(
conversation: null == conversation ? _self.conversation : conversation // ignore: cast_nullable_to_non_nullable
as IntakeConversation,failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppFailure,pendingText: freezed == pendingText ? _self.pendingText : pendingText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class IntakeRouteRefused implements IntakeState {
  const IntakeRouteRefused({required this.conversation, this.pendingText});
  

@override final  IntakeConversation conversation;
 final  String? pendingText;

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntakeRouteRefusedCopyWith<IntakeRouteRefused> get copyWith => _$IntakeRouteRefusedCopyWithImpl<IntakeRouteRefused>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is IntakeRouteRefused&&(identical(other.conversation, conversation) || other.conversation == conversation)&&(identical(other.pendingText, pendingText) || other.pendingText == pendingText));
}


@override
int get hashCode {
    return Object.hash(runtimeType,conversation,pendingText);
}

@override
String toString() {
    return 'IntakeState.routeRefused(conversation: $conversation, pendingText: $pendingText)';
}


}

/// @nodoc
abstract mixin class $IntakeRouteRefusedCopyWith<$Res> implements $IntakeStateCopyWith<$Res> {
  factory $IntakeRouteRefusedCopyWith(IntakeRouteRefused value, $Res Function(IntakeRouteRefused) _then) = _$IntakeRouteRefusedCopyWithImpl;
@override @useResult
$Res call({
 IntakeConversation conversation, String? pendingText
});




}
/// @nodoc
class _$IntakeRouteRefusedCopyWithImpl<$Res>
    implements $IntakeRouteRefusedCopyWith<$Res> {
  _$IntakeRouteRefusedCopyWithImpl(this._self, this._then);

  final IntakeRouteRefused _self;
  final $Res Function(IntakeRouteRefused) _then;

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversation = null,Object? pendingText = freezed,}) {
  return _then(IntakeRouteRefused(
conversation: null == conversation ? _self.conversation : conversation // ignore: cast_nullable_to_non_nullable
as IntakeConversation,pendingText: freezed == pendingText ? _self.pendingText : pendingText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class IntakeUrgent implements IntakeState {
  const IntakeUrgent({required this.conversation, required this.message});
  

@override final  IntakeConversation conversation;
 final  UrgentMessage message;

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntakeUrgentCopyWith<IntakeUrgent> get copyWith => _$IntakeUrgentCopyWithImpl<IntakeUrgent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is IntakeUrgent&&(identical(other.conversation, conversation) || other.conversation == conversation)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,conversation,message);
}

@override
String toString() {
    return 'IntakeState.urgent(conversation: $conversation, message: $message)';
}


}

/// @nodoc
abstract mixin class $IntakeUrgentCopyWith<$Res> implements $IntakeStateCopyWith<$Res> {
  factory $IntakeUrgentCopyWith(IntakeUrgent value, $Res Function(IntakeUrgent) _then) = _$IntakeUrgentCopyWithImpl;
@override @useResult
$Res call({
 IntakeConversation conversation, UrgentMessage message
});


$UrgentMessageCopyWith<$Res> get message;

}
/// @nodoc
class _$IntakeUrgentCopyWithImpl<$Res>
    implements $IntakeUrgentCopyWith<$Res> {
  _$IntakeUrgentCopyWithImpl(this._self, this._then);

  final IntakeUrgent _self;
  final $Res Function(IntakeUrgent) _then;

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversation = null,Object? message = null,}) {
  return _then(IntakeUrgent(
conversation: null == conversation ? _self.conversation : conversation // ignore: cast_nullable_to_non_nullable
as IntakeConversation,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as UrgentMessage,
  ));
}

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UrgentMessageCopyWith<$Res> get message {
  
  return $UrgentMessageCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}

/// @nodoc


class IntakeDone implements IntakeState {
  const IntakeDone({required this.conversation});
  

@override final  IntakeConversation conversation;

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntakeDoneCopyWith<IntakeDone> get copyWith => _$IntakeDoneCopyWithImpl<IntakeDone>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is IntakeDone&&(identical(other.conversation, conversation) || other.conversation == conversation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,conversation);
}

@override
String toString() {
    return 'IntakeState.done(conversation: $conversation)';
}


}

/// @nodoc
abstract mixin class $IntakeDoneCopyWith<$Res> implements $IntakeStateCopyWith<$Res> {
  factory $IntakeDoneCopyWith(IntakeDone value, $Res Function(IntakeDone) _then) = _$IntakeDoneCopyWithImpl;
@override @useResult
$Res call({
 IntakeConversation conversation
});




}
/// @nodoc
class _$IntakeDoneCopyWithImpl<$Res>
    implements $IntakeDoneCopyWith<$Res> {
  _$IntakeDoneCopyWithImpl(this._self, this._then);

  final IntakeDone _self;
  final $Res Function(IntakeDone) _then;

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversation = null,}) {
  return _then(IntakeDone(
conversation: null == conversation ? _self.conversation : conversation // ignore: cast_nullable_to_non_nullable
as IntakeConversation,
  ));
}


}

/// @nodoc


class IntakeLocked implements IntakeState {
  const IntakeLocked({required this.conversation});
  

@override final  IntakeConversation conversation;

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntakeLockedCopyWith<IntakeLocked> get copyWith => _$IntakeLockedCopyWithImpl<IntakeLocked>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is IntakeLocked&&(identical(other.conversation, conversation) || other.conversation == conversation));
}


@override
int get hashCode {
    return Object.hash(runtimeType,conversation);
}

@override
String toString() {
    return 'IntakeState.locked(conversation: $conversation)';
}


}

/// @nodoc
abstract mixin class $IntakeLockedCopyWith<$Res> implements $IntakeStateCopyWith<$Res> {
  factory $IntakeLockedCopyWith(IntakeLocked value, $Res Function(IntakeLocked) _then) = _$IntakeLockedCopyWithImpl;
@override @useResult
$Res call({
 IntakeConversation conversation
});




}
/// @nodoc
class _$IntakeLockedCopyWithImpl<$Res>
    implements $IntakeLockedCopyWith<$Res> {
  _$IntakeLockedCopyWithImpl(this._self, this._then);

  final IntakeLocked _self;
  final $Res Function(IntakeLocked) _then;

/// Create a copy of IntakeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversation = null,}) {
  return _then(IntakeLocked(
conversation: null == conversation ? _self.conversation : conversation // ignore: cast_nullable_to_non_nullable
as IntakeConversation,
  ));
}


}

// dart format on
