import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:rathtech_chatting_app/features/chat/domain/use_cases/mark_all_read_use_case.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late _MockChatRepository mockRepo;
  late MarkAllReadUseCase sut;

  const tPairId = 'pair-1';

  setUp(() {
    mockRepo = _MockChatRepository();
    sut = MarkAllReadUseCase(mockRepo);
  });

  group('MarkAllReadUseCase', () {
    test('returns Right(null) when repository succeeds', () async {
      when(() => mockRepo.markAllRead(any()))
          .thenAnswer((_) async => const Right(null));

      final result = await sut.execute(tPairId);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepo.markAllRead(tPairId)).called(1);
    });

    test('returns Left(failure) when repository fails', () async {
      const failure = ServerFailure.server('update failed');
      when(() => mockRepo.markAllRead(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await sut.execute(tPairId);

      expect(result, const Left<Failure, void>(failure));
    });
  });
}
