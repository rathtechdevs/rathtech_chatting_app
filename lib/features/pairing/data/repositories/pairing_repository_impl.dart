import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logger/app_logger.dart';
import '../../domain/entities/pair.dart';
import '../../domain/entities/pair_invite_code.dart';
import '../../domain/repositories/pairing_repository.dart';
import '../data_sources/remote/pairing_remote_data_source.dart';
import '../dtos/invite_code_dto.dart';
import '../dtos/pair_dto.dart';

class PairingRepositoryImpl implements PairingRepository {
  const PairingRepositoryImpl({
    required PairingRemoteDataSource remoteDataSource,
    required SupabaseClient client,
  })  : _remote = remoteDataSource,
        _client = client;

  final PairingRemoteDataSource _remote;
  final SupabaseClient _client;

  @override
  Future<Either<Failure, PairInviteCode>> generateInviteCode() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Left(AuthFailure.unauthorized());

    try {
      final code = PairingRemoteDataSourceImpl.freshCode();
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));
      final json = await _remote.generateInviteCode(
        userId: userId,
        code: code,
        expiresAt: expiresAt,
      );
      return Right(InviteCodeDto.fromJson(json).toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure.server(e.message));
    } on SocketException {
      return const Left(ServerFailure.noConnection());
    } catch (e, stack) {
      AppLogger.error('generateInviteCode repository error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Pair>> acceptInviteCode(String code) async {
    try {
      final json = await _remote.acceptInviteCode(code);
      final pairId = json['pair_id'] as String;
      final partnerId = json['partner_id'] as String;
      final userId = _client.auth.currentUser?.id ?? '';

      // Build a minimal Pair from the Edge Function response.
      // user_a_id = creator = partner; user_b_id = accepter = us.
      return Right(Pair(
        id: pairId,
        userAId: partnerId,
        userBId: userId,
        createdAt: DateTime.now(),
      ));
    } on ServerException catch (e) {
      return _mapServerException(e);
    } on SocketException {
      return const Left(ServerFailure.noConnection());
    } catch (e, stack) {
      AppLogger.error('acceptInviteCode repository error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, Pair?>> getCurrentPair() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const Right(null);

    try {
      final json = await _remote.getCurrentPair(userId);
      if (json == null) return const Right(null);
      return Right(PairDto.fromJson(json).toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure.server(e.message));
    } on SocketException {
      return const Left(ServerFailure.noConnection());
    } catch (e, stack) {
      AppLogger.error('getCurrentPair repository error', e, stack);
      return const Left(UnknownFailure());
    }
  }

  @override
  Stream<Either<Failure, Pair?>> watchPairStatus() async* {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      yield const Right(null);
      return;
    }

    await for (final json in _remote.watchPairStatus(userId)) {
      try {
        if (json == null) {
          yield const Right(null);
        } else {
          yield Right(PairDto.fromJson(json).toEntity());
        }
      } catch (e, stack) {
        AppLogger.error('watchPairStatus map error', e, stack);
        yield const Left(UnknownFailure());
      }
    }
  }

  Either<Failure, Pair> _mapServerException(ServerException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid') || msg.contains('not found')) {
      return const Left(PairFailure.invalidCode());
    }
    if (msg.contains('expired')) {
      return const Left(PairFailure.expiredCode());
    }
    if (msg.contains('own invite')) {
      return const Left(PairFailure.ownCode());
    }
    if (msg.contains('already paired')) {
      return const Left(PairFailure.alreadyPaired());
    }
    return Left(ServerFailure.server(e.message));
  }
}
