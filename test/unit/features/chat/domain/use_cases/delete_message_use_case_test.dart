import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:rathtech_chatting_app/features/chat/domain/use_cases/delete_message_use_case.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late _MockChatRepository repository;
  late DeleteMessageUseCase useCase;

  setUp(() {
    repository = _MockChatRepository();
    useCase = DeleteMessageUseCase(repository);
  });

  test('delegates to repository.deleteMessage with the given id', () async {
    when(() => repository.deleteMessage(any()))
        .thenAnswer((_) async => const Right(null));

    final result = await useCase.execute('msg-42');

    expect(result.isRight(), isTrue);
    verify(() => repository.deleteMessage('msg-42')).called(1);
  });

  test('propagates Left when repository returns failure', () async {
    when(() => repository.deleteMessage(any()))
        .thenAnswer(
          (_) async => const Left(ServerFailure.server('delete failed')),
        );

    final result = await useCase.execute('msg-99');

    expect(result.isLeft(), isTrue);
  });
}
