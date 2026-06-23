// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'anime_character.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnimeCharacter {

 int get id; String get name;@JsonKey(name: 'first_name') String? get firstName;@JsonKey(name: 'last_name') String? get lastName;@JsonKey(name: 'main_picture') MainPicture? get mainPicture; String? get role;@JsonKey(name: 'voice_actors') List<VoiceActor> get voiceActors;
/// Create a copy of AnimeCharacter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnimeCharacterCopyWith<AnimeCharacter> get copyWith => _$AnimeCharacterCopyWithImpl<AnimeCharacter>(this as AnimeCharacter, _$identity);

  /// Serializes this AnimeCharacter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnimeCharacter&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.mainPicture, mainPicture) || other.mainPicture == mainPicture)&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other.voiceActors, voiceActors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,firstName,lastName,mainPicture,role,const DeepCollectionEquality().hash(voiceActors));

@override
String toString() {
  return 'AnimeCharacter(id: $id, name: $name, firstName: $firstName, lastName: $lastName, mainPicture: $mainPicture, role: $role, voiceActors: $voiceActors)';
}


}

/// @nodoc
abstract mixin class $AnimeCharacterCopyWith<$Res>  {
  factory $AnimeCharacterCopyWith(AnimeCharacter value, $Res Function(AnimeCharacter) _then) = _$AnimeCharacterCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'first_name') String? firstName,@JsonKey(name: 'last_name') String? lastName,@JsonKey(name: 'main_picture') MainPicture? mainPicture, String? role,@JsonKey(name: 'voice_actors') List<VoiceActor> voiceActors
});


$MainPictureCopyWith<$Res>? get mainPicture;

}
/// @nodoc
class _$AnimeCharacterCopyWithImpl<$Res>
    implements $AnimeCharacterCopyWith<$Res> {
  _$AnimeCharacterCopyWithImpl(this._self, this._then);

  final AnimeCharacter _self;
  final $Res Function(AnimeCharacter) _then;

/// Create a copy of AnimeCharacter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? firstName = freezed,Object? lastName = freezed,Object? mainPicture = freezed,Object? role = freezed,Object? voiceActors = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,mainPicture: freezed == mainPicture ? _self.mainPicture : mainPicture // ignore: cast_nullable_to_non_nullable
as MainPicture?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,voiceActors: null == voiceActors ? _self.voiceActors : voiceActors // ignore: cast_nullable_to_non_nullable
as List<VoiceActor>,
  ));
}
/// Create a copy of AnimeCharacter
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


/// Adds pattern-matching-related methods to [AnimeCharacter].
extension AnimeCharacterPatterns on AnimeCharacter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnimeCharacter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnimeCharacter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnimeCharacter value)  $default,){
final _that = this;
switch (_that) {
case _AnimeCharacter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnimeCharacter value)?  $default,){
final _that = this;
switch (_that) {
case _AnimeCharacter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'first_name')  String? firstName, @JsonKey(name: 'last_name')  String? lastName, @JsonKey(name: 'main_picture')  MainPicture? mainPicture,  String? role, @JsonKey(name: 'voice_actors')  List<VoiceActor> voiceActors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnimeCharacter() when $default != null:
return $default(_that.id,_that.name,_that.firstName,_that.lastName,_that.mainPicture,_that.role,_that.voiceActors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'first_name')  String? firstName, @JsonKey(name: 'last_name')  String? lastName, @JsonKey(name: 'main_picture')  MainPicture? mainPicture,  String? role, @JsonKey(name: 'voice_actors')  List<VoiceActor> voiceActors)  $default,) {final _that = this;
switch (_that) {
case _AnimeCharacter():
return $default(_that.id,_that.name,_that.firstName,_that.lastName,_that.mainPicture,_that.role,_that.voiceActors);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'first_name')  String? firstName, @JsonKey(name: 'last_name')  String? lastName, @JsonKey(name: 'main_picture')  MainPicture? mainPicture,  String? role, @JsonKey(name: 'voice_actors')  List<VoiceActor> voiceActors)?  $default,) {final _that = this;
switch (_that) {
case _AnimeCharacter() when $default != null:
return $default(_that.id,_that.name,_that.firstName,_that.lastName,_that.mainPicture,_that.role,_that.voiceActors);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnimeCharacter implements AnimeCharacter {
  const _AnimeCharacter({required this.id, required this.name, @JsonKey(name: 'first_name') this.firstName, @JsonKey(name: 'last_name') this.lastName, @JsonKey(name: 'main_picture') this.mainPicture, this.role, @JsonKey(name: 'voice_actors') final  List<VoiceActor> voiceActors = const []}): _voiceActors = voiceActors;
  factory _AnimeCharacter.fromJson(Map<String, dynamic> json) => _$AnimeCharacterFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(name: 'first_name') final  String? firstName;
@override@JsonKey(name: 'last_name') final  String? lastName;
@override@JsonKey(name: 'main_picture') final  MainPicture? mainPicture;
@override final  String? role;
 final  List<VoiceActor> _voiceActors;
@override@JsonKey(name: 'voice_actors') List<VoiceActor> get voiceActors {
  if (_voiceActors is EqualUnmodifiableListView) return _voiceActors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_voiceActors);
}


/// Create a copy of AnimeCharacter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnimeCharacterCopyWith<_AnimeCharacter> get copyWith => __$AnimeCharacterCopyWithImpl<_AnimeCharacter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnimeCharacterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnimeCharacter&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.mainPicture, mainPicture) || other.mainPicture == mainPicture)&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other._voiceActors, _voiceActors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,firstName,lastName,mainPicture,role,const DeepCollectionEquality().hash(_voiceActors));

@override
String toString() {
  return 'AnimeCharacter(id: $id, name: $name, firstName: $firstName, lastName: $lastName, mainPicture: $mainPicture, role: $role, voiceActors: $voiceActors)';
}


}

/// @nodoc
abstract mixin class _$AnimeCharacterCopyWith<$Res> implements $AnimeCharacterCopyWith<$Res> {
  factory _$AnimeCharacterCopyWith(_AnimeCharacter value, $Res Function(_AnimeCharacter) _then) = __$AnimeCharacterCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'first_name') String? firstName,@JsonKey(name: 'last_name') String? lastName,@JsonKey(name: 'main_picture') MainPicture? mainPicture, String? role,@JsonKey(name: 'voice_actors') List<VoiceActor> voiceActors
});


@override $MainPictureCopyWith<$Res>? get mainPicture;

}
/// @nodoc
class __$AnimeCharacterCopyWithImpl<$Res>
    implements _$AnimeCharacterCopyWith<$Res> {
  __$AnimeCharacterCopyWithImpl(this._self, this._then);

  final _AnimeCharacter _self;
  final $Res Function(_AnimeCharacter) _then;

/// Create a copy of AnimeCharacter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? firstName = freezed,Object? lastName = freezed,Object? mainPicture = freezed,Object? role = freezed,Object? voiceActors = null,}) {
  return _then(_AnimeCharacter(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,mainPicture: freezed == mainPicture ? _self.mainPicture : mainPicture // ignore: cast_nullable_to_non_nullable
as MainPicture?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,voiceActors: null == voiceActors ? _self._voiceActors : voiceActors // ignore: cast_nullable_to_non_nullable
as List<VoiceActor>,
  ));
}

/// Create a copy of AnimeCharacter
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


/// @nodoc
mixin _$VoiceActor {

 int get id; String get name;@JsonKey(name: 'first_name') String? get firstName;@JsonKey(name: 'last_name') String? get lastName;@JsonKey(name: 'main_picture') MainPicture? get mainPicture; String? get language;
/// Create a copy of VoiceActor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoiceActorCopyWith<VoiceActor> get copyWith => _$VoiceActorCopyWithImpl<VoiceActor>(this as VoiceActor, _$identity);

  /// Serializes this VoiceActor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoiceActor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.mainPicture, mainPicture) || other.mainPicture == mainPicture)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,firstName,lastName,mainPicture,language);

@override
String toString() {
  return 'VoiceActor(id: $id, name: $name, firstName: $firstName, lastName: $lastName, mainPicture: $mainPicture, language: $language)';
}


}

/// @nodoc
abstract mixin class $VoiceActorCopyWith<$Res>  {
  factory $VoiceActorCopyWith(VoiceActor value, $Res Function(VoiceActor) _then) = _$VoiceActorCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'first_name') String? firstName,@JsonKey(name: 'last_name') String? lastName,@JsonKey(name: 'main_picture') MainPicture? mainPicture, String? language
});


$MainPictureCopyWith<$Res>? get mainPicture;

}
/// @nodoc
class _$VoiceActorCopyWithImpl<$Res>
    implements $VoiceActorCopyWith<$Res> {
  _$VoiceActorCopyWithImpl(this._self, this._then);

  final VoiceActor _self;
  final $Res Function(VoiceActor) _then;

/// Create a copy of VoiceActor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? firstName = freezed,Object? lastName = freezed,Object? mainPicture = freezed,Object? language = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,mainPicture: freezed == mainPicture ? _self.mainPicture : mainPicture // ignore: cast_nullable_to_non_nullable
as MainPicture?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of VoiceActor
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


/// Adds pattern-matching-related methods to [VoiceActor].
extension VoiceActorPatterns on VoiceActor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VoiceActor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VoiceActor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VoiceActor value)  $default,){
final _that = this;
switch (_that) {
case _VoiceActor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VoiceActor value)?  $default,){
final _that = this;
switch (_that) {
case _VoiceActor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'first_name')  String? firstName, @JsonKey(name: 'last_name')  String? lastName, @JsonKey(name: 'main_picture')  MainPicture? mainPicture,  String? language)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VoiceActor() when $default != null:
return $default(_that.id,_that.name,_that.firstName,_that.lastName,_that.mainPicture,_that.language);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'first_name')  String? firstName, @JsonKey(name: 'last_name')  String? lastName, @JsonKey(name: 'main_picture')  MainPicture? mainPicture,  String? language)  $default,) {final _that = this;
switch (_that) {
case _VoiceActor():
return $default(_that.id,_that.name,_that.firstName,_that.lastName,_that.mainPicture,_that.language);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'first_name')  String? firstName, @JsonKey(name: 'last_name')  String? lastName, @JsonKey(name: 'main_picture')  MainPicture? mainPicture,  String? language)?  $default,) {final _that = this;
switch (_that) {
case _VoiceActor() when $default != null:
return $default(_that.id,_that.name,_that.firstName,_that.lastName,_that.mainPicture,_that.language);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VoiceActor implements VoiceActor {
  const _VoiceActor({required this.id, required this.name, @JsonKey(name: 'first_name') this.firstName, @JsonKey(name: 'last_name') this.lastName, @JsonKey(name: 'main_picture') this.mainPicture, this.language});
  factory _VoiceActor.fromJson(Map<String, dynamic> json) => _$VoiceActorFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(name: 'first_name') final  String? firstName;
@override@JsonKey(name: 'last_name') final  String? lastName;
@override@JsonKey(name: 'main_picture') final  MainPicture? mainPicture;
@override final  String? language;

/// Create a copy of VoiceActor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VoiceActorCopyWith<_VoiceActor> get copyWith => __$VoiceActorCopyWithImpl<_VoiceActor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VoiceActorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VoiceActor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.mainPicture, mainPicture) || other.mainPicture == mainPicture)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,firstName,lastName,mainPicture,language);

@override
String toString() {
  return 'VoiceActor(id: $id, name: $name, firstName: $firstName, lastName: $lastName, mainPicture: $mainPicture, language: $language)';
}


}

/// @nodoc
abstract mixin class _$VoiceActorCopyWith<$Res> implements $VoiceActorCopyWith<$Res> {
  factory _$VoiceActorCopyWith(_VoiceActor value, $Res Function(_VoiceActor) _then) = __$VoiceActorCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'first_name') String? firstName,@JsonKey(name: 'last_name') String? lastName,@JsonKey(name: 'main_picture') MainPicture? mainPicture, String? language
});


@override $MainPictureCopyWith<$Res>? get mainPicture;

}
/// @nodoc
class __$VoiceActorCopyWithImpl<$Res>
    implements _$VoiceActorCopyWith<$Res> {
  __$VoiceActorCopyWithImpl(this._self, this._then);

  final _VoiceActor _self;
  final $Res Function(_VoiceActor) _then;

/// Create a copy of VoiceActor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? firstName = freezed,Object? lastName = freezed,Object? mainPicture = freezed,Object? language = freezed,}) {
  return _then(_VoiceActor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,mainPicture: freezed == mainPicture ? _self.mainPicture : mainPicture // ignore: cast_nullable_to_non_nullable
as MainPicture?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of VoiceActor
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
