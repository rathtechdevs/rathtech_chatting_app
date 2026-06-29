import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:rathtech_chatting_app/features/notifications/domain/use_cases/update_notification_token_use_case.dart';

class _MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late UpdateNotificationTokenUseCase sut;
  late _MockNotificationRepository mockRepo;

  const tUserId = 'user-123';
  const tToken = 'fcm-token-xyz';

  setUp(() {
    mockRepo = _MockNotificationRepository();
    sut = UpdateNotificationTokenUseCase(mockRepo);
  });

  group('UpdateNotificationTokenUseCase', () {
    test('delegates to repository.registerToken and returns Right', () async {
      when(
        () => mockRepo.registerToken(userId: tUserId, token: tToken),
      ).thenAnswer((_) async => const Right(null));

      final result = await sut.execute(userId: tUserId, token: tToken);

      expect(result, const Right<Failure, void>(null));
      verify(
        () => mockRepo.registerToken(userId: tUserId, token: tToken),
      ).called(1);
    });

    test('propagates Left from repository', () async {
      when(
        () => mockRepo.registerToken(userId: tUserId, token: tToken),
      ).thenAnswer((_) async => const Left(ServerFailure.server()));

      final result = await sut.execute(userId: tUserId, token: tToken);

      expect(result.isLeft(), isTrue);
    });
  });
}
