import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/encryption/encryption_service.dart';
import 'package:rathtech_chatting_app/core/encryption/models/key_bundle.dart';
import 'package:rathtech_chatting_app/core/encryption/remote/key_bundle_remote_data_source.dart';
import 'package:rathtech_chatting_app/core/error/exceptions.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/pairing/domain/use_cases/initialize_pair_session_use_case.dart';

class _MockEncryptionService extends Mock implements EncryptionService {}

class _MockKeyBundleRemoteDataSource extends Mock
    implements KeyBundleRemoteDataSource {}

class _FakeKeyBundle extends Fake implements KeyBundle {}

void main() {
  late _MockEncryptionService mockEncryption;
  late _MockKeyBundleRemoteDataSource mockRemote;
  late InitializePairSessionUseCase sut;

  const tPairId = 'pair-abc';
  const tPartnerId = 'user-partner';

  const tBundle = KeyBundle(
    userId: tPartnerId,
    identityKey: 'ik',
    identitySigningKey: 'isk',
    signedPreKey: 'spk',
    signedPreKeySignature: 'sig',
    signedPreKeyId: 1,
  );

  setUpAll(() {
    registerFallbackValue(_FakeKeyBundle());
  });

  setUp(() {
    mockEncryption = _MockEncryptionService();
    mockRemote = _MockKeyBundleRemoteDataSource();
    sut = InitializePairSessionUseCase(
      encryptionService: mockEncryption,
      keyBundleRemoteDataSource: mockRemote,
    );
  });

  group('InitializePairSessionUseCase', () {
    test('fetches partner bundle then initializes session', () async {
      when(() => mockRemote.fetchPartnerKeyBundle(tPartnerId))
          .thenAnswer((_) async => tBundle);
      when(() => mockEncryption.initializeSession(
            pairId: tPairId,
            partnerBundle: any(named: 'partnerBundle'),
          )).thenAnswer((_) async => const Right(null));

      final result = await sut.execute(
        pairId: tPairId,
        partnerUserId: tPartnerId,
      );

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRemote.fetchPartnerKeyBundle(tPartnerId)).called(1);
      verify(() => mockEncryption.initializeSession(
            pairId: tPairId,
            partnerBundle: any(named: 'partnerBundle'),
          )).called(1);
    });

    test('returns Left(ServerFailure) when fetchPartnerKeyBundle throws ServerException',
        () async {
      when(() => mockRemote.fetchPartnerKeyBundle(any()))
          .thenThrow(const ServerException(message: 'no bundle'));

      final result = await sut.execute(
        pairId: tPairId,
        partnerUserId: tPartnerId,
      );

      expect(result.isLeft(), isTrue);
      expect(
        result.fold((f) => f, (_) => null),
        isA<ServerFailure>(),
      );
      verifyNever(() => mockEncryption.initializeSession(
            pairId: any(named: 'pairId'),
            partnerBundle: any(named: 'partnerBundle'),
          ));
    });

    test('returns Left(UnknownFailure) when fetchPartnerKeyBundle throws unexpected exception',
        () async {
      when(() => mockRemote.fetchPartnerKeyBundle(any()))
          .thenThrow(Exception('network reset'));

      final result = await sut.execute(
        pairId: tPairId,
        partnerUserId: tPartnerId,
      );

      expect(result, const Left<Failure, void>(UnknownFailure()));
    });

    test('propagates Left from initializeSession when key exchange fails',
        () async {
      when(() => mockRemote.fetchPartnerKeyBundle(any()))
          .thenAnswer((_) async => tBundle);
      const failure = EncryptionFailure.keyGenerationFailed();
      when(() => mockEncryption.initializeSession(
            pairId: any(named: 'pairId'),
            partnerBundle: any(named: 'partnerBundle'),
          )).thenAnswer((_) async => const Left(failure));

      final result = await sut.execute(
        pairId: tPairId,
        partnerUserId: tPartnerId,
      );

      expect(result, const Left<Failure, void>(failure));
    });
  });
}
