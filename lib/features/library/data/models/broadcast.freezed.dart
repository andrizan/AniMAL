// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'broadcast.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Broadcast {

/// Day of the week, e.g. `monday`, `tuesday`, … `sunday`.
@JsonKey(name: 'day_of_week') String? get dayOfWeek;/// Start time in `HH:MM` (24h, JST) format, e.g. `01:35`.
@JsonKey(name: 'start_time') String? get startTime;
/// Create a copy of Broadcast
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BroadcastCopyWith<Broadcast> get copyWith => _$BroadcastCopyWithImpl<Broadcast>(this as Broadcast, _$identity);

  /// Serializes this Broadcast to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Broadcast&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.startTime, startTime) || other.startTime == startTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dayOfWeek,startTime);

@override
String toString() {
  return 'Broadcast(dayOfWeek: $dayOfWeek, startTime: $startTime)';
}


}

/// @nodoc
abstract mixin class $BroadcastCopyWith<$Res>  {
  factory $BroadcastCopyWith(Broadcast value, $Res Function(Broadcast) _then) = _$BroadcastCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'day_of_week') String? dayOfWeek,@JsonKey(name: 'start_time') String? startTime
});




}
/// @nodoc
class _$BroadcastCopyWithImpl<$Res>
    implements $BroadcastCopyWith<$Res> {
  _$BroadcastCopyWithImpl(this._self, this._then);

  final Broadcast _self;
  final $Res Function(Broadcast) _then;

/// Create a copy of Broadcast
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dayOfWeek = freezed,Object? startTime = freezed,}) {
  return _then(_self.copyWith(
dayOfWeek: freezed == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as String?,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Broadcast].
extension BroadcastPatterns on Broadcast {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Broadcast value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Broadcast() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Broadcast value)  $default,){
final _that = this;
switch (_that) {
case _Broadcast():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Broadcast value)?  $default,){
final _that = this;
switch (_that) {
case _Broadcast() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'day_of_week')  String? dayOfWeek, @JsonKey(name: 'start_time')  String? startTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Broadcast() when $default != null:
return $default(_that.dayOfWeek,_that.startTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'day_of_week')  String? dayOfWeek, @JsonKey(name: 'start_time')  String? startTime)  $default,) {final _that = this;
switch (_that) {
case _Broadcast():
return $default(_that.dayOfWeek,_that.startTime);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'day_of_week')  String? dayOfWeek, @JsonKey(name: 'start_time')  String? startTime)?  $default,) {final _that = this;
switch (_that) {
case _Broadcast() when $default != null:
return $default(_that.dayOfWeek,_that.startTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Broadcast implements Broadcast {
  const _Broadcast({@JsonKey(name: 'day_of_week') this.dayOfWeek, @JsonKey(name: 'start_time') this.startTime});
  factory _Broadcast.fromJson(Map<String, dynamic> json) => _$BroadcastFromJson(json);

/// Day of the week, e.g. `monday`, `tuesday`, … `sunday`.
@override@JsonKey(name: 'day_of_week') final  String? dayOfWeek;
/// Start time in `HH:MM` (24h, JST) format, e.g. `01:35`.
@override@JsonKey(name: 'start_time') final  String? startTime;

/// Create a copy of Broadcast
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BroadcastCopyWith<_Broadcast> get copyWith => __$BroadcastCopyWithImpl<_Broadcast>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BroadcastToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Broadcast&&(identical(other.dayOfWeek, dayOfWeek) || other.dayOfWeek == dayOfWeek)&&(identical(other.startTime, startTime) || other.startTime == startTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dayOfWeek,startTime);

@override
String toString() {
  return 'Broadcast(dayOfWeek: $dayOfWeek, startTime: $startTime)';
}


}

/// @nodoc
abstract mixin class _$BroadcastCopyWith<$Res> implements $BroadcastCopyWith<$Res> {
  factory _$BroadcastCopyWith(_Broadcast value, $Res Function(_Broadcast) _then) = __$BroadcastCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'day_of_week') String? dayOfWeek,@JsonKey(name: 'start_time') String? startTime
});




}
/// @nodoc
class __$BroadcastCopyWithImpl<$Res>
    implements _$BroadcastCopyWith<$Res> {
  __$BroadcastCopyWithImpl(this._self, this._then);

  final _Broadcast _self;
  final $Res Function(_Broadcast) _then;

/// Create a copy of Broadcast
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dayOfWeek = freezed,Object? startTime = freezed,}) {
  return _then(_Broadcast(
dayOfWeek: freezed == dayOfWeek ? _self.dayOfWeek : dayOfWeek // ignore: cast_nullable_to_non_nullable
as String?,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
