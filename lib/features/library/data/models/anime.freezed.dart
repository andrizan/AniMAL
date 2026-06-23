// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'anime.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Anime {

 int get id; String get title;@JsonKey(name: 'main_picture') MainPicture? get mainPicture; double? get mean; int? get rank; int? get popularity;@JsonKey(name: 'num_episodes') int? get numEpisodes; String? get status; String? get rating;@JsonKey(name: 'media_type') String? get mediaType; Broadcast? get broadcast;@JsonKey(name: 'alternative_titles') AlternativeTitles? get alternativeTitles; List<Genre> get genres;/// Only populated when requesting the user's anime list or
/// anime detail with the `my_list_status` field.
@JsonKey(name: 'my_list_status') MyListStatus? get myListStatus;
/// Create a copy of Anime
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnimeCopyWith<Anime> get copyWith => _$AnimeCopyWithImpl<Anime>(this as Anime, _$identity);

  /// Serializes this Anime to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Anime&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.mainPicture, mainPicture) || other.mainPicture == mainPicture)&&(identical(other.mean, mean) || other.mean == mean)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.popularity, popularity) || other.popularity == popularity)&&(identical(other.numEpisodes, numEpisodes) || other.numEpisodes == numEpisodes)&&(identical(other.status, status) || other.status == status)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.broadcast, broadcast) || other.broadcast == broadcast)&&(identical(other.alternativeTitles, alternativeTitles) || other.alternativeTitles == alternativeTitles)&&const DeepCollectionEquality().equals(other.genres, genres)&&(identical(other.myListStatus, myListStatus) || other.myListStatus == myListStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,mainPicture,mean,rank,popularity,numEpisodes,status,rating,mediaType,broadcast,alternativeTitles,const DeepCollectionEquality().hash(genres),myListStatus);

@override
String toString() {
  return 'Anime(id: $id, title: $title, mainPicture: $mainPicture, mean: $mean, rank: $rank, popularity: $popularity, numEpisodes: $numEpisodes, status: $status, rating: $rating, mediaType: $mediaType, broadcast: $broadcast, alternativeTitles: $alternativeTitles, genres: $genres, myListStatus: $myListStatus)';
}


}

/// @nodoc
abstract mixin class $AnimeCopyWith<$Res>  {
  factory $AnimeCopyWith(Anime value, $Res Function(Anime) _then) = _$AnimeCopyWithImpl;
@useResult
$Res call({
 int id, String title,@JsonKey(name: 'main_picture') MainPicture? mainPicture, double? mean, int? rank, int? popularity,@JsonKey(name: 'num_episodes') int? numEpisodes, String? status, String? rating,@JsonKey(name: 'media_type') String? mediaType, Broadcast? broadcast,@JsonKey(name: 'alternative_titles') AlternativeTitles? alternativeTitles, List<Genre> genres,@JsonKey(name: 'my_list_status') MyListStatus? myListStatus
});


$MainPictureCopyWith<$Res>? get mainPicture;$BroadcastCopyWith<$Res>? get broadcast;$AlternativeTitlesCopyWith<$Res>? get alternativeTitles;$MyListStatusCopyWith<$Res>? get myListStatus;

}
/// @nodoc
class _$AnimeCopyWithImpl<$Res>
    implements $AnimeCopyWith<$Res> {
  _$AnimeCopyWithImpl(this._self, this._then);

  final Anime _self;
  final $Res Function(Anime) _then;

/// Create a copy of Anime
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? mainPicture = freezed,Object? mean = freezed,Object? rank = freezed,Object? popularity = freezed,Object? numEpisodes = freezed,Object? status = freezed,Object? rating = freezed,Object? mediaType = freezed,Object? broadcast = freezed,Object? alternativeTitles = freezed,Object? genres = null,Object? myListStatus = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,mainPicture: freezed == mainPicture ? _self.mainPicture : mainPicture // ignore: cast_nullable_to_non_nullable
as MainPicture?,mean: freezed == mean ? _self.mean : mean // ignore: cast_nullable_to_non_nullable
as double?,rank: freezed == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int?,popularity: freezed == popularity ? _self.popularity : popularity // ignore: cast_nullable_to_non_nullable
as int?,numEpisodes: freezed == numEpisodes ? _self.numEpisodes : numEpisodes // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as String?,mediaType: freezed == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String?,broadcast: freezed == broadcast ? _self.broadcast : broadcast // ignore: cast_nullable_to_non_nullable
as Broadcast?,alternativeTitles: freezed == alternativeTitles ? _self.alternativeTitles : alternativeTitles // ignore: cast_nullable_to_non_nullable
as AlternativeTitles?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<Genre>,myListStatus: freezed == myListStatus ? _self.myListStatus : myListStatus // ignore: cast_nullable_to_non_nullable
as MyListStatus?,
  ));
}
/// Create a copy of Anime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MainPictureCopyWith<$Res>? get mainPicture {
    if (_self.mainPicture == null) {
    return null;
  }

  return $MainPictureCopyWith<$Res>(_self.mainPicture!, (value) {
    return _then(_self.copyWith(mainPicture: value));
  });
}/// Create a copy of Anime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BroadcastCopyWith<$Res>? get broadcast {
    if (_self.broadcast == null) {
    return null;
  }

  return $BroadcastCopyWith<$Res>(_self.broadcast!, (value) {
    return _then(_self.copyWith(broadcast: value));
  });
}/// Create a copy of Anime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AlternativeTitlesCopyWith<$Res>? get alternativeTitles {
    if (_self.alternativeTitles == null) {
    return null;
  }

  return $AlternativeTitlesCopyWith<$Res>(_self.alternativeTitles!, (value) {
    return _then(_self.copyWith(alternativeTitles: value));
  });
}/// Create a copy of Anime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MyListStatusCopyWith<$Res>? get myListStatus {
    if (_self.myListStatus == null) {
    return null;
  }

  return $MyListStatusCopyWith<$Res>(_self.myListStatus!, (value) {
    return _then(_self.copyWith(myListStatus: value));
  });
}
}


/// Adds pattern-matching-related methods to [Anime].
extension AnimePatterns on Anime {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Anime value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Anime() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Anime value)  $default,){
final _that = this;
switch (_that) {
case _Anime():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Anime value)?  $default,){
final _that = this;
switch (_that) {
case _Anime() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title, @JsonKey(name: 'main_picture')  MainPicture? mainPicture,  double? mean,  int? rank,  int? popularity, @JsonKey(name: 'num_episodes')  int? numEpisodes,  String? status,  String? rating, @JsonKey(name: 'media_type')  String? mediaType,  Broadcast? broadcast, @JsonKey(name: 'alternative_titles')  AlternativeTitles? alternativeTitles,  List<Genre> genres, @JsonKey(name: 'my_list_status')  MyListStatus? myListStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Anime() when $default != null:
return $default(_that.id,_that.title,_that.mainPicture,_that.mean,_that.rank,_that.popularity,_that.numEpisodes,_that.status,_that.rating,_that.mediaType,_that.broadcast,_that.alternativeTitles,_that.genres,_that.myListStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title, @JsonKey(name: 'main_picture')  MainPicture? mainPicture,  double? mean,  int? rank,  int? popularity, @JsonKey(name: 'num_episodes')  int? numEpisodes,  String? status,  String? rating, @JsonKey(name: 'media_type')  String? mediaType,  Broadcast? broadcast, @JsonKey(name: 'alternative_titles')  AlternativeTitles? alternativeTitles,  List<Genre> genres, @JsonKey(name: 'my_list_status')  MyListStatus? myListStatus)  $default,) {final _that = this;
switch (_that) {
case _Anime():
return $default(_that.id,_that.title,_that.mainPicture,_that.mean,_that.rank,_that.popularity,_that.numEpisodes,_that.status,_that.rating,_that.mediaType,_that.broadcast,_that.alternativeTitles,_that.genres,_that.myListStatus);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title, @JsonKey(name: 'main_picture')  MainPicture? mainPicture,  double? mean,  int? rank,  int? popularity, @JsonKey(name: 'num_episodes')  int? numEpisodes,  String? status,  String? rating, @JsonKey(name: 'media_type')  String? mediaType,  Broadcast? broadcast, @JsonKey(name: 'alternative_titles')  AlternativeTitles? alternativeTitles,  List<Genre> genres, @JsonKey(name: 'my_list_status')  MyListStatus? myListStatus)?  $default,) {final _that = this;
switch (_that) {
case _Anime() when $default != null:
return $default(_that.id,_that.title,_that.mainPicture,_that.mean,_that.rank,_that.popularity,_that.numEpisodes,_that.status,_that.rating,_that.mediaType,_that.broadcast,_that.alternativeTitles,_that.genres,_that.myListStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Anime implements Anime {
  const _Anime({required this.id, required this.title, @JsonKey(name: 'main_picture') this.mainPicture, this.mean, this.rank, this.popularity, @JsonKey(name: 'num_episodes') this.numEpisodes, this.status, this.rating, @JsonKey(name: 'media_type') this.mediaType, this.broadcast, @JsonKey(name: 'alternative_titles') this.alternativeTitles, final  List<Genre> genres = const [], @JsonKey(name: 'my_list_status') this.myListStatus}): _genres = genres;
  factory _Anime.fromJson(Map<String, dynamic> json) => _$AnimeFromJson(json);

@override final  int id;
@override final  String title;
@override@JsonKey(name: 'main_picture') final  MainPicture? mainPicture;
@override final  double? mean;
@override final  int? rank;
@override final  int? popularity;
@override@JsonKey(name: 'num_episodes') final  int? numEpisodes;
@override final  String? status;
@override final  String? rating;
@override@JsonKey(name: 'media_type') final  String? mediaType;
@override final  Broadcast? broadcast;
@override@JsonKey(name: 'alternative_titles') final  AlternativeTitles? alternativeTitles;
 final  List<Genre> _genres;
@override@JsonKey() List<Genre> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

/// Only populated when requesting the user's anime list or
/// anime detail with the `my_list_status` field.
@override@JsonKey(name: 'my_list_status') final  MyListStatus? myListStatus;

/// Create a copy of Anime
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnimeCopyWith<_Anime> get copyWith => __$AnimeCopyWithImpl<_Anime>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnimeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Anime&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.mainPicture, mainPicture) || other.mainPicture == mainPicture)&&(identical(other.mean, mean) || other.mean == mean)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.popularity, popularity) || other.popularity == popularity)&&(identical(other.numEpisodes, numEpisodes) || other.numEpisodes == numEpisodes)&&(identical(other.status, status) || other.status == status)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.broadcast, broadcast) || other.broadcast == broadcast)&&(identical(other.alternativeTitles, alternativeTitles) || other.alternativeTitles == alternativeTitles)&&const DeepCollectionEquality().equals(other._genres, _genres)&&(identical(other.myListStatus, myListStatus) || other.myListStatus == myListStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,mainPicture,mean,rank,popularity,numEpisodes,status,rating,mediaType,broadcast,alternativeTitles,const DeepCollectionEquality().hash(_genres),myListStatus);

@override
String toString() {
  return 'Anime(id: $id, title: $title, mainPicture: $mainPicture, mean: $mean, rank: $rank, popularity: $popularity, numEpisodes: $numEpisodes, status: $status, rating: $rating, mediaType: $mediaType, broadcast: $broadcast, alternativeTitles: $alternativeTitles, genres: $genres, myListStatus: $myListStatus)';
}


}

/// @nodoc
abstract mixin class _$AnimeCopyWith<$Res> implements $AnimeCopyWith<$Res> {
  factory _$AnimeCopyWith(_Anime value, $Res Function(_Anime) _then) = __$AnimeCopyWithImpl;
@override @useResult
$Res call({
 int id, String title,@JsonKey(name: 'main_picture') MainPicture? mainPicture, double? mean, int? rank, int? popularity,@JsonKey(name: 'num_episodes') int? numEpisodes, String? status, String? rating,@JsonKey(name: 'media_type') String? mediaType, Broadcast? broadcast,@JsonKey(name: 'alternative_titles') AlternativeTitles? alternativeTitles, List<Genre> genres,@JsonKey(name: 'my_list_status') MyListStatus? myListStatus
});


@override $MainPictureCopyWith<$Res>? get mainPicture;@override $BroadcastCopyWith<$Res>? get broadcast;@override $AlternativeTitlesCopyWith<$Res>? get alternativeTitles;@override $MyListStatusCopyWith<$Res>? get myListStatus;

}
/// @nodoc
class __$AnimeCopyWithImpl<$Res>
    implements _$AnimeCopyWith<$Res> {
  __$AnimeCopyWithImpl(this._self, this._then);

  final _Anime _self;
  final $Res Function(_Anime) _then;

/// Create a copy of Anime
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? mainPicture = freezed,Object? mean = freezed,Object? rank = freezed,Object? popularity = freezed,Object? numEpisodes = freezed,Object? status = freezed,Object? rating = freezed,Object? mediaType = freezed,Object? broadcast = freezed,Object? alternativeTitles = freezed,Object? genres = null,Object? myListStatus = freezed,}) {
  return _then(_Anime(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,mainPicture: freezed == mainPicture ? _self.mainPicture : mainPicture // ignore: cast_nullable_to_non_nullable
as MainPicture?,mean: freezed == mean ? _self.mean : mean // ignore: cast_nullable_to_non_nullable
as double?,rank: freezed == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int?,popularity: freezed == popularity ? _self.popularity : popularity // ignore: cast_nullable_to_non_nullable
as int?,numEpisodes: freezed == numEpisodes ? _self.numEpisodes : numEpisodes // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as String?,mediaType: freezed == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String?,broadcast: freezed == broadcast ? _self.broadcast : broadcast // ignore: cast_nullable_to_non_nullable
as Broadcast?,alternativeTitles: freezed == alternativeTitles ? _self.alternativeTitles : alternativeTitles // ignore: cast_nullable_to_non_nullable
as AlternativeTitles?,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<Genre>,myListStatus: freezed == myListStatus ? _self.myListStatus : myListStatus // ignore: cast_nullable_to_non_nullable
as MyListStatus?,
  ));
}

/// Create a copy of Anime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MainPictureCopyWith<$Res>? get mainPicture {
    if (_self.mainPicture == null) {
    return null;
  }

  return $MainPictureCopyWith<$Res>(_self.mainPicture!, (value) {
    return _then(_self.copyWith(mainPicture: value));
  });
}/// Create a copy of Anime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BroadcastCopyWith<$Res>? get broadcast {
    if (_self.broadcast == null) {
    return null;
  }

  return $BroadcastCopyWith<$Res>(_self.broadcast!, (value) {
    return _then(_self.copyWith(broadcast: value));
  });
}/// Create a copy of Anime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AlternativeTitlesCopyWith<$Res>? get alternativeTitles {
    if (_self.alternativeTitles == null) {
    return null;
  }

  return $AlternativeTitlesCopyWith<$Res>(_self.alternativeTitles!, (value) {
    return _then(_self.copyWith(alternativeTitles: value));
  });
}/// Create a copy of Anime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MyListStatusCopyWith<$Res>? get myListStatus {
    if (_self.myListStatus == null) {
    return null;
  }

  return $MyListStatusCopyWith<$Res>(_self.myListStatus!, (value) {
    return _then(_self.copyWith(myListStatus: value));
  });
}
}


/// @nodoc
mixin _$MainPicture {

 String? get medium; String? get large;
/// Create a copy of MainPicture
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MainPictureCopyWith<MainPicture> get copyWith => _$MainPictureCopyWithImpl<MainPicture>(this as MainPicture, _$identity);

  /// Serializes this MainPicture to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MainPicture&&(identical(other.medium, medium) || other.medium == medium)&&(identical(other.large, large) || other.large == large));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,medium,large);

@override
String toString() {
  return 'MainPicture(medium: $medium, large: $large)';
}


}

/// @nodoc
abstract mixin class $MainPictureCopyWith<$Res>  {
  factory $MainPictureCopyWith(MainPicture value, $Res Function(MainPicture) _then) = _$MainPictureCopyWithImpl;
@useResult
$Res call({
 String? medium, String? large
});




}
/// @nodoc
class _$MainPictureCopyWithImpl<$Res>
    implements $MainPictureCopyWith<$Res> {
  _$MainPictureCopyWithImpl(this._self, this._then);

  final MainPicture _self;
  final $Res Function(MainPicture) _then;

/// Create a copy of MainPicture
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? medium = freezed,Object? large = freezed,}) {
  return _then(_self.copyWith(
medium: freezed == medium ? _self.medium : medium // ignore: cast_nullable_to_non_nullable
as String?,large: freezed == large ? _self.large : large // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MainPicture].
extension MainPicturePatterns on MainPicture {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MainPicture value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MainPicture() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MainPicture value)  $default,){
final _that = this;
switch (_that) {
case _MainPicture():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MainPicture value)?  $default,){
final _that = this;
switch (_that) {
case _MainPicture() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? medium,  String? large)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MainPicture() when $default != null:
return $default(_that.medium,_that.large);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? medium,  String? large)  $default,) {final _that = this;
switch (_that) {
case _MainPicture():
return $default(_that.medium,_that.large);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? medium,  String? large)?  $default,) {final _that = this;
switch (_that) {
case _MainPicture() when $default != null:
return $default(_that.medium,_that.large);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MainPicture implements MainPicture {
  const _MainPicture({this.medium, this.large});
  factory _MainPicture.fromJson(Map<String, dynamic> json) => _$MainPictureFromJson(json);

@override final  String? medium;
@override final  String? large;

/// Create a copy of MainPicture
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MainPictureCopyWith<_MainPicture> get copyWith => __$MainPictureCopyWithImpl<_MainPicture>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MainPictureToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MainPicture&&(identical(other.medium, medium) || other.medium == medium)&&(identical(other.large, large) || other.large == large));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,medium,large);

@override
String toString() {
  return 'MainPicture(medium: $medium, large: $large)';
}


}

/// @nodoc
abstract mixin class _$MainPictureCopyWith<$Res> implements $MainPictureCopyWith<$Res> {
  factory _$MainPictureCopyWith(_MainPicture value, $Res Function(_MainPicture) _then) = __$MainPictureCopyWithImpl;
@override @useResult
$Res call({
 String? medium, String? large
});




}
/// @nodoc
class __$MainPictureCopyWithImpl<$Res>
    implements _$MainPictureCopyWith<$Res> {
  __$MainPictureCopyWithImpl(this._self, this._then);

  final _MainPicture _self;
  final $Res Function(_MainPicture) _then;

/// Create a copy of MainPicture
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? medium = freezed,Object? large = freezed,}) {
  return _then(_MainPicture(
medium: freezed == medium ? _self.medium : medium // ignore: cast_nullable_to_non_nullable
as String?,large: freezed == large ? _self.large : large // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AlternativeTitles {

 String? get en; String? get ja; List<String> get synonyms;
/// Create a copy of AlternativeTitles
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlternativeTitlesCopyWith<AlternativeTitles> get copyWith => _$AlternativeTitlesCopyWithImpl<AlternativeTitles>(this as AlternativeTitles, _$identity);

  /// Serializes this AlternativeTitles to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlternativeTitles&&(identical(other.en, en) || other.en == en)&&(identical(other.ja, ja) || other.ja == ja)&&const DeepCollectionEquality().equals(other.synonyms, synonyms));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,en,ja,const DeepCollectionEquality().hash(synonyms));

@override
String toString() {
  return 'AlternativeTitles(en: $en, ja: $ja, synonyms: $synonyms)';
}


}

/// @nodoc
abstract mixin class $AlternativeTitlesCopyWith<$Res>  {
  factory $AlternativeTitlesCopyWith(AlternativeTitles value, $Res Function(AlternativeTitles) _then) = _$AlternativeTitlesCopyWithImpl;
@useResult
$Res call({
 String? en, String? ja, List<String> synonyms
});




}
/// @nodoc
class _$AlternativeTitlesCopyWithImpl<$Res>
    implements $AlternativeTitlesCopyWith<$Res> {
  _$AlternativeTitlesCopyWithImpl(this._self, this._then);

  final AlternativeTitles _self;
  final $Res Function(AlternativeTitles) _then;

/// Create a copy of AlternativeTitles
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? en = freezed,Object? ja = freezed,Object? synonyms = null,}) {
  return _then(_self.copyWith(
en: freezed == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String?,ja: freezed == ja ? _self.ja : ja // ignore: cast_nullable_to_non_nullable
as String?,synonyms: null == synonyms ? _self.synonyms : synonyms // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AlternativeTitles].
extension AlternativeTitlesPatterns on AlternativeTitles {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AlternativeTitles value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AlternativeTitles() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AlternativeTitles value)  $default,){
final _that = this;
switch (_that) {
case _AlternativeTitles():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AlternativeTitles value)?  $default,){
final _that = this;
switch (_that) {
case _AlternativeTitles() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? en,  String? ja,  List<String> synonyms)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AlternativeTitles() when $default != null:
return $default(_that.en,_that.ja,_that.synonyms);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? en,  String? ja,  List<String> synonyms)  $default,) {final _that = this;
switch (_that) {
case _AlternativeTitles():
return $default(_that.en,_that.ja,_that.synonyms);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? en,  String? ja,  List<String> synonyms)?  $default,) {final _that = this;
switch (_that) {
case _AlternativeTitles() when $default != null:
return $default(_that.en,_that.ja,_that.synonyms);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AlternativeTitles implements AlternativeTitles {
  const _AlternativeTitles({this.en, this.ja, final  List<String> synonyms = const []}): _synonyms = synonyms;
  factory _AlternativeTitles.fromJson(Map<String, dynamic> json) => _$AlternativeTitlesFromJson(json);

@override final  String? en;
@override final  String? ja;
 final  List<String> _synonyms;
@override@JsonKey() List<String> get synonyms {
  if (_synonyms is EqualUnmodifiableListView) return _synonyms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_synonyms);
}


/// Create a copy of AlternativeTitles
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlternativeTitlesCopyWith<_AlternativeTitles> get copyWith => __$AlternativeTitlesCopyWithImpl<_AlternativeTitles>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AlternativeTitlesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AlternativeTitles&&(identical(other.en, en) || other.en == en)&&(identical(other.ja, ja) || other.ja == ja)&&const DeepCollectionEquality().equals(other._synonyms, _synonyms));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,en,ja,const DeepCollectionEquality().hash(_synonyms));

@override
String toString() {
  return 'AlternativeTitles(en: $en, ja: $ja, synonyms: $synonyms)';
}


}

/// @nodoc
abstract mixin class _$AlternativeTitlesCopyWith<$Res> implements $AlternativeTitlesCopyWith<$Res> {
  factory _$AlternativeTitlesCopyWith(_AlternativeTitles value, $Res Function(_AlternativeTitles) _then) = __$AlternativeTitlesCopyWithImpl;
@override @useResult
$Res call({
 String? en, String? ja, List<String> synonyms
});




}
/// @nodoc
class __$AlternativeTitlesCopyWithImpl<$Res>
    implements _$AlternativeTitlesCopyWith<$Res> {
  __$AlternativeTitlesCopyWithImpl(this._self, this._then);

  final _AlternativeTitles _self;
  final $Res Function(_AlternativeTitles) _then;

/// Create a copy of AlternativeTitles
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? en = freezed,Object? ja = freezed,Object? synonyms = null,}) {
  return _then(_AlternativeTitles(
en: freezed == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String?,ja: freezed == ja ? _self.ja : ja // ignore: cast_nullable_to_non_nullable
as String?,synonyms: null == synonyms ? _self._synonyms : synonyms // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
