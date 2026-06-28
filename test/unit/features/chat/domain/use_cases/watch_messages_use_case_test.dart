import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/chat/domain/entities/message.dart';
import 'package:rathtech_chatting_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:rathtech_chatting_app/features/chat/domain/use_cases/watch_messages_use_case.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late _MockChatRepository repository;
  late WatchMessagesUseCase useCase;

  const tPairId = 'pair-id';

  setUp(() {
    repository = _MockChatRepository();
    useCase = WatchMessagesUseCase(repository);
  });

  test('emits Right(messages) when repository yields messages', () async {
    final tMessages = [
      Message(
        id: 'msg-1',
        pairId: tPairId,
        senderId: 'user-a',
        contentType: 'text',
        text: 'Hi',
        status: MessageStatus.sent,
        createdAt: DateTime(2024),
      ),
    ];

    when(() => repository.watchMessages(any()))
        .thenAnswer((_) => Stream.value(Right(tMessages)));

    final result = await useCase.execute(tPairId).first;

    expect(result.isRight(), isTrue);
    expect(result.getOrElse((_) => []), tMessages);
    verify(() => repository.watchMessages(tPairId)).called(1);
  });

  test('emits Left(Failure) when repository yields failure', () async {
    when(() => repository.watchMessages(any()))
        .thenAnswer((_) => Stream.value(const Left(UnknownFailure())));

    final result = await useCase.execute(tPairId).first;

    expect(result.isLeft(), isTrue);
  });
}
