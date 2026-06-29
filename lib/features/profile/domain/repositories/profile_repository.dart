import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_presence.dart';
import '../entities/user_profile.dart';
import '../value_objects/display_name.dart';

abstract class ProfileRepository {
  // ── Own profile ─────────────────────────────────────────────────────────────

  Future<Either<Failure, UserProfile>> createProfile({
    required DisplayName displayName,
    DateTime? dateOfBirth,
  });

  Future<Either<Failure, bool>> hasOwnProfile();

  Future<Either<Failure, UserProfile?>> getOwnProfile();

  Future<Either<Failure, UserProfile>> updateProfile({
    required String displayName,
  });

  Future<Either<Failure, String>> uploadAvatar({
    required String userId,
    required String localFilePath,
  });

  // ── Partner profile ──────────────────────────────────────────────────────────

  Future<Either<Failure, UserProfile?>> getPartnerProfile(String partnerId);

  Stream<UserProfile?> watchPartnerProfile(String partnerId);

  // ── Presence ─────────────────────────────────────────────────────────────────

  Future<Either<Failure, void>> upsertPresence({
    required String userId,
    required bool isOnline,
  });

  Stream<UserPresence?> watchPartnerPresence(String partnerId);
}
