import 'package:animal/data/models/anime.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'anime_character.freezed.dart';
part 'anime_character.g.dart';

@freezed
sealed class AnimeCharacter with _$AnimeCharacter {
  const factory AnimeCharacter({
    required int id,
    required String name,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'main_picture') MainPicture? mainPicture,
    String? role,
    @JsonKey(name: 'voice_actors') @Default([]) List<VoiceActor> voiceActors,
  }) = _AnimeCharacter;

  factory AnimeCharacter.fromJson(Map<String, dynamic> json) =>
      _$AnimeCharacterFromJson(json);
}

@freezed
sealed class VoiceActor with _$VoiceActor {
  const factory VoiceActor({
    required int id,
    required String name,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'main_picture') MainPicture? mainPicture,
    String? language,
  }) = _VoiceActor;

  factory VoiceActor.fromJson(Map<String, dynamic> json) =>
      _$VoiceActorFromJson(json);
}
