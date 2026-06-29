import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/chat/domain/entities/message.dart';
import 'package:rathtech_chatting_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:rathtech_chatting_app/features/chat/domain/use_cases/send_media_message_use_case.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

class _FakeSendMediaParams extends Fake implements SendMediaParams {}

void main() {
  late _MockChatRepository repository;
  late SendMediaMessageUseCase useCase;

  const tParams = SendMediaParams(
    pairId: 'pair-id',
    senderId: 'user-a',
    partnerId: 'user-b',
    contentType: 'image',
    localFilePath: '/tmp/test.jpg',
  );

  final tMessage = Message(
    id: 'msg-id',
    pairId: 'pair-id',
    senderId: 'user-a',
    contentType: 'image',
    mediaLocalPath: '/tmp/test.jpg',
    status: MessageStatus.sent,
    createdAt: DateTime(2024),
  );

  setUp(() {
    repository = _MockChatRepository();
    useCase = SendMediaMessageUseCase(repository);
    registerFallbackValue(_FakeSendMediaParams());
  });

  test('delegates to repository and returns Right(Message) on success', () async {
    when(() => repository.sendMediaMessage(any()))
        .thenAnswer((_) async => Right(tMessage));

    final result = await useCase.execute(tParams);

    expect(result.isRight(), isTrue);
    final msg = result.getOrElse((_) => throw Exception());
    expect(msg.contentType, 'image');
    expect(msg.mediaLocalPath, '/tmp/test.jpg');
    verify(() => repository.sendMediaMessage(tParams)).called(1);
  });

  test('returns Left(Failure) when repository fails', () async {
    when(() => repository.sendMediaMessage(any()))
        .thenAnswer((_) async => const Left(ServerFailure.server()));

    final result = await useCase.execute(tParams);

    expect(result.isLeft(), isTrue);
    verify(() => repository.sendMediaMessage(tParams)).called(1);
  });

  test('delegates voice message with durationMs to repository', () async {
    const tVoiceParams = SendMediaParams(
      pairId: 'pair-id',
      senderId: 'user-a',
      partnerId: 'user-b',
      contentType: 'voice',
      localFilePath: '/tmp/voice.m4a',
      durationMs: 3500,
    );
    final tVoiceMessage = Message(
      id: 'voice-id',
      pairId: 'pair-id',
      senderId: 'user-a',
      contentType: 'voice',
      mediaDurationMs: 3500,
      status: MessageStatus.sent,
      createdAt: DateTime(2024),
    );

    when(() => repository.sendMediaMessage(any()))
        .thenAnswer((_) async => Right(tVoiceMessage));

    final result = await useCase.execute(tVoiceParams);

    expect(result.isRight(), isTrue);
    final msg = result.getOrElse((_) => throw Exception());
    expect(msg.contentType, 'voice');
    expect(msg.mediaDurationMs, 3500);
    verify(() => repository.sendMediaMessage(tVoiceParams)).called(1);
  });
}
