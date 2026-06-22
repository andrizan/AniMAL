// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mal_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MalUser {

 int get id;@JsonKey(name: 'name') String get name;@JsonKey(name: 'picture') String? get picture;@JsonKey(name: 'gender') String? get gender;@JsonKey(name: 'birthday') String? get birthday;@JsonKey(name: 'location') String? get location;@JsonKey(name: 'joined_at') String? get joinedAt;@JsonKey(name: 'anime_statistics') AnimeStatistics? get animeStatistics;
/// Create a copy of MalUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MalUserCopyWith<MalUser> get copyWith => _$MalUserCopyWithImpl<MalUser>(this as MalUser, _$identity);

  /// Serializes this MalUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MalUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.picture, picture) || other.picture == picture)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.birthday, birthday) || other.birthday == birthday)&&(identical(other.location, location) || other.location == location)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.animeStatistics, animeStatistics) || other.animeStatistics == animeStatistics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,picture,gender,birthday,location,joinedAt,animeStatistics);

@override
String toString() {
  return 'MalUser(id: $id, name: $name, picture: $picture, gender: $gender, birthday: $birthday, location: $location, joinedAt: $joinedAt, animeStatistics: $animeStatistics)';
}


}

/// @nodoc
abstract mixin class $MalUserCopyWith<$Res>  {
  factory $MalUserCopyWith(MalUser value, $Res Function(MalUser) _then) = _$MalUserCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'name') String name,@JsonKey(name: 'picture') String? picture,@JsonKey(name: 'gender') String? gender,@JsonKey(name: 'birthday') String? birthday,@JsonKey(name: 'location') String? location,@JsonKey(name: 'joined_at') String? joinedAt,@JsonKey(name: 'anime_statistics') AnimeStatistics? animeStatistics
});


$AnimeStatisticsCopyWith<$Res>? get animeStatistics;

}
/// @nodoc
class _$MalUserCopyWithImpl<$Res>
    implements $MalUserCopyWith<$Res> {
  _$MalUserCopyWithImpl(this._self, this._then);

  final MalUser _self;
  final $Res Function(MalUser) _then;

/// Create a copy of MalUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? picture = freezed,Object? gender = freezed,Object? birthday = freezed,Object? location = freezed,Object? joinedAt = freezed,Object? animeStatistics = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,picture: freezed == picture ? _self.picture : picture // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as String?,animeStatistics: freezed == animeStatistics ? _self.animeStatistics : animeStatistics // ignore: cast_nullable_to_non_nullable
as AnimeStatistics?,
  ));
}
/// Create a copy of MalUser
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnimeStatisticsCopyWith<$Res>? get animeStatistics {
    if (_self.animeStatistics == null) {
    return null;
  }

  return $AnimeStatisticsCopyWith<$Res>(_self.animeStatistics!, (value) {
    return _then(_self.copyWith(animeStatistics: value));
  });
}
}


/// Adds pattern-matching-related methods to [MalUser].
extension MalUserPatterns on MalUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MalUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MalUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MalUser value)  $default,){
final _that = this;
switch (_that) {
case _MalUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MalUser value)?  $default,){
final _that = this;
switch (_that) {
case _MalUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'name')  String name, @JsonKey(name: 'picture')  String? picture, @JsonKey(name: 'gender')  String? gender, @JsonKey(name: 'birthday')  String? birthday, @JsonKey(name: 'location')  String? location, @JsonKey(name: 'joined_at')  String? joinedAt, @JsonKey(name: 'anime_statistics')  AnimeStatistics? animeStatistics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MalUser() when $default != null:
return $default(_that.id,_that.name,_that.picture,_that.gender,_that.birthday,_that.location,_that.joinedAt,_that.animeStatistics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'name')  String name, @JsonKey(name: 'picture')  String? picture, @JsonKey(name: 'gender')  String? gender, @JsonKey(name: 'birthday')  String? birthday, @JsonKey(name: 'location')  String? location, @JsonKey(name: 'joined_at')  String? joinedAt, @JsonKey(name: 'anime_statistics')  AnimeStatistics? animeStatistics)  $default,) {final _that = this;
switch (_that) {
case _MalUser():
return $default(_that.id,_that.name,_that.picture,_that.gender,_that.birthday,_that.location,_that.joinedAt,_that.animeStatistics);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'name')  String name, @JsonKey(name: 'picture')  String? picture, @JsonKey(name: 'gender')  String? gender, @JsonKey(name: 'birthday')  String? birthday, @JsonKey(name: 'location')  String? location, @JsonKey(name: 'joined_at')  String? joinedAt, @JsonKey(name: 'anime_statistics')  AnimeStatistics? animeStatistics)?  $default,) {final _that = this;
switch (_that) {
case _MalUser() when $default != null:
return $default(_that.id,_that.name,_that.picture,_that.gender,_that.birthday,_that.location,_that.joinedAt,_that.animeStatistics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MalUser implements MalUser {
  const _MalUser({required this.id, @JsonKey(name: 'name') required this.name, @JsonKey(name: 'picture') this.picture, @JsonKey(name: 'gender') this.gender, @JsonKey(name: 'birthday') this.birthday, @JsonKey(name: 'location') this.location, @JsonKey(name: 'joined_at') this.joinedAt, @JsonKey(name: 'anime_statistics') this.animeStatistics});
  factory _MalUser.fromJson(Map<String, dynamic> json) => _$MalUserFromJson(json);

@override final  int id;
@override@JsonKey(name: 'name') final  String name;
@override@JsonKey(name: 'picture') final  String? picture;
@override@JsonKey(name: 'gender') final  String? gender;
@override@JsonKey(name: 'birthday') final  String? birthday;
@override@JsonKey(name: 'location') final  String? location;
@override@JsonKey(name: 'joined_at') final  String? joinedAt;
@override@JsonKey(name: 'anime_statistics') final  AnimeStatistics? animeStatistics;

/// Create a copy of MalUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MalUserCopyWith<_MalUser> get copyWith => __$MalUserCopyWithImpl<_MalUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MalUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MalUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.picture, picture) || other.picture == picture)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.birthday, birthday) || other.birthday == birthday)&&(identical(other.location, location) || other.location == location)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.animeStatistics, animeStatistics) || other.animeStatistics == animeStatistics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,picture,gender,birthday,location,joinedAt,animeStatistics);

@override
String toString() {
  return 'MalUser(id: $id, name: $name, picture: $picture, gender: $gender, birthday: $birthday, location: $location, joinedAt: $joinedAt, animeStatistics: $animeStatistics)';
}


}

/// @nodoc
abstract mixin class _$MalUserCopyWith<$Res> implements $MalUserCopyWith<$Res> {
  factory _$MalUserCopyWith(_MalUser value, $Res Function(_MalUser) _then) = __$MalUserCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'name') String name,@JsonKey(name: 'picture') String? picture,@JsonKey(name: 'gender') String? gender,@JsonKey(name: 'birthday') String? birthday,@JsonKey(name: 'location') String? location,@JsonKey(name: 'joined_at') String? joinedAt,@JsonKey(name: 'anime_statistics') AnimeStatistics? animeStatistics
});


@override $AnimeStatisticsCopyWith<$Res>? get animeStatistics;

}
/// @nodoc
class __$MalUserCopyWithImpl<$Res>
    implements _$MalUserCopyWith<$Res> {
  __$MalUserCopyWithImpl(this._self, this._then);

  final _MalUser _self;
  final $Res Function(_MalUser) _then;

/// Create a copy of MalUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? picture = freezed,Object? gender = freezed,Object? birthday = freezed,Object? location = freezed,Object? joinedAt = freezed,Object? animeStatistics = freezed,}) {
  return _then(_MalUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,picture: freezed == picture ? _self.picture : picture // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as String?,animeStatistics: freezed == animeStatistics ? _self.animeStatistics : animeStatistics // ignore: cast_nullable_to_non_nullable
as AnimeStatistics?,
  ));
}

/// Create a copy of MalUser
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnimeStatisticsCopyWith<$Res>? get animeStatistics {
    if (_self.animeStatistics == null) {
    return null;
  }

  return $AnimeStatisticsCopyWith<$Res>(_self.animeStatistics!, (value) {
    return _then(_self.copyWith(animeStatistics: value));
  });
}
}


/// @nodoc
mixin _$AnimeStatistics {

@JsonKey(name: 'num_items_watching') int? get numItemsWatching;@JsonKey(name: 'num_items_completed') int? get numItemsCompleted;@JsonKey(name: 'num_items_on_hold') int? get numItemsOnHold;@JsonKey(name: 'num_items_dropped') int? get numItemsDropped;@JsonKey(name: 'num_items_plan_to_watch') int? get numItemsPlanToWatch;@JsonKey(name: 'num_items') int? get numItems;@JsonKey(name: 'num_days_watched') double? get numDaysWatched;@JsonKey(name: 'num_days_watching') double? get numDaysWatching;@JsonKey(name: 'num_days_completed') double? get numDaysCompleted;@JsonKey(name: 'num_days_on_hold') double? get numDaysOnHold;@JsonKey(name: 'num_days_dropped') double? get numDaysDropped;@JsonKey(name: 'num_days') double? get numDays;@JsonKey(name: 'mean_score') double? get meanScore;@JsonKey(name: 'num_episodes') int? get numEpisodes;
/// Create a copy of AnimeStatistics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnimeStatisticsCopyWith<AnimeStatistics> get copyWith => _$AnimeStatisticsCopyWithImpl<AnimeStatistics>(this as AnimeStatistics, _$identity);

  /// Serializes this AnimeStatistics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnimeStatistics&&(identical(other.numItemsWatching, numItemsWatching) || other.numItemsWatching == numItemsWatching)&&(identical(other.numItemsCompleted, numItemsCompleted) || other.numItemsCompleted == numItemsCompleted)&&(identical(other.numItemsOnHold, numItemsOnHold) || other.numItemsOnHold == numItemsOnHold)&&(identical(other.numItemsDropped, numItemsDropped) || other.numItemsDropped == numItemsDropped)&&(identical(other.numItemsPlanToWatch, numItemsPlanToWatch) || other.numItemsPlanToWatch == numItemsPlanToWatch)&&(identical(other.numItems, numItems) || other.numItems == numItems)&&(identical(other.numDaysWatched, numDaysWatched) || other.numDaysWatched == numDaysWatched)&&(identical(other.numDaysWatching, numDaysWatching) || other.numDaysWatching == numDaysWatching)&&(identical(other.numDaysCompleted, numDaysCompleted) || other.numDaysCompleted == numDaysCompleted)&&(identical(other.numDaysOnHold, numDaysOnHold) || other.numDaysOnHold == numDaysOnHold)&&(identical(other.numDaysDropped, numDaysDropped) || other.numDaysDropped == numDaysDropped)&&(identical(other.numDays, numDays) || other.numDays == numDays)&&(identical(other.meanScore, meanScore) || other.meanScore == meanScore)&&(identical(other.numEpisodes, numEpisodes) || other.numEpisodes == numEpisodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,numItemsWatching,numItemsCompleted,numItemsOnHold,numItemsDropped,numItemsPlanToWatch,numItems,numDaysWatched,numDaysWatching,numDaysCompleted,numDaysOnHold,numDaysDropped,numDays,meanScore,numEpisodes);

@override
String toString() {
  return 'AnimeStatistics(numItemsWatching: $numItemsWatching, numItemsCompleted: $numItemsCompleted, numItemsOnHold: $numItemsOnHold, numItemsDropped: $numItemsDropped, numItemsPlanToWatch: $numItemsPlanToWatch, numItems: $numItems, numDaysWatched: $numDaysWatched, numDaysWatching: $numDaysWatching, numDaysCompleted: $numDaysCompleted, numDaysOnHold: $numDaysOnHold, numDaysDropped: $numDaysDropped, numDays: $numDays, meanScore: $meanScore, numEpisodes: $numEpisodes)';
}


}

/// @nodoc
abstract mixin class $AnimeStatisticsCopyWith<$Res>  {
  factory $AnimeStatisticsCopyWith(AnimeStatistics value, $Res Function(AnimeStatistics) _then) = _$AnimeStatisticsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'num_items_watching') int? numItemsWatching,@JsonKey(name: 'num_items_completed') int? numItemsCompleted,@JsonKey(name: 'num_items_on_hold') int? numItemsOnHold,@JsonKey(name: 'num_items_dropped') int? numItemsDropped,@JsonKey(name: 'num_items_plan_to_watch') int? numItemsPlanToWatch,@JsonKey(name: 'num_items') int? numItems,@JsonKey(name: 'num_days_watched') double? numDaysWatched,@JsonKey(name: 'num_days_watching') double? numDaysWatching,@JsonKey(name: 'num_days_completed') double? numDaysCompleted,@JsonKey(name: 'num_days_on_hold') double? numDaysOnHold,@JsonKey(name: 'num_days_dropped') double? numDaysDropped,@JsonKey(name: 'num_days') double? numDays,@JsonKey(name: 'mean_score') double? meanScore,@JsonKey(name: 'num_episodes') int? numEpisodes
});




}
/// @nodoc
class _$AnimeStatisticsCopyWithImpl<$Res>
    implements $AnimeStatisticsCopyWith<$Res> {
  _$AnimeStatisticsCopyWithImpl(this._self, this._then);

  final AnimeStatistics _self;
  final $Res Function(AnimeStatistics) _then;

/// Create a copy of AnimeStatistics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? numItemsWatching = freezed,Object? numItemsCompleted = freezed,Object? numItemsOnHold = freezed,Object? numItemsDropped = freezed,Object? numItemsPlanToWatch = freezed,Object? numItems = freezed,Object? numDaysWatched = freezed,Object? numDaysWatching = freezed,Object? numDaysCompleted = freezed,Object? numDaysOnHold = freezed,Object? numDaysDropped = freezed,Object? numDays = freezed,Object? meanScore = freezed,Object? numEpisodes = freezed,}) {
  return _then(_self.copyWith(
numItemsWatching: freezed == numItemsWatching ? _self.numItemsWatching : numItemsWatching // ignore: cast_nullable_to_non_nullable
as int?,numItemsCompleted: freezed == numItemsCompleted ? _self.numItemsCompleted : numItemsCompleted // ignore: cast_nullable_to_non_nullable
as int?,numItemsOnHold: freezed == numItemsOnHold ? _self.numItemsOnHold : numItemsOnHold // ignore: cast_nullable_to_non_nullable
as int?,numItemsDropped: freezed == numItemsDropped ? _self.numItemsDropped : numItemsDropped // ignore: cast_nullable_to_non_nullable
as int?,numItemsPlanToWatch: freezed == numItemsPlanToWatch ? _self.numItemsPlanToWatch : numItemsPlanToWatch // ignore: cast_nullable_to_non_nullable
as int?,numItems: freezed == numItems ? _self.numItems : numItems // ignore: cast_nullable_to_non_nullable
as int?,numDaysWatched: freezed == numDaysWatched ? _self.numDaysWatched : numDaysWatched // ignore: cast_nullable_to_non_nullable
as double?,numDaysWatching: freezed == numDaysWatching ? _self.numDaysWatching : numDaysWatching // ignore: cast_nullable_to_non_nullable
as double?,numDaysCompleted: freezed == numDaysCompleted ? _self.numDaysCompleted : numDaysCompleted // ignore: cast_nullable_to_non_nullable
as double?,numDaysOnHold: freezed == numDaysOnHold ? _self.numDaysOnHold : numDaysOnHold // ignore: cast_nullable_to_non_nullable
as double?,numDaysDropped: freezed == numDaysDropped ? _self.numDaysDropped : numDaysDropped // ignore: cast_nullable_to_non_nullable
as double?,numDays: freezed == numDays ? _self.numDays : numDays // ignore: cast_nullable_to_non_nullable
as double?,meanScore: freezed == meanScore ? _self.meanScore : meanScore // ignore: cast_nullable_to_non_nullable
as double?,numEpisodes: freezed == numEpisodes ? _self.numEpisodes : numEpisodes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AnimeStatistics].
extension AnimeStatisticsPatterns on AnimeStatistics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnimeStatistics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnimeStatistics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnimeStatistics value)  $default,){
final _that = this;
switch (_that) {
case _AnimeStatistics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnimeStatistics value)?  $default,){
final _that = this;
switch (_that) {
case _AnimeStatistics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'num_items_watching')  int? numItemsWatching, @JsonKey(name: 'num_items_completed')  int? numItemsCompleted, @JsonKey(name: 'num_items_on_hold')  int? numItemsOnHold, @JsonKey(name: 'num_items_dropped')  int? numItemsDropped, @JsonKey(name: 'num_items_plan_to_watch')  int? numItemsPlanToWatch, @JsonKey(name: 'num_items')  int? numItems, @JsonKey(name: 'num_days_watched')  double? numDaysWatched, @JsonKey(name: 'num_days_watching')  double? numDaysWatching, @JsonKey(name: 'num_days_completed')  double? numDaysCompleted, @JsonKey(name: 'num_days_on_hold')  double? numDaysOnHold, @JsonKey(name: 'num_days_dropped')  double? numDaysDropped, @JsonKey(name: 'num_days')  double? numDays, @JsonKey(name: 'mean_score')  double? meanScore, @JsonKey(name: 'num_episodes')  int? numEpisodes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnimeStatistics() when $default != null:
return $default(_that.numItemsWatching,_that.numItemsCompleted,_that.numItemsOnHold,_that.numItemsDropped,_that.numItemsPlanToWatch,_that.numItems,_that.numDaysWatched,_that.numDaysWatching,_that.numDaysCompleted,_that.numDaysOnHold,_that.numDaysDropped,_that.numDays,_that.meanScore,_that.numEpisodes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'num_items_watching')  int? numItemsWatching, @JsonKey(name: 'num_items_completed')  int? numItemsCompleted, @JsonKey(name: 'num_items_on_hold')  int? numItemsOnHold, @JsonKey(name: 'num_items_dropped')  int? numItemsDropped, @JsonKey(name: 'num_items_plan_to_watch')  int? numItemsPlanToWatch, @JsonKey(name: 'num_items')  int? numItems, @JsonKey(name: 'num_days_watched')  double? numDaysWatched, @JsonKey(name: 'num_days_watching')  double? numDaysWatching, @JsonKey(name: 'num_days_completed')  double? numDaysCompleted, @JsonKey(name: 'num_days_on_hold')  double? numDaysOnHold, @JsonKey(name: 'num_days_dropped')  double? numDaysDropped, @JsonKey(name: 'num_days')  double? numDays, @JsonKey(name: 'mean_score')  double? meanScore, @JsonKey(name: 'num_episodes')  int? numEpisodes)  $default,) {final _that = this;
switch (_that) {
case _AnimeStatistics():
return $default(_that.numItemsWatching,_that.numItemsCompleted,_that.numItemsOnHold,_that.numItemsDropped,_that.numItemsPlanToWatch,_that.numItems,_that.numDaysWatched,_that.numDaysWatching,_that.numDaysCompleted,_that.numDaysOnHold,_that.numDaysDropped,_that.numDays,_that.meanScore,_that.numEpisodes);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'num_items_watching')  int? numItemsWatching, @JsonKey(name: 'num_items_completed')  int? numItemsCompleted, @JsonKey(name: 'num_items_on_hold')  int? numItemsOnHold, @JsonKey(name: 'num_items_dropped')  int? numItemsDropped, @JsonKey(name: 'num_items_plan_to_watch')  int? numItemsPlanToWatch, @JsonKey(name: 'num_items')  int? numItems, @JsonKey(name: 'num_days_watched')  double? numDaysWatched, @JsonKey(name: 'num_days_watching')  double? numDaysWatching, @JsonKey(name: 'num_days_completed')  double? numDaysCompleted, @JsonKey(name: 'num_days_on_hold')  double? numDaysOnHold, @JsonKey(name: 'num_days_dropped')  double? numDaysDropped, @JsonKey(name: 'num_days')  double? numDays, @JsonKey(name: 'mean_score')  double? meanScore, @JsonKey(name: 'num_episodes')  int? numEpisodes)?  $default,) {final _that = this;
switch (_that) {
case _AnimeStatistics() when $default != null:
return $default(_that.numItemsWatching,_that.numItemsCompleted,_that.numItemsOnHold,_that.numItemsDropped,_that.numItemsPlanToWatch,_that.numItems,_that.numDaysWatched,_that.numDaysWatching,_that.numDaysCompleted,_that.numDaysOnHold,_that.numDaysDropped,_that.numDays,_that.meanScore,_that.numEpisodes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnimeStatistics implements AnimeStatistics {
  const _AnimeStatistics({@JsonKey(name: 'num_items_watching') this.numItemsWatching, @JsonKey(name: 'num_items_completed') this.numItemsCompleted, @JsonKey(name: 'num_items_on_hold') this.numItemsOnHold, @JsonKey(name: 'num_items_dropped') this.numItemsDropped, @JsonKey(name: 'num_items_plan_to_watch') this.numItemsPlanToWatch, @JsonKey(name: 'num_items') this.numItems, @JsonKey(name: 'num_days_watched') this.numDaysWatched, @JsonKey(name: 'num_days_watching') this.numDaysWatching, @JsonKey(name: 'num_days_completed') this.numDaysCompleted, @JsonKey(name: 'num_days_on_hold') this.numDaysOnHold, @JsonKey(name: 'num_days_dropped') this.numDaysDropped, @JsonKey(name: 'num_days') this.numDays, @JsonKey(name: 'mean_score') this.meanScore, @JsonKey(name: 'num_episodes') this.numEpisodes});
  factory _AnimeStatistics.fromJson(Map<String, dynamic> json) => _$AnimeStatisticsFromJson(json);

@override@JsonKey(name: 'num_items_watching') final  int? numItemsWatching;
@override@JsonKey(name: 'num_items_completed') final  int? numItemsCompleted;
@override@JsonKey(name: 'num_items_on_hold') final  int? numItemsOnHold;
@override@JsonKey(name: 'num_items_dropped') final  int? numItemsDropped;
@override@JsonKey(name: 'num_items_plan_to_watch') final  int? numItemsPlanToWatch;
@override@JsonKey(name: 'num_items') final  int? numItems;
@override@JsonKey(name: 'num_days_watched') final  double? numDaysWatched;
@override@JsonKey(name: 'num_days_watching') final  double? numDaysWatching;
@override@JsonKey(name: 'num_days_completed') final  double? numDaysCompleted;
@override@JsonKey(name: 'num_days_on_hold') final  double? numDaysOnHold;
@override@JsonKey(name: 'num_days_dropped') final  double? numDaysDropped;
@override@JsonKey(name: 'num_days') final  double? numDays;
@override@JsonKey(name: 'mean_score') final  double? meanScore;
@override@JsonKey(name: 'num_episodes') final  int? numEpisodes;

/// Create a copy of AnimeStatistics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnimeStatisticsCopyWith<_AnimeStatistics> get copyWith => __$AnimeStatisticsCopyWithImpl<_AnimeStatistics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnimeStatisticsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnimeStatistics&&(identical(other.numItemsWatching, numItemsWatching) || other.numItemsWatching == numItemsWatching)&&(identical(other.numItemsCompleted, numItemsCompleted) || other.numItemsCompleted == numItemsCompleted)&&(identical(other.numItemsOnHold, numItemsOnHold) || other.numItemsOnHold == numItemsOnHold)&&(identical(other.numItemsDropped, numItemsDropped) || other.numItemsDropped == numItemsDropped)&&(identical(other.numItemsPlanToWatch, numItemsPlanToWatch) || other.numItemsPlanToWatch == numItemsPlanToWatch)&&(identical(other.numItems, numItems) || other.numItems == numItems)&&(identical(other.numDaysWatched, numDaysWatched) || other.numDaysWatched == numDaysWatched)&&(identical(other.numDaysWatching, numDaysWatching) || other.numDaysWatching == numDaysWatching)&&(identical(other.numDaysCompleted, numDaysCompleted) || other.numDaysCompleted == numDaysCompleted)&&(identical(other.numDaysOnHold, numDaysOnHold) || other.numDaysOnHold == numDaysOnHold)&&(identical(other.numDaysDropped, numDaysDropped) || other.numDaysDropped == numDaysDropped)&&(identical(other.numDays, numDays) || other.numDays == numDays)&&(identical(other.meanScore, meanScore) || other.meanScore == meanScore)&&(identical(other.numEpisodes, numEpisodes) || other.numEpisodes == numEpisodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,numItemsWatching,numItemsCompleted,numItemsOnHold,numItemsDropped,numItemsPlanToWatch,numItems,numDaysWatched,numDaysWatching,numDaysCompleted,numDaysOnHold,numDaysDropped,numDays,meanScore,numEpisodes);

@override
String toString() {
  return 'AnimeStatistics(numItemsWatching: $numItemsWatching, numItemsCompleted: $numItemsCompleted, numItemsOnHold: $numItemsOnHold, numItemsDropped: $numItemsDropped, numItemsPlanToWatch: $numItemsPlanToWatch, numItems: $numItems, numDaysWatched: $numDaysWatched, numDaysWatching: $numDaysWatching, numDaysCompleted: $numDaysCompleted, numDaysOnHold: $numDaysOnHold, numDaysDropped: $numDaysDropped, numDays: $numDays, meanScore: $meanScore, numEpisodes: $numEpisodes)';
}


}

/// @nodoc
abstract mixin class _$AnimeStatisticsCopyWith<$Res> implements $AnimeStatisticsCopyWith<$Res> {
  factory _$AnimeStatisticsCopyWith(_AnimeStatistics value, $Res Function(_AnimeStatistics) _then) = __$AnimeStatisticsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'num_items_watching') int? numItemsWatching,@JsonKey(name: 'num_items_completed') int? numItemsCompleted,@JsonKey(name: 'num_items_on_hold') int? numItemsOnHold,@JsonKey(name: 'num_items_dropped') int? numItemsDropped,@JsonKey(name: 'num_items_plan_to_watch') int? numItemsPlanToWatch,@JsonKey(name: 'num_items') int? numItems,@JsonKey(name: 'num_days_watched') double? numDaysWatched,@JsonKey(name: 'num_days_watching') double? numDaysWatching,@JsonKey(name: 'num_days_completed') double? numDaysCompleted,@JsonKey(name: 'num_days_on_hold') double? numDaysOnHold,@JsonKey(name: 'num_days_dropped') double? numDaysDropped,@JsonKey(name: 'num_days') double? numDays,@JsonKey(name: 'mean_score') double? meanScore,@JsonKey(name: 'num_episodes') int? numEpisodes
});




}
/// @nodoc
class __$AnimeStatisticsCopyWithImpl<$Res>
    implements _$AnimeStatisticsCopyWith<$Res> {
  __$AnimeStatisticsCopyWithImpl(this._self, this._then);

  final _AnimeStatistics _self;
  final $Res Function(_AnimeStatistics) _then;

/// Create a copy of AnimeStatistics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? numItemsWatching = freezed,Object? numItemsCompleted = freezed,Object? numItemsOnHold = freezed,Object? numItemsDropped = freezed,Object? numItemsPlanToWatch = freezed,Object? numItems = freezed,Object? numDaysWatched = freezed,Object? numDaysWatching = freezed,Object? numDaysCompleted = freezed,Object? numDaysOnHold = freezed,Object? numDaysDropped = freezed,Object? numDays = freezed,Object? meanScore = freezed,Object? numEpisodes = freezed,}) {
  return _then(_AnimeStatistics(
numItemsWatching: freezed == numItemsWatching ? _self.numItemsWatching : numItemsWatching // ignore: cast_nullable_to_non_nullable
as int?,numItemsCompleted: freezed == numItemsCompleted ? _self.numItemsCompleted : numItemsCompleted // ignore: cast_nullable_to_non_nullable
as int?,numItemsOnHold: freezed == numItemsOnHold ? _self.numItemsOnHold : numItemsOnHold // ignore: cast_nullable_to_non_nullable
as int?,numItemsDropped: freezed == numItemsDropped ? _self.numItemsDropped : numItemsDropped // ignore: cast_nullable_to_non_nullable
as int?,numItemsPlanToWatch: freezed == numItemsPlanToWatch ? _self.numItemsPlanToWatch : numItemsPlanToWatch // ignore: cast_nullable_to_non_nullable
as int?,numItems: freezed == numItems ? _self.numItems : numItems // ignore: cast_nullable_to_non_nullable
as int?,numDaysWatched: freezed == numDaysWatched ? _self.numDaysWatched : numDaysWatched // ignore: cast_nullable_to_non_nullable
as double?,numDaysWatching: freezed == numDaysWatching ? _self.numDaysWatching : numDaysWatching // ignore: cast_nullable_to_non_nullable
as double?,numDaysCompleted: freezed == numDaysCompleted ? _self.numDaysCompleted : numDaysCompleted // ignore: cast_nullable_to_non_nullable
as double?,numDaysOnHold: freezed == numDaysOnHold ? _self.numDaysOnHold : numDaysOnHold // ignore: cast_nullable_to_non_nullable
as double?,numDaysDropped: freezed == numDaysDropped ? _self.numDaysDropped : numDaysDropped // ignore: cast_nullable_to_non_nullable
as double?,numDays: freezed == numDays ? _self.numDays : numDays // ignore: cast_nullable_to_non_nullable
as double?,meanScore: freezed == meanScore ? _self.meanScore : meanScore // ignore: cast_nullable_to_non_nullable
as double?,numEpisodes: freezed == numEpisodes ? _self.numEpisodes : numEpisodes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
