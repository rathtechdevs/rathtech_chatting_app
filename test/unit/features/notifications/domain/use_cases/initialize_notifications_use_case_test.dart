import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/core/notifications/notification_service.dart';
import 'package:rathtech_chatting_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:rathtech_chatting_app/features/notifications/domain/use_cases/initialize_notifications_use_case.dart';

class _MockNotificationRepository extends Mock
    implements NotificationRepository {}

class _MockNotificationService extends Mock implements NotificationService {}

void main() {
  late InitializeNotificationsUseCase sut;
  late _MockNotificationRepository mockRepo;
  late _MockNotificationService mockService;

  const tUserId = 'user-123';
  const tToken = 'fcm-token-abc';

  setUp(() {
    mockRepo = _MockNotificationRepository();
    mockService = _MockNotificationService();
    sut = InitializeNotificationsUseCase(mockRepo, mockService);
  });

  group('InitializeNotificationsUseCase', () {
    test('returns Right(true) when permission granted and token saved', () async {
      when(() => mockRepo.requestPermission())
          .thenAnswer((_) async => const Right(true));
      when(() => mockService.getToken())
          .thenAnswer((_) async => tToken);
      when(
        () => mockRepo.registerToken(userId: tUserId, token: tToken),
      ).thenAnswer((_) async => const Right(null));

      final result = await sut.execute(tUserId);

      expect(result, const Right<Failure, bool>(true));
      verify(() => mockRepo.requestPermission()).called(1);
      verify(() => mockService.getToken()).called(1);
      verify(
        () => mockRepo.registerToken(userId: tUserId, token: tToken),
      ).called(1);
    });

    test('returns Right(false) when user denies permission', () async {
      when(() => mockRepo.requestPermission())
          .thenAnswer((_) async => const Right(false));

      final result = await sut.execute(tUserId);

      expect(result, const Right<Failure, bool>(false));
      verifyNever(() => mockService.getToken());
      verifyNever(
        () => mockRepo.registerToken(userId: any(named: 'userId'), token: any(named: 'token')),
      );
    });

    test('returns Left(PermissionFailure) when requestPermission fails', () async {
      when(() => mockRepo.requestPermission()).thenAnswer(
        (_) async => const Left(PermissionFailure.notifications()),
      );

      final result = await sut.execute(tUserId);

      expect(result.isLeft(), isTrue);
      verifyNever(() => mockService.getToken());
    });

    test('returns Right(false) when FCM token is null', () async {
      when(() => mockRepo.requestPermission())
          .thenAnswer((_) async => const Right(true));
      when(() => mockService.getToken()).thenAnswer((_) async => null);

      final result = await sut.execute(tUserId);

      expect(result, const Right<Failure, bool>(false));
      verifyNever(
        () => mockRepo.registerToken(userId: any(named: 'userId'), token: any(named: 'token')),
      );
    });

    test('returns Left(ServerFailure) when registerToken fails', () async {
      when(() => mockRepo.requestPermission())
          .thenAnswer((_) async => const Right(true));
      when(() => mockService.getToken()).thenAnswer((_) async => tToken);
      when(
        () => mockRepo.registerToken(userId: tUserId, token: tToken),
      ).thenAnswer((_) async => const Left(ServerFailure.server()));

      final result = await sut.execute(tUserId);

      expect(result.isLeft(), isTrue);
    });
  });
}
