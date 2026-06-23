// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'my_list_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MyListStatus {

 WatchStatus get status;/// Number of episodes the user has watched.
@JsonKey(name: 'num_episodes_watched') int? get numEpisodesWatched;/// User's score (0–10), 0 means no score.
 int? get score;/// Whether the user is currently rewatching.
@JsonKey(name: 'is_rewatching') bool? get isRewatching;/// ISO-8601 timestamp of the last update.
@JsonKey(name: 'updated_at') String? get updatedAt;/// How many times the user has rewatched the anime.
@JsonKey(name: 'num_times_rewatched') int? get numTimesRewatched;/// Priority (0–2).
 int? get priority;/// Rewatch value (0–5).
@JsonKey(name: 'rewatch_value') int? get rewatchValue;/// Free-text notes the user attached to the entry.
 String? get comments;
/// Create a copy of MyListStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MyListStatusCopyWith<MyListStatus> get copyWith => _$MyListStatusCopyWithImpl<MyListStatus>(this as MyListStatus, _$identity);

  /// Serializes this MyListStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyListStatus&&(identical(other.status, status) || other.status == status)&&(identical(other.numEpisodesWatched, numEpisodesWatched) || other.numEpisodesWatched == numEpisodesWatched)&&(identical(other.score, score) || other.score == score)&&(identical(other.isRewatching, isRewatching) || other.isRewatching == isRewatching)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.numTimesRewatched, numTimesRewatched) || other.numTimesRewatched == numTimesRewatched)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.rewatchValue, rewatchValue) || other.rewatchValue == rewatchValue)&&(identical(other.comments, comments) || other.comments == comments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,numEpisodesWatched,score,isRewatching,updatedAt,numTimesRewatched,priority,rewatchValue,comments);

@override
String toString() {
  return 'MyListStatus(status: $status, numEpisodesWatched: $numEpisodesWatched, score: $score, isRewatching: $isRewatching, updatedAt: $updatedAt, numTimesRewatched: $numTimesRewatched, priority: $priority, rewatchValue: $rewatchValue, comments: $comments)';
}


}

/// @nodoc
abstract mixin class $MyListStatusCopyWith<$Res>  {
  factory $MyListStatusCopyWith(MyListStatus value, $Res Function(MyListStatus) _then) = _$MyListStatusCopyWithImpl;
@useResult
$Res call({
 WatchStatus status,@JsonKey(name: 'num_episodes_watched') int? numEpisodesWatched, int? score,@JsonKey(name: 'is_rewatching') bool? isRewatching,@JsonKey(name: 'updated_at') String? updatedAt,@JsonKey(name: 'num_times_rewatched') int? numTimesRewatched, int? priority,@JsonKey(name: 'rewatch_value') int? rewatchValue, String? comments
});




}
/// @nodoc
class _$MyListStatusCopyWithImpl<$Res>
    implements $MyListStatusCopyWith<$Res> {
  _$MyListStatusCopyWithImpl(this._self, this._then);

  final MyListStatus _self;
  final $Res Function(MyListStatus) _then;

/// Create a copy of MyListStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? numEpisodesWatched = freezed,Object? score = freezed,Object? isRewatching = freezed,Object? updatedAt = freezed,Object? numTimesRewatched = freezed,Object? priority = freezed,Object? rewatchValue = freezed,Object? comments = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WatchStatus,numEpisodesWatched: freezed == numEpisodesWatched ? _self.numEpisodesWatched : numEpisodesWatched // ignore: cast_nullable_to_non_nullable
as int?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int?,isRewatching: freezed == isRewatching ? _self.isRewatching : isRewatching // ignore: cast_nullable_to_non_nullable
as bool?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,numTimesRewatched: freezed == numTimesRewatched ? _self.numTimesRewatched : numTimesRewatched // ignore: cast_nullable_to_non_nullable
as int?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int?,rewatchValue: freezed == rewatchValue ? _self.rewatchValue : rewatchValue // ignore: cast_nullable_to_non_nullable
as int?,comments: freezed == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MyListStatus].
extension MyListStatusPatterns on MyListStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MyListStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MyListStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MyListStatus value)  $default,){
final _that = this;
switch (_that) {
case _MyListStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MyListStatus value)?  $default,){
final _that = this;
switch (_that) {
case _MyListStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WatchStatus status, @JsonKey(name: 'num_episodes_watched')  int? numEpisodesWatched,  int? score, @JsonKey(name: 'is_rewatching')  bool? isRewatching, @JsonKey(name: 'updated_at')  String? updatedAt, @JsonKey(name: 'num_times_rewatched')  int? numTimesRewatched,  int? priority, @JsonKey(name: 'rewatch_value')  int? rewatchValue,  String? comments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MyListStatus() when $default != null:
return $default(_that.status,_that.numEpisodesWatched,_that.score,_that.isRewatching,_that.updatedAt,_that.numTimesRewatched,_that.priority,_that.rewatchValue,_that.comments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WatchStatus status, @JsonKey(name: 'num_episodes_watched')  int? numEpisodesWatched,  int? score, @JsonKey(name: 'is_rewatching')  bool? isRewatching, @JsonKey(name: 'updated_at')  String? updatedAt, @JsonKey(name: 'num_times_rewatched')  int? numTimesRewatched,  int? priority, @JsonKey(name: 'rewatch_value')  int? rewatchValue,  String? comments)  $default,) {final _that = this;
switch (_that) {
case _MyListStatus():
return $default(_that.status,_that.numEpisodesWatched,_that.score,_that.isRewatching,_that.updatedAt,_that.numTimesRewatched,_that.priority,_that.rewatchValue,_that.comments);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WatchStatus status, @JsonKey(name: 'num_episodes_watched')  int? numEpisodesWatched,  int? score, @JsonKey(name: 'is_rewatching')  bool? isRewatching, @JsonKey(name: 'updated_at')  String? updatedAt, @JsonKey(name: 'num_times_rewatched')  int? numTimesRewatched,  int? priority, @JsonKey(name: 'rewatch_value')  int? rewatchValue,  String? comments)?  $default,) {final _that = this;
switch (_that) {
case _MyListStatus() when $default != null:
return $default(_that.status,_that.numEpisodesWatched,_that.score,_that.isRewatching,_that.updatedAt,_that.numTimesRewatched,_that.priority,_that.rewatchValue,_that.comments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MyListStatus implements MyListStatus {
  const _MyListStatus({required this.status, @JsonKey(name: 'num_episodes_watched') this.numEpisodesWatched, this.score, @JsonKey(name: 'is_rewatching') this.isRewatching, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'num_times_rewatched') this.numTimesRewatched, this.priority, @JsonKey(name: 'rewatch_value') this.rewatchValue, this.comments});
  factory _MyListStatus.fromJson(Map<String, dynamic> json) => _$MyListStatusFromJson(json);

@override final  WatchStatus status;
/// Number of episodes the user has watched.
@override@JsonKey(name: 'num_episodes_watched') final  int? numEpisodesWatched;
/// User's score (0–10), 0 means no score.
@override final  int? score;
/// Whether the user is currently rewatching.
@override@JsonKey(name: 'is_rewatching') final  bool? isRewatching;
/// ISO-8601 timestamp of the last update.
@override@JsonKey(name: 'updated_at') final  String? updatedAt;
/// How many times the user has rewatched the anime.
@override@JsonKey(name: 'num_times_rewatched') final  int? numTimesRewatched;
/// Priority (0–2).
@override final  int? priority;
/// Rewatch value (0–5).
@override@JsonKey(name: 'rewatch_value') final  int? rewatchValue;
/// Free-text notes the user attached to the entry.
@override final  String? comments;

/// Create a copy of MyListStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MyListStatusCopyWith<_MyListStatus> get copyWith => __$MyListStatusCopyWithImpl<_MyListStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MyListStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MyListStatus&&(identical(other.status, status) || other.status == status)&&(identical(other.numEpisodesWatched, numEpisodesWatched) || other.numEpisodesWatched == numEpisodesWatched)&&(identical(other.score, score) || other.score == score)&&(identical(other.isRewatching, isRewatching) || other.isRewatching == isRewatching)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.numTimesRewatched, numTimesRewatched) || other.numTimesRewatched == numTimesRewatched)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.rewatchValue, rewatchValue) || other.rewatchValue == rewatchValue)&&(identical(other.comments, comments) || other.comments == comments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,numEpisodesWatched,score,isRewatching,updatedAt,numTimesRewatched,priority,rewatchValue,comments);

@override
String toString() {
  return 'MyListStatus(status: $status, numEpisodesWatched: $numEpisodesWatched, score: $score, isRewatching: $isRewatching, updatedAt: $updatedAt, numTimesRewatched: $numTimesRewatched, priority: $priority, rewatchValue: $rewatchValue, comments: $comments)';
}


}

/// @nodoc
abstract mixin class _$MyListStatusCopyWith<$Res> implements $MyListStatusCopyWith<$Res> {
  factory _$MyListStatusCopyWith(_MyListStatus value, $Res Function(_MyListStatus) _then) = __$MyListStatusCopyWithImpl;
@override @useResult
$Res call({
 WatchStatus status,@JsonKey(name: 'num_episodes_watched') int? numEpisodesWatched, int? score,@JsonKey(name: 'is_rewatching') bool? isRewatching,@JsonKey(name: 'updated_at') String? updatedAt,@JsonKey(name: 'num_times_rewatched') int? numTimesRewatched, int? priority,@JsonKey(name: 'rewatch_value') int? rewatchValue, String? comments
});




}
/// @nodoc
class __$MyListStatusCopyWithImpl<$Res>
    implements _$MyListStatusCopyWith<$Res> {
  __$MyListStatusCopyWithImpl(this._self, this._then);

  final _MyListStatus _self;
  final $Res Function(_MyListStatus) _then;

/// Create a copy of MyListStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? numEpisodesWatched = freezed,Object? score = freezed,Object? isRewatching = freezed,Object? updatedAt = freezed,Object? numTimesRewatched = freezed,Object? priority = freezed,Object? rewatchValue = freezed,Object? comments = freezed,}) {
  return _then(_MyListStatus(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WatchStatus,numEpisodesWatched: freezed == numEpisodesWatched ? _self.numEpisodesWatched : numEpisodesWatched // ignore: cast_nullable_to_non_nullable
as int?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int?,isRewatching: freezed == isRewatching ? _self.isRewatching : isRewatching // ignore: cast_nullable_to_non_nullable
as bool?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,numTimesRewatched: freezed == numTimesRewatched ? _self.numTimesRewatched : numTimesRewatched // ignore: cast_nullable_to_non_nullable
as int?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int?,rewatchValue: freezed == rewatchValue ? _self.rewatchValue : rewatchValue // ignore: cast_nullable_to_non_nullable
as int?,comments: freezed == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
