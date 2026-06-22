// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_character.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnimeCharacter _$AnimeCharacterFromJson(Map<String, dynamic> json) =>
    _AnimeCharacter(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      mainPicture: json['main_picture'] == null
          ? null
          : MainPicture.fromJson(json['main_picture'] as Map<String, dynamic>),
      role: json['role'] as String?,
      voiceActors:
          (json['voice_actors'] as List<dynamic>?)
              ?.map((e) => VoiceActor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$AnimeCharacterToJson(_AnimeCharacter instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'main_picture': instance.mainPicture,
      'role': instance.role,
      'voice_actors': instance.voiceActors,
    };

_VoiceActor _$VoiceActorFromJson(Map<String, dynamic> json) => _VoiceActor(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  firstName: json['first_name'] as String?,
  lastName: json['last_name'] as String?,
  mainPicture: json['main_picture'] == null
      ? null
      : MainPicture.fromJson(json['main_picture'] as Map<String, dynamic>),
  language: json['language'] as String?,
);

Map<String, dynamic> _$VoiceActorToJson(_VoiceActor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'main_picture': instance.mainPicture,
      'language': instance.language,
    };
