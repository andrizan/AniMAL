import 'package:animal/features/profile/domain/entities/user_profile_entity.dart';

abstract interface class ProfileRepository {
  Future<UserProfileEntity?> getUserProfile();
}
