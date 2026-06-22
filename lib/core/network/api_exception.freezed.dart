// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_exception.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ApiException {

 String? get message;
/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiExceptionCopyWith<ApiException> get copyWith => _$ApiExceptionCopyWithImpl<ApiException>(this as ApiException, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiException&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ApiException(message: $message)';
}


}

/// @nodoc
abstract mixin class $ApiExceptionCopyWith<$Res>  {
  factory $ApiExceptionCopyWith(ApiException value, $Res Function(ApiException) _then) = _$ApiExceptionCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ApiExceptionCopyWithImpl<$Res>
    implements $ApiExceptionCopyWith<$Res> {
  _$ApiExceptionCopyWithImpl(this._self, this._then);

  final ApiException _self;
  final $Res Function(ApiException) _then;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message! : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiException].
extension ApiExceptionPatterns on ApiException {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NetworkException value)?  network,TResult Function( ServerException value)?  server,TResult Function( ParsingException value)?  parsing,TResult Function( UnauthorizedException value)?  unauthorized,TResult Function( UnknownApiException value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NetworkException() when network != null:
return network(_that);case ServerException() when server != null:
return server(_that);case ParsingException() when parsing != null:
return parsing(_that);case UnauthorizedException() when unauthorized != null:
return unauthorized(_that);case UnknownApiException() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NetworkException value)  network,required TResult Function( ServerException value)  server,required TResult Function( ParsingException value)  parsing,required TResult Function( UnauthorizedException value)  unauthorized,required TResult Function( UnknownApiException value)  unknown,}){
final _that = this;
switch (_that) {
case NetworkException():
return network(_that);case ServerException():
return server(_that);case ParsingException():
return parsing(_that);case UnauthorizedException():
return unauthorized(_that);case UnknownApiException():
return unknown(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NetworkException value)?  network,TResult? Function( ServerException value)?  server,TResult? Function( ParsingException value)?  parsing,TResult? Function( UnauthorizedException value)?  unauthorized,TResult? Function( UnknownApiException value)?  unknown,}){
final _that = this;
switch (_that) {
case NetworkException() when network != null:
return network(_that);case ServerException() when server != null:
return server(_that);case ParsingException() when parsing != null:
return parsing(_that);case UnauthorizedException() when unauthorized != null:
return unauthorized(_that);case UnknownApiException() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String message)?  network,TResult Function( int statusCode,  String message)?  server,TResult Function( String message)?  parsing,TResult Function( String? message)?  unauthorized,TResult Function( String? message)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NetworkException() when network != null:
return network(_that.message);case ServerException() when server != null:
return server(_that.statusCode,_that.message);case ParsingException() when parsing != null:
return parsing(_that.message);case UnauthorizedException() when unauthorized != null:
return unauthorized(_that.message);case UnknownApiException() when unknown != null:
return unknown(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String message)  network,required TResult Function( int statusCode,  String message)  server,required TResult Function( String message)  parsing,required TResult Function( String? message)  unauthorized,required TResult Function( String? message)  unknown,}) {final _that = this;
switch (_that) {
case NetworkException():
return network(_that.message);case ServerException():
return server(_that.statusCode,_that.message);case ParsingException():
return parsing(_that.message);case UnauthorizedException():
return unauthorized(_that.message);case UnknownApiException():
return unknown(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String message)?  network,TResult? Function( int statusCode,  String message)?  server,TResult? Function( String message)?  parsing,TResult? Function( String? message)?  unauthorized,TResult? Function( String? message)?  unknown,}) {final _that = this;
switch (_that) {
case NetworkException() when network != null:
return network(_that.message);case ServerException() when server != null:
return server(_that.statusCode,_that.message);case ParsingException() when parsing != null:
return parsing(_that.message);case UnauthorizedException() when unauthorized != null:
return unauthorized(_that.message);case UnknownApiException() when unknown != null:
return unknown(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class NetworkException implements ApiException {
  const NetworkException({required this.message});
  

@override final  String message;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetworkExceptionCopyWith<NetworkException> get copyWith => _$NetworkExceptionCopyWithImpl<NetworkException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetworkException&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ApiException.network(message: $message)';
}


}

/// @nodoc
abstract mixin class $NetworkExceptionCopyWith<$Res> implements $ApiExceptionCopyWith<$Res> {
  factory $NetworkExceptionCopyWith(NetworkException value, $Res Function(NetworkException) _then) = _$NetworkExceptionCopyWithImpl;
@override @useResult
$Res call({
 String message
});




}
/// @nodoc
class _$NetworkExceptionCopyWithImpl<$Res>
    implements $NetworkExceptionCopyWith<$Res> {
  _$NetworkExceptionCopyWithImpl(this._self, this._then);

  final NetworkException _self;
  final $Res Function(NetworkException) _then;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(NetworkException(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ServerException implements ApiException {
  const ServerException({required this.statusCode, required this.message});
  

 final  int statusCode;
@override final  String message;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServerExceptionCopyWith<ServerException> get copyWith => _$ServerExceptionCopyWithImpl<ServerException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerException&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,statusCode,message);

@override
String toString() {
  return 'ApiException.server(statusCode: $statusCode, message: $message)';
}


}

/// @nodoc
abstract mixin class $ServerExceptionCopyWith<$Res> implements $ApiExceptionCopyWith<$Res> {
  factory $ServerExceptionCopyWith(ServerException value, $Res Function(ServerException) _then) = _$ServerExceptionCopyWithImpl;
@override @useResult
$Res call({
 int statusCode, String message
});




}
/// @nodoc
class _$ServerExceptionCopyWithImpl<$Res>
    implements $ServerExceptionCopyWith<$Res> {
  _$ServerExceptionCopyWithImpl(this._self, this._then);

  final ServerException _self;
  final $Res Function(ServerException) _then;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? statusCode = null,Object? message = null,}) {
  return _then(ServerException(
statusCode: null == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ParsingException implements ApiException {
  const ParsingException({required this.message});
  

@override final  String message;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParsingExceptionCopyWith<ParsingException> get copyWith => _$ParsingExceptionCopyWithImpl<ParsingException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParsingException&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ApiException.parsing(message: $message)';
}


}

/// @nodoc
abstract mixin class $ParsingExceptionCopyWith<$Res> implements $ApiExceptionCopyWith<$Res> {
  factory $ParsingExceptionCopyWith(ParsingException value, $Res Function(ParsingException) _then) = _$ParsingExceptionCopyWithImpl;
@override @useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ParsingExceptionCopyWithImpl<$Res>
    implements $ParsingExceptionCopyWith<$Res> {
  _$ParsingExceptionCopyWithImpl(this._self, this._then);

  final ParsingException _self;
  final $Res Function(ParsingException) _then;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ParsingException(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class UnauthorizedException implements ApiException {
  const UnauthorizedException({this.message});
  

@override final  String? message;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnauthorizedExceptionCopyWith<UnauthorizedException> get copyWith => _$UnauthorizedExceptionCopyWithImpl<UnauthorizedException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnauthorizedException&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ApiException.unauthorized(message: $message)';
}


}

/// @nodoc
abstract mixin class $UnauthorizedExceptionCopyWith<$Res> implements $ApiExceptionCopyWith<$Res> {
  factory $UnauthorizedExceptionCopyWith(UnauthorizedException value, $Res Function(UnauthorizedException) _then) = _$UnauthorizedExceptionCopyWithImpl;
@override @useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$UnauthorizedExceptionCopyWithImpl<$Res>
    implements $UnauthorizedExceptionCopyWith<$Res> {
  _$UnauthorizedExceptionCopyWithImpl(this._self, this._then);

  final UnauthorizedException _self;
  final $Res Function(UnauthorizedException) _then;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(UnauthorizedException(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class UnknownApiException implements ApiException {
  const UnknownApiException({this.message});
  

@override final  String? message;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownApiExceptionCopyWith<UnknownApiException> get copyWith => _$UnknownApiExceptionCopyWithImpl<UnknownApiException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownApiException&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ApiException.unknown(message: $message)';
}


}

/// @nodoc
abstract mixin class $UnknownApiExceptionCopyWith<$Res> implements $ApiExceptionCopyWith<$Res> {
  factory $UnknownApiExceptionCopyWith(UnknownApiException value, $Res Function(UnknownApiException) _then) = _$UnknownApiExceptionCopyWithImpl;
@override @useResult
$Res call({
 String? message
});




}
/// @nodoc
class _$UnknownApiExceptionCopyWithImpl<$Res>
    implements $UnknownApiExceptionCopyWith<$Res> {
  _$UnknownApiExceptionCopyWithImpl(this._self, this._then);

  final UnknownApiException _self;
  final $Res Function(UnknownApiException) _then;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = freezed,}) {
  return _then(UnknownApiException(
message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
