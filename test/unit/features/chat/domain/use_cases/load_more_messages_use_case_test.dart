import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/chat/domain/entities/message.dart';
import 'package:rathtech_chatting_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:rathtech_chatting_app/features/chat/domain/use_cases/load_more_messages_use_case.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

class _FakeLoadMoreParams extends Fake implements LoadMoreParams {}

void main() {
  late _MockChatRepository mockRepo;
  late LoadMoreMessagesUseCase sut;

  final tParams = LoadMoreParams(
    pairId: 'pair-1',
    before: DateTime(2024),
  );

  setUpAll(() => registerFallbackValue(_FakeLoadMoreParams()));

  setUp(() {
    mockRepo = _MockChatRepository();
    sut = LoadMoreMessagesUseCase(mockRepo);
  });

  group('LoadMoreMessagesUseCase', () {
    test('returns Right(messages) when repository succeeds', () async {
      when(() => mockRepo.loadMoreMessages(any()))
          .thenAnswer((_) async => const Right(<Message>[]));

      final result = await sut.execute(tParams);

      expect(result.isRight(), isTrue);
      verify(() => mockRepo.loadMoreMessages(tParams)).called(1);
    });

    test('returns Left(failure) when repository fails', () async {
      const failure = ServerFailure.server('pagination error');
      when(() => mockRepo.loadMoreMessages(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await sut.execute(tParams);

      expect(result, const Left<Failure, List<Message>>(failure));
    });
  });
}
