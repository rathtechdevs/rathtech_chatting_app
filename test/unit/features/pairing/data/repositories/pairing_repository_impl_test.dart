import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/exceptions.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/pairing/data/data_sources/remote/pairing_remote_data_source.dart';
import 'package:rathtech_chatting_app/features/pairing/data/repositories/pairing_repository_impl.dart';
import 'package:rathtech_chatting_app/features/pairing/domain/entities/pair.dart';
import 'package:rathtech_chatting_app/features/pairing/domain/entities/pair_invite_code.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockPairingRemoteDataSource extends Mock
    implements PairingRemoteDataSource {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockSupabaseClient extends Mock implements SupabaseClient {
  _MockSupabaseClient(this._auth);
  final GoTrueClient _auth;
  @override
  GoTrueClient get auth => _auth;
}

void main() {
  late _MockPairingRemoteDataSource remote;
  late _MockGoTrueClient goTrueClient;
  late _MockSupabaseClient client;
  late PairingRepositoryImpl repository;

  const tUserId = 'user-b';
  const tPartnerId = 'user-a';
  const tPairId = 'pair-id';
  const tCode = 'ABCD1234';

  setUp(() {
    remote = _MockPairingRemoteDataSource();
    goTrueClient = _MockGoTrueClient();
    client = _MockSupabaseClient(goTrueClient);

    final mockUser = User(
      id: tUserId,
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: DateTime(2024).toIso8601String(),
    );
    when(() => goTrueClient.currentUser).thenReturn(mockUser);

    repository = PairingRepositoryImpl(
      remoteDataSource: remote,
      client: client,
    );
  });

  group('generateInviteCode', () {
    test('returns PairInviteCode on success', () async {
      final now = DateTime(2024);
      final expires = now.add(const Duration(minutes: 10));
      final tJson = {
        'id': 'invite-id',
        'code': tCode,
        'creator_id': tUserId,
        'expires_at': expires.toIso8601String(),
        'used': false,
        'created_at': now.toIso8601String(),
      };

      when(() => remote.generateInviteCode(
            userId: any(named: 'userId'),
            code: any(named: 'code'),
            expiresAt: any(named: 'expiresAt'),
          )).thenAnswer((_) async => tJson);

      final result = await repository.generateInviteCode();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => throw Exception()),
          isA<PairInviteCode>());
    });
  });

  group('acceptInviteCode', () {
    test('returns Pair from Edge Function response', () async {
      when(() => remote.acceptInviteCode(tCode)).thenAnswer(
        (_) async => {'pair_id': tPairId, 'partner_id': tPartnerId},
      );

      final result = await repository.acceptInviteCode(tCode);

      expect(result.isRight(), isTrue);
      final pair = result.getOrElse((_) => throw Exception());
      expect(pair.id, tPairId);
      expect(pair.userAId, tPartnerId);
      expect(pair.userBId, tUserId);
    });

    test('maps server invalid code error to PairFailure.invalidCode', () async {
      when(() => remote.acceptInviteCode(any())).thenThrow(
        const ServerException(message: 'Invalid invite code', statusCode: 404),
      );

      final result = await repository.acceptInviteCode(tCode);

      expect(result.isLeft(), isTrue);
      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<PairFailure>());
    });

    test('maps "already paired" error to PairFailure.alreadyPaired', () async {
      when(() => remote.acceptInviteCode(any())).thenThrow(
        const ServerException(message: 'already paired', statusCode: 409),
      );

      final result = await repository.acceptInviteCode(tCode);

      expect(result.isLeft(), isTrue);
      final failure = result.fold((f) => f, (_) => null);
      expect(failure, const PairFailure.alreadyPaired());
    });
  });

  group('getCurrentPair', () {
    test('returns null when no pair exists', () async {
      when(() => remote.getCurrentPair(tUserId))
          .thenAnswer((_) async => null);

      final result = await repository.getCurrentPair();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => throw Exception()), isNull);
    });

    test('returns Pair when paired', () async {
      final now = DateTime(2024);
      when(() => remote.getCurrentPair(tUserId)).thenAnswer((_) async => {
            'id': tPairId,
            'user_a_id': tPartnerId,
            'user_b_id': tUserId,
            'created_at': now.toIso8601String(),
          });

      final result = await repository.getCurrentPair();

      expect(result.isRight(), isTrue);
      final pair = result.getOrElse((_) => throw Exception());
      expect(pair, isA<Pair>());
      expect(pair!.id, tPairId);
    });
  });
}
