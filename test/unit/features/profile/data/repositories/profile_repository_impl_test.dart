import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/exceptions.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/profile/data/data_sources/remote/profile_remote_data_source.dart';
import 'package:rathtech_chatting_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:rathtech_chatting_app/features/profile/domain/entities/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late ProfileRepositoryImpl sut;
  late _MockProfileRemoteDataSource mockRemote;
  late _MockSupabaseClient mockClient;
  late _MockGoTrueClient mockAuth;

  const tUserId = 'user-abc';
  final tProfileJson = {
    'id': tUserId,
    'display_name': 'Alice',
    'avatar_url': null,
    'date_of_birth': null,
    'created_at': '2024-01-01T00:00:00.000Z',
  };
  final tProfile = UserProfile(
    id: tUserId,
    displayName: 'Alice',
    createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
  );

  setUp(() {
    mockRemote = _MockProfileRemoteDataSource();
    mockClient = _MockSupabaseClient();
    mockAuth = _MockGoTrueClient();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(
      const User(
        id: tUserId,
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2024-01-01T00:00:00.000Z',
      ),
    );

    sut = ProfileRepositoryImpl(
      remoteDataSource: mockRemote,
      client: mockClient,
    );
  });

  group('updateProfile', () {
    test('returns Right(UserProfile) on success', () async {
      when(
        () => mockRemote.updateProfile(
          userId: tUserId,
          displayName: 'Alice',
        ),
      ).thenAnswer((_) async => tProfileJson);

      final result = await sut.updateProfile(displayName: 'Alice');

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => throw StateError('')).displayName, 'Alice');
    });

    test('returns Left(ServerFailure) when remote throws ServerException',
        () async {
      when(
        () => mockRemote.updateProfile(
          userId: tUserId,
          displayName: 'Alice',
        ),
      ).thenThrow(const ServerException(message: 'DB error'));

      final result = await sut.updateProfile(displayName: 'Alice');

      expect(result.isLeft(), isTrue);
      expect(result.fold((l) => l, (_) => null), isA<ServerFailure>());
    });

    test('returns Left(AuthFailure) when no current user', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await sut.updateProfile(displayName: 'Alice');

      expect(result.isLeft(), isTrue);
      expect(result.fold((l) => l, (_) => null), isA<AuthFailure>());
    });
  });

  group('getPartnerProfile', () {
    test('returns Right(UserProfile) when profile found', () async {
      when(() => mockRemote.getProfile('partner-id'))
          .thenAnswer((_) async => tProfileJson);

      final result = await sut.getPartnerProfile('partner-id');

      expect(result.isRight(), isTrue);
      expect(
        result.getOrElse((_) => throw StateError(''))?.displayName,
        tProfile.displayName,
      );
    });

    test('returns Right(null) when profile not found', () async {
      when(() => mockRemote.getProfile('partner-id'))
          .thenAnswer((_) async => null);

      final result = await sut.getPartnerProfile('partner-id');

      expect(result, const Right<Failure, UserProfile?>(null));
    });
  });

  group('upsertPresence', () {
    test('returns Right on success', () async {
      when(
        () => mockRemote.upsertPresence(
          userId: tUserId,
          isOnline: true,
        ),
      ).thenAnswer((_) async {});

      final result =
          await sut.upsertPresence(userId: tUserId, isOnline: true);

      expect(result, const Right<Failure, void>(null));
    });

    test('returns Left(ServerFailure) when remote throws', () async {
      when(
        () => mockRemote.upsertPresence(
          userId: tUserId,
          isOnline: false,
        ),
      ).thenThrow(const ServerException(message: 'Network error'));

      final result =
          await sut.upsertPresence(userId: tUserId, isOnline: false);

      expect(result.isLeft(), isTrue);
    });
  });

  group('watchPartnerPresence', () {
    test('maps JSON rows to UserPresence', () async {
      final presenceJson = {
        'user_id': 'partner-id',
        'is_online': true,
        'last_seen_at': '2024-06-01T12:00:00.000Z',
      };
      final controller = StreamController<Map<String, dynamic>?>.broadcast();

      when(() => mockRemote.watchPresence('partner-id'))
          .thenAnswer((_) => controller.stream);

      final stream = sut.watchPartnerPresence('partner-id');

      expect(
        stream,
        emits(
          predicate<dynamic>((p) => p != null && (p as dynamic).isOnline == true),
        ),
      );
      controller.add(presenceJson);
      await Future<void>.delayed(Duration.zero);
      await controller.close();
    });
  });
}
