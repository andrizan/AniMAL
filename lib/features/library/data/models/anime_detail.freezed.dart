// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'anime_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnimeDetail {

 int get id; String get title;@JsonKey(name: 'main_picture') MainPicture? get mainPicture; double? get mean; int? get rank; int? get popularity;@JsonKey(name: 'num_episodes') int? get numEpisodes; String? get status; String? get rating; String? get source; String? get synopsis;@JsonKey(name: 'start_date') String? get startDate;@JsonKey(name: 'end_date') String? get endDate;@JsonKey(name: 'media_type') String? get mediaType;@JsonKey(name: 'num_scoring_users') int? get numScoringUsers; List<Genre> get genres; Broadcast? get broadcast;@JsonKey(name: 'alternative_titles') AlternativeTitles? get alternativeTitles;@JsonKey(name: 'related_anime') List<RelatedAnime> get relatedAnime;@JsonKey(name: 'my_list_status') MyListStatus? get myListStatus;
/// Create a copy of AnimeDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnimeDetailCopyWith<AnimeDetail> get copyWith => _$AnimeDetailCopyWithImpl<AnimeDetail>(this as AnimeDetail, _$identity);

  /// Serializes this AnimeDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnimeDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.mainPicture, mainPicture) || other.mainPicture == mainPicture)&&(identical(other.mean, mean) || other.mean == mean)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.popularity, popularity) || other.popularity == popularity)&&(identical(other.numEpisodes, numEpisodes) || other.numEpisodes == numEpisodes)&&(identical(other.status, status) || other.status == status)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.source, source) || other.source == source)&&(identical(other.synopsis, synopsis) || other.synopsis == synopsis)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.numScoringUsers, numScoringUsers) || other.numScoringUsers == numScoringUsers)&&const DeepCollectionEquality().equals(other.genres, genres)&&(identical(other.broadcast, broadcast) || other.broadcast == broadcast)&&(identical(other.alternativeTitles, alternativeTitles) || other.alternativeTitles == alternativeTitles)&&const DeepCollectionEquality().equals(other.relatedAnime, relatedAnime)&&(identical(other.myListStatus, myListStatus) || other.myListStatus == myListStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,mainPicture,mean,rank,popularity,numEpisodes,status,rating,source,synopsis,startDate,endDate,mediaType,numScoringUsers,const DeepCollectionEquality().hash(genres),broadcast,alternativeTitles,const DeepCollectionEquality().hash(relatedAnime),myListStatus]);

@override
String toString() {
  return 'AnimeDetail(id: $id, title: $title, mainPicture: $mainPicture, mean: $mean, rank: $rank, popularity: $popularity, numEpisodes: $numEpisodes, status: $status, rating: $rating, source: $source, synopsis: $synopsis, startDate: $startDate, endDate: $endDate, mediaType: $mediaType, numScoringUsers: $numScoringUsers, genres: $genres, broadcast: $broadcast, alternativeTitles: $alternativeTitles, relatedAnime: $relatedAnime, myListStatus: $myListStatus)';
}


}

/// @nodoc
abstract mixin class $AnimeDetailCopyWith<$Res>  {
  factory $AnimeDetailCopyWith(AnimeDetail value, $Res Function(AnimeDetail) _then) = _$AnimeDetailCopyWithImpl;
@useResult
$Res call({
 int id, String title,@JsonKey(name: 'main_picture') MainPicture? mainPicture, double? mean, int? rank, int? popularity,@JsonKey(name: 'num_episodes') int? numEpisodes, String? status, String? rating, String? source, String? synopsis,@JsonKey(name: 'start_date') String? startDate,@JsonKey(name: 'end_date') String? endDate,@JsonKey(name: 'media_type') String? mediaType,@JsonKey(name: 'num_scoring_users') int? numScoringUsers, List<Genre> genres, Broadcast? broadcast,@JsonKey(name: 'alternative_titles') AlternativeTitles? alternativeTitles,@JsonKey(name: 'related_anime') List<RelatedAnime> relatedAnime,@JsonKey(name: 'my_list_status') MyListStatus? myListStatus
});


$MainPictureCopyWith<$Res>? get mainPicture;$BroadcastCopyWith<$Res>? get broadcast;$AlternativeTitlesCopyWith<$Res>? get alternativeTitles;$MyListStatusCopyWith<$Res>? get myListStatus;

}
/// @nodoc
class _$AnimeDetailCopyWithImpl<$Res>
    implements $AnimeDetailCopyWith<$Res> {
  _$AnimeDetailCopyWithImpl(this._self, this._then);

  final AnimeDetail _self;
  final $Res Function(AnimeDetail) _then;

/// Create a copy of AnimeDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? mainPicture = freezed,Object? mean = freezed,Object? rank = freezed,Object? popularity = freezed,Object? numEpisodes = freezed,Object? status = freezed,Object? rating = freezed,Object? source = freezed,Object? synopsis = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? mediaType = freezed,Object? numScoringUsers = freezed,Object? genres = null,Object? broadcast = freezed,Object? alternativeTitles = freezed,Object? relatedAnime = null,Object? myListStatus = freezed,}) {
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
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,synopsis: freezed == synopsis ? _self.synopsis : synopsis // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,mediaType: freezed == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String?,numScoringUsers: freezed == numScoringUsers ? _self.numScoringUsers : numScoringUsers // ignore: cast_nullable_to_non_nullable
as int?,genres: null == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<Genre>,broadcast: freezed == broadcast ? _self.broadcast : broadcast // ignore: cast_nullable_to_non_nullable
as Broadcast?,alternativeTitles: freezed == alternativeTitles ? _self.alternativeTitles : alternativeTitles // ignore: cast_nullable_to_non_nullable
as AlternativeTitles?,relatedAnime: null == relatedAnime ? _self.relatedAnime : relatedAnime // ignore: cast_nullable_to_non_nullable
as List<RelatedAnime>,myListStatus: freezed == myListStatus ? _self.myListStatus : myListStatus // ignore: cast_nullable_to_non_nullable
as MyListStatus?,
  ));
}
/// Create a copy of AnimeDetail
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
}/// Create a copy of AnimeDetail
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
}/// Create a copy of AnimeDetail
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
}/// Create a copy of AnimeDetail
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


/// Adds pattern-matching-related methods to [AnimeDetail].
extension AnimeDetailPatterns on AnimeDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnimeDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnimeDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnimeDetail value)  $default,){
final _that = this;
switch (_that) {
case _AnimeDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnimeDetail value)?  $default,){
final _that = this;
switch (_that) {
case _AnimeDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title, @JsonKey(name: 'main_picture')  MainPicture? mainPicture,  double? mean,  int? rank,  int? popularity, @JsonKey(name: 'num_episodes')  int? numEpisodes,  String? status,  String? rating,  String? source,  String? synopsis, @JsonKey(name: 'start_date')  String? startDate, @JsonKey(name: 'end_date')  String? endDate, @JsonKey(name: 'media_type')  String? mediaType, @JsonKey(name: 'num_scoring_users')  int? numScoringUsers,  List<Genre> genres,  Broadcast? broadcast, @JsonKey(name: 'alternative_titles')  AlternativeTitles? alternativeTitles, @JsonKey(name: 'related_anime')  List<RelatedAnime> relatedAnime, @JsonKey(name: 'my_list_status')  MyListStatus? myListStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnimeDetail() when $default != null:
return $default(_that.id,_that.title,_that.mainPicture,_that.mean,_that.rank,_that.popularity,_that.numEpisodes,_that.status,_that.rating,_that.source,_that.synopsis,_that.startDate,_that.endDate,_that.mediaType,_that.numScoringUsers,_that.genres,_that.broadcast,_that.alternativeTitles,_that.relatedAnime,_that.myListStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title, @JsonKey(name: 'main_picture')  MainPicture? mainPicture,  double? mean,  int? rank,  int? popularity, @JsonKey(name: 'num_episodes')  int? numEpisodes,  String? status,  String? rating,  String? source,  String? synopsis, @JsonKey(name: 'start_date')  String? startDate, @JsonKey(name: 'end_date')  String? endDate, @JsonKey(name: 'media_type')  String? mediaType, @JsonKey(name: 'num_scoring_users')  int? numScoringUsers,  List<Genre> genres,  Broadcast? broadcast, @JsonKey(name: 'alternative_titles')  AlternativeTitles? alternativeTitles, @JsonKey(name: 'related_anime')  List<RelatedAnime> relatedAnime, @JsonKey(name: 'my_list_status')  MyListStatus? myListStatus)  $default,) {final _that = this;
switch (_that) {
case _AnimeDetail():
return $default(_that.id,_that.title,_that.mainPicture,_that.mean,_that.rank,_that.popularity,_that.numEpisodes,_that.status,_that.rating,_that.source,_that.synopsis,_that.startDate,_that.endDate,_that.mediaType,_that.numScoringUsers,_that.genres,_that.broadcast,_that.alternativeTitles,_that.relatedAnime,_that.myListStatus);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title, @JsonKey(name: 'main_picture')  MainPicture? mainPicture,  double? mean,  int? rank,  int? popularity, @JsonKey(name: 'num_episodes')  int? numEpisodes,  String? status,  String? rating,  String? source,  String? synopsis, @JsonKey(name: 'start_date')  String? startDate, @JsonKey(name: 'end_date')  String? endDate, @JsonKey(name: 'media_type')  String? mediaType, @JsonKey(name: 'num_scoring_users')  int? numScoringUsers,  List<Genre> genres,  Broadcast? broadcast, @JsonKey(name: 'alternative_titles')  AlternativeTitles? alternativeTitles, @JsonKey(name: 'related_anime')  List<RelatedAnime> relatedAnime, @JsonKey(name: 'my_list_status')  MyListStatus? myListStatus)?  $default,) {final _that = this;
switch (_that) {
case _AnimeDetail() when $default != null:
return $default(_that.id,_that.title,_that.mainPicture,_that.mean,_that.rank,_that.popularity,_that.numEpisodes,_that.status,_that.rating,_that.source,_that.synopsis,_that.startDate,_that.endDate,_that.mediaType,_that.numScoringUsers,_that.genres,_that.broadcast,_that.alternativeTitles,_that.relatedAnime,_that.myListStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnimeDetail implements AnimeDetail {
  const _AnimeDetail({required this.id, required this.title, @JsonKey(name: 'main_picture') this.mainPicture, this.mean, this.rank, this.popularity, @JsonKey(name: 'num_episodes') this.numEpisodes, this.status, this.rating, this.source, this.synopsis, @JsonKey(name: 'start_date') this.startDate, @JsonKey(name: 'end_date') this.endDate, @JsonKey(name: 'media_type') this.mediaType, @JsonKey(name: 'num_scoring_users') this.numScoringUsers, final  List<Genre> genres = const [], this.broadcast, @JsonKey(name: 'alternative_titles') this.alternativeTitles, @JsonKey(name: 'related_anime') final  List<RelatedAnime> relatedAnime = const [], @JsonKey(name: 'my_list_status') this.myListStatus}): _genres = genres,_relatedAnime = relatedAnime;
  factory _AnimeDetail.fromJson(Map<String, dynamic> json) => _$AnimeDetailFromJson(json);

@override final  int id;
@override final  String title;
@override@JsonKey(name: 'main_picture') final  MainPicture? mainPicture;
@override final  double? mean;
@override final  int? rank;
@override final  int? popularity;
@override@JsonKey(name: 'num_episodes') final  int? numEpisodes;
@override final  String? status;
@override final  String? rating;
@override final  String? source;
@override final  String? synopsis;
@override@JsonKey(name: 'start_date') final  String? startDate;
@override@JsonKey(name: 'end_date') final  String? endDate;
@override@JsonKey(name: 'media_type') final  String? mediaType;
@override@JsonKey(name: 'num_scoring_users') final  int? numScoringUsers;
 final  List<Genre> _genres;
@override@JsonKey() List<Genre> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

@override final  Broadcast? broadcast;
@override@JsonKey(name: 'alternative_titles') final  AlternativeTitles? alternativeTitles;
 final  List<RelatedAnime> _relatedAnime;
@override@JsonKey(name: 'related_anime') List<RelatedAnime> get relatedAnime {
  if (_relatedAnime is EqualUnmodifiableListView) return _relatedAnime;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_relatedAnime);
}

@override@JsonKey(name: 'my_list_status') final  MyListStatus? myListStatus;

/// Create a copy of AnimeDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnimeDetailCopyWith<_AnimeDetail> get copyWith => __$AnimeDetailCopyWithImpl<_AnimeDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnimeDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnimeDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.mainPicture, mainPicture) || other.mainPicture == mainPicture)&&(identical(other.mean, mean) || other.mean == mean)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.popularity, popularity) || other.popularity == popularity)&&(identical(other.numEpisodes, numEpisodes) || other.numEpisodes == numEpisodes)&&(identical(other.status, status) || other.status == status)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.source, source) || other.source == source)&&(identical(other.synopsis, synopsis) || other.synopsis == synopsis)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.mediaType, mediaType) || other.mediaType == mediaType)&&(identical(other.numScoringUsers, numScoringUsers) || other.numScoringUsers == numScoringUsers)&&const DeepCollectionEquality().equals(other._genres, _genres)&&(identical(other.broadcast, broadcast) || other.broadcast == broadcast)&&(identical(other.alternativeTitles, alternativeTitles) || other.alternativeTitles == alternativeTitles)&&const DeepCollectionEquality().equals(other._relatedAnime, _relatedAnime)&&(identical(other.myListStatus, myListStatus) || other.myListStatus == myListStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,mainPicture,mean,rank,popularity,numEpisodes,status,rating,source,synopsis,startDate,endDate,mediaType,numScoringUsers,const DeepCollectionEquality().hash(_genres),broadcast,alternativeTitles,const DeepCollectionEquality().hash(_relatedAnime),myListStatus]);

@override
String toString() {
  return 'AnimeDetail(id: $id, title: $title, mainPicture: $mainPicture, mean: $mean, rank: $rank, popularity: $popularity, numEpisodes: $numEpisodes, status: $status, rating: $rating, source: $source, synopsis: $synopsis, startDate: $startDate, endDate: $endDate, mediaType: $mediaType, numScoringUsers: $numScoringUsers, genres: $genres, broadcast: $broadcast, alternativeTitles: $alternativeTitles, relatedAnime: $relatedAnime, myListStatus: $myListStatus)';
}


}

/// @nodoc
abstract mixin class _$AnimeDetailCopyWith<$Res> implements $AnimeDetailCopyWith<$Res> {
  factory _$AnimeDetailCopyWith(_AnimeDetail value, $Res Function(_AnimeDetail) _then) = __$AnimeDetailCopyWithImpl;
@override @useResult
$Res call({
 int id, String title,@JsonKey(name: 'main_picture') MainPicture? mainPicture, double? mean, int? rank, int? popularity,@JsonKey(name: 'num_episodes') int? numEpisodes, String? status, String? rating, String? source, String? synopsis,@JsonKey(name: 'start_date') String? startDate,@JsonKey(name: 'end_date') String? endDate,@JsonKey(name: 'media_type') String? mediaType,@JsonKey(name: 'num_scoring_users') int? numScoringUsers, List<Genre> genres, Broadcast? broadcast,@JsonKey(name: 'alternative_titles') AlternativeTitles? alternativeTitles,@JsonKey(name: 'related_anime') List<RelatedAnime> relatedAnime,@JsonKey(name: 'my_list_status') MyListStatus? myListStatus
});


@override $MainPictureCopyWith<$Res>? get mainPicture;@override $BroadcastCopyWith<$Res>? get broadcast;@override $AlternativeTitlesCopyWith<$Res>? get alternativeTitles;@override $MyListStatusCopyWith<$Res>? get myListStatus;

}
/// @nodoc
class __$AnimeDetailCopyWithImpl<$Res>
    implements _$AnimeDetailCopyWith<$Res> {
  __$AnimeDetailCopyWithImpl(this._self, this._then);

  final _AnimeDetail _self;
  final $Res Function(_AnimeDetail) _then;

/// Create a copy of AnimeDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? mainPicture = freezed,Object? mean = freezed,Object? rank = freezed,Object? popularity = freezed,Object? numEpisodes = freezed,Object? status = freezed,Object? rating = freezed,Object? source = freezed,Object? synopsis = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? mediaType = freezed,Object? numScoringUsers = freezed,Object? genres = null,Object? broadcast = freezed,Object? alternativeTitles = freezed,Object? relatedAnime = null,Object? myListStatus = freezed,}) {
  return _then(_AnimeDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,mainPicture: freezed == mainPicture ? _self.mainPicture : mainPicture // ignore: cast_nullable_to_non_nullable
as MainPicture?,mean: freezed == mean ? _self.mean : mean // ignore: cast_nullable_to_non_nullable
as double?,rank: freezed == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int?,popularity: freezed == popularity ? _self.popularity : popularity // ignore: cast_nullable_to_non_nullable
as int?,numEpisodes: freezed == numEpisodes ? _self.numEpisodes : numEpisodes // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as String?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String?,synopsis: freezed == synopsis ? _self.synopsis : synopsis // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,mediaType: freezed == mediaType ? _self.mediaType : mediaType // ignore: cast_nullable_to_non_nullable
as String?,numScoringUsers: freezed == numScoringUsers ? _self.numScoringUsers : numScoringUsers // ignore: cast_nullable_to_non_nullable
as int?,genres: null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<Genre>,broadcast: freezed == broadcast ? _self.broadcast : broadcast // ignore: cast_nullable_to_non_nullable
as Broadcast?,alternativeTitles: freezed == alternativeTitles ? _self.alternativeTitles : alternativeTitles // ignore: cast_nullable_to_non_nullable
as AlternativeTitles?,relatedAnime: null == relatedAnime ? _self._relatedAnime : relatedAnime // ignore: cast_nullable_to_non_nullable
as List<RelatedAnime>,myListStatus: freezed == myListStatus ? _self.myListStatus : myListStatus // ignore: cast_nullable_to_non_nullable
as MyListStatus?,
  ));
}

/// Create a copy of AnimeDetail
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
}/// Create a copy of AnimeDetail
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
}/// Create a copy of AnimeDetail
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
}/// Create a copy of AnimeDetail
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
mixin _$Genre {

 int get id; String get name;
/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenreCopyWith<Genre> get copyWith => _$GenreCopyWithImpl<Genre>(this as Genre, _$identity);

  /// Serializes this Genre to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Genre&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'Genre(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $GenreCopyWith<$Res>  {
  factory $GenreCopyWith(Genre value, $Res Function(Genre) _then) = _$GenreCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$GenreCopyWithImpl<$Res>
    implements $GenreCopyWith<$Res> {
  _$GenreCopyWithImpl(this._self, this._then);

  final Genre _self;
  final $Res Function(Genre) _then;

/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Genre].
extension GenrePatterns on Genre {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Genre value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Genre() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Genre value)  $default,){
final _that = this;
switch (_that) {
case _Genre():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Genre value)?  $default,){
final _that = this;
switch (_that) {
case _Genre() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Genre() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name)  $default,) {final _that = this;
switch (_that) {
case _Genre():
return $default(_that.id,_that.name);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _Genre() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Genre implements Genre {
  const _Genre({required this.id, required this.name});
  factory _Genre.fromJson(Map<String, dynamic> json) => _$GenreFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GenreCopyWith<_Genre> get copyWith => __$GenreCopyWithImpl<_Genre>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GenreToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Genre&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'Genre(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$GenreCopyWith<$Res> implements $GenreCopyWith<$Res> {
  factory _$GenreCopyWith(_Genre value, $Res Function(_Genre) _then) = __$GenreCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$GenreCopyWithImpl<$Res>
    implements _$GenreCopyWith<$Res> {
  __$GenreCopyWithImpl(this._self, this._then);

  final _Genre _self;
  final $Res Function(_Genre) _then;

/// Create a copy of Genre
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_Genre(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RelatedAnime {

@JsonKey(name: 'node') AnimeNode get node;@JsonKey(name: 'relation_type') String? get relationType;@JsonKey(name: 'relation_type_formatted') String? get relationTypeFormatted;
/// Create a copy of RelatedAnime
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelatedAnimeCopyWith<RelatedAnime> get copyWith => _$RelatedAnimeCopyWithImpl<RelatedAnime>(this as RelatedAnime, _$identity);

  /// Serializes this RelatedAnime to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelatedAnime&&(identical(other.node, node) || other.node == node)&&(identical(other.relationType, relationType) || other.relationType == relationType)&&(identical(other.relationTypeFormatted, relationTypeFormatted) || other.relationTypeFormatted == relationTypeFormatted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,node,relationType,relationTypeFormatted);

@override
String toString() {
  return 'RelatedAnime(node: $node, relationType: $relationType, relationTypeFormatted: $relationTypeFormatted)';
}


}

/// @nodoc
abstract mixin class $RelatedAnimeCopyWith<$Res>  {
  factory $RelatedAnimeCopyWith(RelatedAnime value, $Res Function(RelatedAnime) _then) = _$RelatedAnimeCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'node') AnimeNode node,@JsonKey(name: 'relation_type') String? relationType,@JsonKey(name: 'relation_type_formatted') String? relationTypeFormatted
});


$AnimeNodeCopyWith<$Res> get node;

}
/// @nodoc
class _$RelatedAnimeCopyWithImpl<$Res>
    implements $RelatedAnimeCopyWith<$Res> {
  _$RelatedAnimeCopyWithImpl(this._self, this._then);

  final RelatedAnime _self;
  final $Res Function(RelatedAnime) _then;

/// Create a copy of RelatedAnime
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? node = null,Object? relationType = freezed,Object? relationTypeFormatted = freezed,}) {
  return _then(_self.copyWith(
node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as AnimeNode,relationType: freezed == relationType ? _self.relationType : relationType // ignore: cast_nullable_to_non_nullable
as String?,relationTypeFormatted: freezed == relationTypeFormatted ? _self.relationTypeFormatted : relationTypeFormatted // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of RelatedAnime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnimeNodeCopyWith<$Res> get node {
  
  return $AnimeNodeCopyWith<$Res>(_self.node, (value) {
    return _then(_self.copyWith(node: value));
  });
}
}


/// Adds pattern-matching-related methods to [RelatedAnime].
extension RelatedAnimePatterns on RelatedAnime {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RelatedAnime value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RelatedAnime() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RelatedAnime value)  $default,){
final _that = this;
switch (_that) {
case _RelatedAnime():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RelatedAnime value)?  $default,){
final _that = this;
switch (_that) {
case _RelatedAnime() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'node')  AnimeNode node, @JsonKey(name: 'relation_type')  String? relationType, @JsonKey(name: 'relation_type_formatted')  String? relationTypeFormatted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RelatedAnime() when $default != null:
return $default(_that.node,_that.relationType,_that.relationTypeFormatted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'node')  AnimeNode node, @JsonKey(name: 'relation_type')  String? relationType, @JsonKey(name: 'relation_type_formatted')  String? relationTypeFormatted)  $default,) {final _that = this;
switch (_that) {
case _RelatedAnime():
return $default(_that.node,_that.relationType,_that.relationTypeFormatted);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'node')  AnimeNode node, @JsonKey(name: 'relation_type')  String? relationType, @JsonKey(name: 'relation_type_formatted')  String? relationTypeFormatted)?  $default,) {final _that = this;
switch (_that) {
case _RelatedAnime() when $default != null:
return $default(_that.node,_that.relationType,_that.relationTypeFormatted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RelatedAnime implements RelatedAnime {
  const _RelatedAnime({@JsonKey(name: 'node') required this.node, @JsonKey(name: 'relation_type') this.relationType, @JsonKey(name: 'relation_type_formatted') this.relationTypeFormatted});
  factory _RelatedAnime.fromJson(Map<String, dynamic> json) => _$RelatedAnimeFromJson(json);

@override@JsonKey(name: 'node') final  AnimeNode node;
@override@JsonKey(name: 'relation_type') final  String? relationType;
@override@JsonKey(name: 'relation_type_formatted') final  String? relationTypeFormatted;

/// Create a copy of RelatedAnime
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RelatedAnimeCopyWith<_RelatedAnime> get copyWith => __$RelatedAnimeCopyWithImpl<_RelatedAnime>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RelatedAnimeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RelatedAnime&&(identical(other.node, node) || other.node == node)&&(identical(other.relationType, relationType) || other.relationType == relationType)&&(identical(other.relationTypeFormatted, relationTypeFormatted) || other.relationTypeFormatted == relationTypeFormatted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,node,relationType,relationTypeFormatted);

@override
String toString() {
  return 'RelatedAnime(node: $node, relationType: $relationType, relationTypeFormatted: $relationTypeFormatted)';
}


}

/// @nodoc
abstract mixin class _$RelatedAnimeCopyWith<$Res> implements $RelatedAnimeCopyWith<$Res> {
  factory _$RelatedAnimeCopyWith(_RelatedAnime value, $Res Function(_RelatedAnime) _then) = __$RelatedAnimeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'node') AnimeNode node,@JsonKey(name: 'relation_type') String? relationType,@JsonKey(name: 'relation_type_formatted') String? relationTypeFormatted
});


@override $AnimeNodeCopyWith<$Res> get node;

}
/// @nodoc
class __$RelatedAnimeCopyWithImpl<$Res>
    implements _$RelatedAnimeCopyWith<$Res> {
  __$RelatedAnimeCopyWithImpl(this._self, this._then);

  final _RelatedAnime _self;
  final $Res Function(_RelatedAnime) _then;

/// Create a copy of RelatedAnime
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? node = null,Object? relationType = freezed,Object? relationTypeFormatted = freezed,}) {
  return _then(_RelatedAnime(
node: null == node ? _self.node : node // ignore: cast_nullable_to_non_nullable
as AnimeNode,relationType: freezed == relationType ? _self.relationType : relationType // ignore: cast_nullable_to_non_nullable
as String?,relationTypeFormatted: freezed == relationTypeFormatted ? _self.relationTypeFormatted : relationTypeFormatted // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of RelatedAnime
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnimeNodeCopyWith<$Res> get node {
  
  return $AnimeNodeCopyWith<$Res>(_self.node, (value) {
    return _then(_self.copyWith(node: value));
  });
}
}


/// @nodoc
mixin _$AnimeNode {

 int get id; String get title;@JsonKey(name: 'main_picture') MainPicture? get mainPicture;
/// Create a copy of AnimeNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnimeNodeCopyWith<AnimeNode> get copyWith => _$AnimeNodeCopyWithImpl<AnimeNode>(this as AnimeNode, _$identity);

  /// Serializes this AnimeNode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnimeNode&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.mainPicture, mainPicture) || other.mainPicture == mainPicture));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,mainPicture);

@override
String toString() {
  return 'AnimeNode(id: $id, title: $title, mainPicture: $mainPicture)';
}


}

/// @nodoc
abstract mixin class $AnimeNodeCopyWith<$Res>  {
  factory $AnimeNodeCopyWith(AnimeNode value, $Res Function(AnimeNode) _then) = _$AnimeNodeCopyWithImpl;
@useResult
$Res call({
 int id, String title,@JsonKey(name: 'main_picture') MainPicture? mainPicture
});


$MainPictureCopyWith<$Res>? get mainPicture;

}
/// @nodoc
class _$AnimeNodeCopyWithImpl<$Res>
    implements $AnimeNodeCopyWith<$Res> {
  _$AnimeNodeCopyWithImpl(this._self, this._then);

  final AnimeNode _self;
  final $Res Function(AnimeNode) _then;

/// Create a copy of AnimeNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? mainPicture = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,mainPicture: freezed == mainPicture ? _self.mainPicture : mainPicture // ignore: cast_nullable_to_non_nullable
as MainPicture?,
  ));
}
/// Create a copy of AnimeNode
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
}
}


/// Adds pattern-matching-related methods to [AnimeNode].
extension AnimeNodePatterns on AnimeNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnimeNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnimeNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnimeNode value)  $default,){
final _that = this;
switch (_that) {
case _AnimeNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnimeNode value)?  $default,){
final _that = this;
switch (_that) {
case _AnimeNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title, @JsonKey(name: 'main_picture')  MainPicture? mainPicture)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnimeNode() when $default != null:
return $default(_that.id,_that.title,_that.mainPicture);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title, @JsonKey(name: 'main_picture')  MainPicture? mainPicture)  $default,) {final _that = this;
switch (_that) {
case _AnimeNode():
return $default(_that.id,_that.title,_that.mainPicture);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title, @JsonKey(name: 'main_picture')  MainPicture? mainPicture)?  $default,) {final _that = this;
switch (_that) {
case _AnimeNode() when $default != null:
return $default(_that.id,_that.title,_that.mainPicture);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnimeNode implements AnimeNode {
  const _AnimeNode({required this.id, required this.title, @JsonKey(name: 'main_picture') this.mainPicture});
  factory _AnimeNode.fromJson(Map<String, dynamic> json) => _$AnimeNodeFromJson(json);

@override final  int id;
@override final  String title;
@override@JsonKey(name: 'main_picture') final  MainPicture? mainPicture;

/// Create a copy of AnimeNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnimeNodeCopyWith<_AnimeNode> get copyWith => __$AnimeNodeCopyWithImpl<_AnimeNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnimeNodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnimeNode&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.mainPicture, mainPicture) || other.mainPicture == mainPicture));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,mainPicture);

@override
String toString() {
  return 'AnimeNode(id: $id, title: $title, mainPicture: $mainPicture)';
}


}

/// @nodoc
abstract mixin class _$AnimeNodeCopyWith<$Res> implements $AnimeNodeCopyWith<$Res> {
  factory _$AnimeNodeCopyWith(_AnimeNode value, $Res Function(_AnimeNode) _then) = __$AnimeNodeCopyWithImpl;
@override @useResult
$Res call({
 int id, String title,@JsonKey(name: 'main_picture') MainPicture? mainPicture
});


@override $MainPictureCopyWith<$Res>? get mainPicture;

}
/// @nodoc
class __$AnimeNodeCopyWithImpl<$Res>
    implements _$AnimeNodeCopyWith<$Res> {
  __$AnimeNodeCopyWithImpl(this._self, this._then);

  final _AnimeNode _self;
  final $Res Function(_AnimeNode) _then;

/// Create a copy of AnimeNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? mainPicture = freezed,}) {
  return _then(_AnimeNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,mainPicture: freezed == mainPicture ? _self.mainPicture : mainPicture // ignore: cast_nullable_to_non_nullable
as MainPicture?,
  ));
}

/// Create a copy of AnimeNode
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
}
}

// dart format on
