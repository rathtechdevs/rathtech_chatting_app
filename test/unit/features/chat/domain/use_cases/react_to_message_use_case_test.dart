import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:rathtech_chatting_app/features/chat/domain/use_cases/react_to_message_use_case.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late _MockChatRepository repository;
  late ReactToMessageUseCase useCase;

  const tParams = ReactToMessageParams(
    messageId: 'msg-1',
    pairId: 'pair-1',
    emoji: '❤️',
  );

  setUp(() {
    repository = _MockChatRepository();
    useCase = ReactToMessageUseCase(repository);
    registerFallbackValue(tParams);
  });

  test('delegates to repository.reactToMessage', () async {
    when(() => repository.reactToMessage(any()))
        .thenAnswer((_) async => const Right(null));

    final result = await useCase.execute(tParams);

    expect(result.isRight(), isTrue);
    verify(() => repository.reactToMessage(tParams)).called(1);
  });

  test('propagates Left when repository returns failure', () async {
    when(() => repository.reactToMessage(any()))
        .thenAnswer(
          (_) async =>
              const Left(ServerFailure.server('react failed')),
        );

    final result = await useCase.execute(tParams);

    expect(result.isLeft(), isTrue);
  });
}
