import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logger/app_logger.dart';
import '../../domain/entities/user_presence.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/value_objects/display_name.dart';
import '../data_sources/remote/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({
    required ProfileRemoteDataSource remoteDataSource,
    required SupabaseClient client,
  })  : _remote = remoteDataSource,
        _client = client;

  final ProfileRemoteDataSource _remote;
  final SupabaseClient _client;

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String? get _userId => _client.auth.currentUser?.id;

  UserProfile _profileFromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['display_name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        dateOfBirth: json['date_of_birth'] != null
            ? DateTime.parse(json['date_of_birth'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  UserPresence _presenceFromJson(Map<String, dynamic> json) => UserPresence(
        userId: json['user_id'] as String,
        isOnline: json['is_online'] as bool,
        lastSeenAt: DateTime.parse(json['last_seen_at'] as String).toLocal(),
      );

  // ── Own profile ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, UserProfile>> createProfile({
    required DisplayName displayName,
    DateTime? dateOfBirth,
  }) async {
    final userId = _userId;
    if (userId == null) return const Left(AuthFailure.unauthorized());

    try {
      final data = await _remote.createProfile(
        userId: userId,
        displayName: displayName.value,
        dateOfBirth: dateOfBirth,
      );
      return Right(_profileFromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure.server(e.message));
    } on SocketException {
      return const Left(ServerFailure.noConnection());
    } catch (e, stack) {
      AppLogger.error('createProfile repository error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> hasOwnProfile() async {
    final userId = _userId;
    if (userId == null) return const Right(false);

    try {
      final has = await _remote.hasProfile(userId);
      return Right(has);
    } on SocketException {
      return const Left(ServerFailure.noConnection());
    } catch (e, stack) {
      AppLogger.error('hasOwnProfile repository error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserProfile?>> getOwnProfile() async {
    final userId = _userId;
    if (userId == null) return const Right(null);

    try {
      final data = await _remote.getProfile(userId);
      return Right(data != null ? _profileFromJson(data) : null);
    } on ServerException catch (e) {
      return Left(ServerFailure.server(e.message));
    } on SocketException {
      return const Left(ServerFailure.noConnection());
    } catch (e, stack) {
      AppLogger.error('getOwnProfile repository error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateProfile({
    required String displayName,
  }) async {
    final userId = _userId;
    if (userId == null) return const Left(AuthFailure.unauthorized());

    try {
      final data = await _remote.updateProfile(
        userId: userId,
        displayName: displayName,
      );
      return Right(_profileFromJson(data));
    } on ServerException catch (e) {
      return Left(ServerFailure.server(e.message));
    } on SocketException {
      return const Left(ServerFailure.noConnection());
    } catch (e, stack) {
      AppLogger.error('updateProfile repository error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, String>> uploadAvatar({
    required String userId,
    required String localFilePath,
  }) async {
    try {
      final url = await _remote.uploadAvatar(
        userId: userId,
        localFilePath: localFilePath,
      );
      return Right(url);
    } on ServerException catch (e) {
      return Left(ServerFailure.server(e.message));
    } on SocketException {
      return const Left(ServerFailure.noConnection());
    } catch (e, stack) {
      AppLogger.error('uploadAvatar repository error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  // ── Partner profile ──────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, UserProfile?>> getPartnerProfile(
    String partnerId,
  ) async {
    try {
      final data = await _remote.getProfile(partnerId);
      return Right(data != null ? _profileFromJson(data) : null);
    } on ServerException catch (e) {
      return Left(ServerFailure.server(e.message));
    } on SocketException {
      return const Left(ServerFailure.noConnection());
    } catch (e, stack) {
      AppLogger.error('getPartnerProfile repository error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  @override
  Stream<UserProfile?> watchPartnerProfile(String partnerId) {
    return _remote
        .watchProfile(partnerId)
        .map((row) => row != null ? _profileFromJson(row) : null);
  }

  // ── Presence ──────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> upsertPresence({
    required String userId,
    required bool isOnline,
  }) async {
    try {
      await _remote.upsertPresence(userId: userId, isOnline: isOnline);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure.server(e.message));
    } catch (e, stack) {
      AppLogger.error('upsertPresence repository error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  @override
  Stream<UserPresence?> watchPartnerPresence(String partnerId) {
    return _remote
        .watchPresence(partnerId)
        .map((row) => row != null ? _presenceFromJson(row) : null);
  }
}
