import 'dart:async';
import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart' hide AuthException;
import '../../../../core/error/failures.dart';
import '../../../../core/logger/app_logger.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/value_objects/email_address.dart';
import '../../domain/value_objects/otp_code.dart';
import '../../domain/value_objects/phone_number.dart';
import '../data_sources/remote/auth_remote_data_source.dart';
import '../data_sources/secure/auth_secure_data_source.dart';
import '../dtos/session_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthSecureDataSource secureDataSource,
  })  : _remote = remoteDataSource,
        _secure = secureDataSource;

  final AuthRemoteDataSource _remote;
  final AuthSecureDataSource _secure;

  @override
  Future<Either<Failure, void>> requestPhoneOtp(PhoneNumber phone) =>
      _wrap(() => _remote.requestPhoneOtp(phone.value));

  @override
  Future<Either<Failure, void>> verifyPhoneOtp(
    PhoneNumber phone,
    OtpCode code,
  ) => _wrap(() => _remote.verifyPhoneOtp(phone.value, code.value));

  @override
  Future<Either<Failure, void>> requestEmailMagicLink(EmailAddress email) =>
      _wrap(() => _remote.requestEmailMagicLink(email.value));

  @override
  Future<Either<Failure, void>> refreshSession() =>
      _wrap(() => _remote.refreshSession());

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remote.signOut();
    } catch (e, stack) {
      // Sign-out failure is non-fatal; log but always clear local state.
      AppLogger.error('Remote sign-out failed', e, stack);
    }
    await _secure.deleteAll();
    return const Right(null);
  }

  @override
  Stream<AppAuthState> watchAuthState() async* {
    // Synchronous initial state from the current Supabase user
    final currentUser = _remote.currentUser;
    if (currentUser == null) {
      yield AppAuthState.unauthenticated;
    } else {
      final hasProfile = await _remote.hasProfile(currentUser.id);
      yield hasProfile ? AppAuthState.authenticated : AppAuthState.registering;
    }

    // supabase_flutter AuthState carries (event, session)
    await for (final supabaseState in _remote.onAuthStateChange) {
      final event = supabaseState.event;
      final session = supabaseState.session;

      if (event == AuthChangeEvent.signedOut) {
        await _secure.deleteAll();
        yield AppAuthState.unauthenticated;
      } else if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        if (session != null) {
          await _secure.saveSession(SessionDto.fromSupabaseSession(session));
          final hasProfile = await _remote.hasProfile(session.user.id);
          yield hasProfile
              ? AppAuthState.authenticated
              : AppAuthState.registering;
        }
      }
      // AuthChangeEvent.userUpdated does not affect auth routing; skip.
    }
  }

  Future<Either<Failure, T>> _wrap<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on AuthException catch (e) {
      return Left(_mapAuthException(e));
    } on ServerException catch (e) {
      return Left(ServerFailure.server(e.message));
    } on SocketException {
      return const Left(ServerFailure.noConnection());
    } on TimeoutException {
      return const Left(ServerFailure.timeout());
    } catch (e, stack) {
      AppLogger.error('Unexpected error in AuthRepository', e, stack);
      return const Left(UnknownFailure());
    }
  }

  Failure _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('expired') || msg.contains('otp_expired')) {
      return const AuthFailure.otpExpired();
    }
    if (msg.contains('invalid') || msg.contains('incorrect')) {
      return const AuthFailure.otpInvalid();
    }
    if (msg.contains('rate') || msg.contains('too many')) {
      return const AuthFailure.rateLimited();
    }
    if (msg.contains('not confirmed') || msg.contains('not_confirmed')) {
      return const AuthFailure.emailNotConfirmed();
    }
    if (msg.contains('not found') || msg.contains('user_not_found')) {
      return const AuthFailure.userNotFound();
    }
    return AuthFailure.server(e.message);
  }
}
