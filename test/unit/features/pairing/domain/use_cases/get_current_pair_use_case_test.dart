import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/pairing/domain/entities/pair.dart';
import 'package:rathtech_chatting_app/features/pairing/domain/repositories/pairing_repository.dart';
import 'package:rathtech_chatting_app/features/pairing/domain/use_cases/get_current_pair_use_case.dart';

class _MockPairingRepository extends Mock implements PairingRepository {}

void main() {
  late _MockPairingRepository mockRepo;
  late GetCurrentPairUseCase sut;

  setUp(() {
    mockRepo = _MockPairingRepository();
    sut = GetCurrentPairUseCase(mockRepo);
  });

  final tPair = Pair(
    id: 'pair-1',
    userAId: 'user-a',
    userBId: 'user-b',
    createdAt: DateTime(2024),
  );

  group('GetCurrentPairUseCase', () {
    test('returns Right(pair) when user is paired', () async {
      when(() => mockRepo.getCurrentPair())
          .thenAnswer((_) async => Right(tPair));

      final result = await sut.execute();

      expect(result, Right<Failure, Pair?>(tPair));
      verify(() => mockRepo.getCurrentPair()).called(1);
    });

    test('returns Right(null) when user is not yet paired', () async {
      when(() => mockRepo.getCurrentPair())
          .thenAnswer((_) async => const Right(null));

      final result = await sut.execute();

      expect(result, const Right<Failure, Pair?>(null));
    });

    test('returns Left(failure) when repository fails', () async {
      const failure = ServerFailure.noConnection();
      when(() => mockRepo.getCurrentPair())
          .thenAnswer((_) async => const Left(failure));

      final result = await sut.execute();

      expect(result, const Left<Failure, Pair?>(failure));
    });
  });
}
