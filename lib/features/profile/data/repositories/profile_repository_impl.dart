import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logger/app_logger.dart';
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

  @override
  Future<Either<Failure, UserProfile>> createProfile({
    required DisplayName displayName,
    DateTime? dateOfBirth,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const Left(AuthFailure.unauthorized());
    }

    try {
      final data = await _remote.createProfile(
        userId: userId,
        displayName: displayName.value,
        dateOfBirth: dateOfBirth,
      );
      return Right(_fromJson(data));
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
    final userId = _client.auth.currentUser?.id;
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
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Right(null);

    try {
      final data = await _remote.getProfile(userId);
      return Right(data != null ? _fromJson(data) : null);
    } on ServerException catch (e) {
      return Left(ServerFailure.server(e.message));
    } on SocketException {
      return const Left(ServerFailure.noConnection());
    } catch (e, stack) {
      AppLogger.error('getOwnProfile repository error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  UserProfile _fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    displayName: json['display_name'] as String,
    avatarUrl: json['avatar_url'] as String?,
    dateOfBirth: json['date_of_birth'] != null
        ? DateTime.parse(json['date_of_birth'] as String)
        : null,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
