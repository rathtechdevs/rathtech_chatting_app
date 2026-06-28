import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/chat/domain/entities/message.dart';
import 'package:rathtech_chatting_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:rathtech_chatting_app/features/chat/domain/use_cases/edit_message_use_case.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  late _MockChatRepository repository;
  late EditMessageUseCase useCase;

  final tCreatedAt = DateTime(2024, 1, 1, 12);

  setUp(() {
    repository = _MockChatRepository();
    useCase = EditMessageUseCase(repository);
    registerFallbackValue(
      EditMessageParams(
        messageId: 'id',
        pairId: 'pair',
        newText: 'new',
        originalCreatedAt: tCreatedAt,
      ),
    );
  });

  test('returns Left(ValidationFailure) when message is older than 15 min',
      () async {
    final params = EditMessageParams(
      messageId: 'msg-1',
      pairId: 'pair-1',
      newText: 'edited',
      originalCreatedAt: DateTime.now().subtract(const Duration(minutes: 20)),
    );

    final result = await useCase.execute(params);

    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repository.editMessage(any()));
  });

  test('delegates to repository when within the 15-min window', () async {
    final params = EditMessageParams(
      messageId: 'msg-1',
      pairId: 'pair-1',
      newText: 'edited text',
      originalCreatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    );

    final tMessage = Message(
      id: 'msg-1',
      pairId: 'pair-1',
      senderId: 'user-1',
      contentType: 'text',
      text: 'edited text',
      status: MessageStatus.sent,
      createdAt: tCreatedAt,
    );

    when(() => repository.editMessage(any()))
        .thenAnswer((_) async => Right(tMessage));

    final result = await useCase.execute(params);

    expect(result.isRight(), isTrue);
    verify(() => repository.editMessage(any())).called(1);
  });
}
