import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/chat/domain/entities/message.dart';
import 'package:rathtech_chatting_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:rathtech_chatting_app/features/chat/domain/use_cases/send_message_use_case.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late _MockChatRepository repository;
  late SendMessageUseCase useCase;

  const tParams = SendMessageParams(
    pairId: 'pair-id',
    senderId: 'user-a',
    partnerId: 'user-b',
    text: 'Hello!',
  );

  final tMessage = Message(
    id: 'msg-id',
    pairId: 'pair-id',
    senderId: 'user-a',
    contentType: 'text',
    text: 'Hello!',
    status: MessageStatus.sent,
    createdAt: DateTime(2024),
  );

  setUp(() {
    repository = _MockChatRepository();
    useCase = SendMessageUseCase(repository);

    registerFallbackValue(tParams);
  });

  test('delegates to repository and returns Right(Message) on success', () async {
    when(() => repository.sendMessage(any()))
        .thenAnswer((_) async => Right(tMessage));

    final result = await useCase.execute(tParams);

    expect(result.isRight(), isTrue);
    verify(() => repository.sendMessage(tParams)).called(1);
  });

  test('returns Left(Failure) when repository fails', () async {
    when(() => repository.sendMessage(any()))
        .thenAnswer((_) async => const Left(ServerFailure.server()));

    final result = await useCase.execute(tParams);

    expect(result.isLeft(), isTrue);
  });
}
