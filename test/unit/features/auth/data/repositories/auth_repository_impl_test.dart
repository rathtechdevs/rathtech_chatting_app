import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/exceptions.dart' hide AuthException;
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/auth/data/data_sources/remote/auth_remote_data_source.dart';
import 'package:rathtech_chatting_app/features/auth/data/data_sources/secure/auth_secure_data_source.dart';
import 'package:rathtech_chatting_app/features/auth/data/dtos/session_dto.dart';
import 'package:rathtech_chatting_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:rathtech_chatting_app/features/auth/domain/entities/auth_session.dart';
import 'package:rathtech_chatting_app/features/auth/domain/value_objects/email_address.dart';
import 'package:rathtech_chatting_app/features/auth/domain/value_objects/otp_code.dart';
import 'package:rathtech_chatting_app/features/auth/domain/value_objects/phone_number.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockSecure extends Mock implements AuthSecureDataSource {}

class _FakeSessionDto extends Fake implements SessionDto {}

PhoneNumber _phone(String raw) =>
    PhoneNumber.create(raw).fold((_) => throw Exception('bad test data'), (p) => p);

OtpCode _code(String raw) =>
    OtpCode.create(raw).fold((_) => throw Exception('bad test data'), (c) => c);

EmailAddress _email(String raw) =>
    EmailAddress.create(raw).fold((_) => throw Exception('bad test data'), (e) => e);

void main() {
  late _MockRemote mockRemote;
  late _MockSecure mockSecure;
  late AuthRepositoryImpl sut;

  final tPhone = _phone('+14155552671');
  final tCode = _code('123456');
  final tEmail = _email('test@example.com');

  setUpAll(() {
    registerFallbackValue(_FakeSessionDto());
    registerFallbackValue(tPhone);
    registerFallbackValue(tCode);
    registerFallbackValue(tEmail);
  });

  setUp(() {
    mockRemote = _MockRemote();
    mockSecure = _MockSecure();
    sut = AuthRepositoryImpl(
      remoteDataSource: mockRemote,
      secureDataSource: mockSecure,
    );
  });

  // ── requestPhoneOtp ─────────────────────────────────────────────────────────

  group('requestPhoneOtp', () {
    test('returns Right(null) when remote succeeds', () async {
      when(() => mockRemote.requestPhoneOtp(any())).thenAnswer((_) async {});

      final result = await sut.requestPhoneOtp(tPhone);

      expect(result, const Right<Failure, void>(null));
    });

    test('maps AuthException "expired" → Left(AuthFailure.otpExpired)', () async {
      when(() => mockRemote.requestPhoneOtp(any()))
          .thenThrow(const AuthException('otp_expired'));

      final result = await sut.requestPhoneOtp(tPhone);

      result.fold(
        (f) => expect(f, const AuthFailure.otpExpired()),
        (_) => fail('Expected Left'),
      );
    });

    test('maps AuthException "invalid" → Left(AuthFailure.otpInvalid)', () async {
      when(() => mockRemote.requestPhoneOtp(any()))
          .thenThrow(const AuthException('invalid code'));

      final result = await sut.requestPhoneOtp(tPhone);

      result.fold(
        (f) => expect(f, const AuthFailure.otpInvalid()),
        (_) => fail('Expected Left'),
      );
    });

    test('maps ServerException → Left(ServerFailure.server)', () async {
      when(() => mockRemote.requestPhoneOtp(any()))
          .thenThrow(const ServerException(message: 'upstream error'));

      final result = await sut.requestPhoneOtp(tPhone);

      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('maps SocketException → Left(ServerFailure.noConnection)', () async {
      when(() => mockRemote.requestPhoneOtp(any()))
          .thenThrow(const SocketException('no network'));

      final result = await sut.requestPhoneOtp(tPhone);

      expect(result, const Left<Failure, void>(ServerFailure.noConnection()));
    });

    test('maps TimeoutException → Left(ServerFailure.timeout)', () async {
      when(() => mockRemote.requestPhoneOtp(any()))
          .thenThrow(TimeoutException('timed out'));

      final result = await sut.requestPhoneOtp(tPhone);

      expect(result, const Left<Failure, void>(ServerFailure.timeout()));
    });
  });

  // ── requestEmailMagicLink ───────────────────────────────────────────────────

  group('requestEmailMagicLink', () {
    test('returns Right(null) when remote succeeds', () async {
      when(() => mockRemote.requestEmailMagicLink(any())).thenAnswer((_) async {});

      final result = await sut.requestEmailMagicLink(tEmail);

      expect(result, const Right<Failure, void>(null));
    });

    test('maps ServerException → Left(ServerFailure)', () async {
      when(() => mockRemote.requestEmailMagicLink(any()))
          .thenThrow(const ServerException(message: 'smtp error'));

      final result = await sut.requestEmailMagicLink(tEmail);

      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  // ── logout ──────────────────────────────────────────────────────────────────

  group('logout', () {
    test('calls signOut + deleteAll and returns Right(null)', () async {
      when(() => mockRemote.signOut()).thenAnswer((_) async {});
      when(() => mockSecure.deleteAll()).thenAnswer((_) async {});

      final result = await sut.logout();

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRemote.signOut()).called(1);
      verify(() => mockSecure.deleteAll()).called(1);
    });

    test('returns Right(null) even if signOut throws — deleteAll still called',
        () async {
      when(() => mockRemote.signOut()).thenThrow(Exception('network error'));
      when(() => mockSecure.deleteAll()).thenAnswer((_) async {});

      final result = await sut.logout();

      expect(result, const Right<Failure, void>(null));
      verify(() => mockSecure.deleteAll()).called(1);
    });
  });

  // ── watchAuthState — initial unauthenticated ────────────────────────────────

  group('watchAuthState', () {
    test('emits unauthenticated when currentUser is null', () async {
      when(() => mockRemote.currentUser).thenReturn(null);
      when(() => mockRemote.onAuthStateChange)
          .thenAnswer((_) => const Stream.empty());

      final first = await sut.watchAuthState().first;

      expect(first, AppAuthState.unauthenticated);
    });

    test('emits authenticated when currentUser exists and hasProfile', () async {
      const tUserId = 'uid-1';
      when(() => mockRemote.currentUser).thenReturn(
        const User(
          id: tUserId,
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2024-01-01T00:00:00.000Z',
        ),
      );
      when(() => mockRemote.hasProfile(tUserId)).thenAnswer((_) async => true);
      when(() => mockRemote.onAuthStateChange)
          .thenAnswer((_) => const Stream.empty());

      final first = await sut.watchAuthState().first;

      expect(first, AppAuthState.authenticated);
    });

    test('emits registering when currentUser exists but no profile', () async {
      const tUserId = 'uid-1';
      when(() => mockRemote.currentUser).thenReturn(
        const User(
          id: tUserId,
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2024-01-01T00:00:00.000Z',
        ),
      );
      when(() => mockRemote.hasProfile(tUserId)).thenAnswer((_) async => false);
      when(() => mockRemote.onAuthStateChange)
          .thenAnswer((_) => const Stream.empty());

      final first = await sut.watchAuthState().first;

      expect(first, AppAuthState.registering);
    });
  });
}
