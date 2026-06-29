import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rathtech_chatting_app/core/error/exceptions.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/core/notifications/notification_service.dart';
import 'package:rathtech_chatting_app/features/notifications/data/data_sources/notification_remote_data_source.dart';
import 'package:rathtech_chatting_app/features/notifications/data/repositories/notification_repository_impl.dart';

class _MockNotificationService extends Mock implements NotificationService {}

class _MockNotificationRemoteDataSource extends Mock
    implements NotificationRemoteDataSource {}

void main() {
  late NotificationRepositoryImpl sut;
  late _MockNotificationService mockService;
  late _MockNotificationRemoteDataSource mockRemote;

  const tUserId = 'user-abc';
  const tToken = 'fcm-token-def';

  setUp(() {
    mockService = _MockNotificationService();
    mockRemote = _MockNotificationRemoteDataSource();
    sut = NotificationRepositoryImpl(
      service: mockService,
      remoteDataSource: mockRemote,
    );
  });

  group('requestPermission', () {
    test('returns Right(true) when service grants permission', () async {
      when(() => mockService.requestPermission())
          .thenAnswer((_) async => true);

      final result = await sut.requestPermission();

      expect(result, const Right<Failure, bool>(true));
    });

    test('returns Right(false) when service denies permission', () async {
      when(() => mockService.requestPermission())
          .thenAnswer((_) async => false);

      final result = await sut.requestPermission();

      expect(result, const Right<Failure, bool>(false));
    });

    test('returns Left(PermissionFailure) when service throws', () async {
      when(() => mockService.requestPermission()).thenThrow(Exception('denied'));

      final result = await sut.requestPermission();

      expect(result.isLeft(), isTrue);
      expect(
        result.fold((l) => l, (_) => null),
        isA<PermissionFailure>(),
      );
    });
  });

  group('registerToken', () {
    test('returns Right when saveToken succeeds', () async {
      when(
        () => mockRemote.saveToken(userId: tUserId, token: tToken),
      ).thenAnswer((_) async {});

      final result =
          await sut.registerToken(userId: tUserId, token: tToken);

      expect(result, const Right<Failure, void>(null));
      verify(
        () => mockRemote.saveToken(userId: tUserId, token: tToken),
      ).called(1);
    });

    test('returns Left(ServerFailure) when saveToken throws ServerException',
        () async {
      when(
        () => mockRemote.saveToken(userId: tUserId, token: tToken),
      ).thenThrow(const ServerException(message: 'DB error'));

      final result =
          await sut.registerToken(userId: tUserId, token: tToken);

      expect(result.isLeft(), isTrue);
      expect(
        result.fold((l) => l, (_) => null),
        isA<ServerFailure>(),
      );
    });

    test('returns Left(ServerFailure) when saveToken throws generic exception',
        () async {
      when(
        () => mockRemote.saveToken(userId: tUserId, token: tToken),
      ).thenThrow(Exception('network error'));

      final result =
          await sut.registerToken(userId: tUserId, token: tToken);

      expect(result.isLeft(), isTrue);
    });
  });

  group('stream delegation', () {
    test('onTokenRefresh delegates to service', () {
      final controller = StreamController<String>.broadcast();
      when(() => mockService.onTokenRefresh).thenAnswer((_) => controller.stream);

      expect(sut.onTokenRefresh, emitsInOrder(<String>['new-token']));
      controller.add('new-token');
      controller.close();
    });

    test('onForegroundMessage delegates to service', () {
      final controller = StreamController<RemoteMessage>.broadcast();
      when(() => mockService.onForegroundMessage)
          .thenAnswer((_) => controller.stream);

      const message = RemoteMessage();
      expect(sut.onForegroundMessage, emitsInOrder(<RemoteMessage>[message]));
      controller.add(message);
      controller.close();
    });

    test('getInitialMessage delegates to service', () async {
      when(() => mockService.getInitialMessage()).thenAnswer((_) async => null);

      final result = await sut.getInitialMessage();

      expect(result, isNull);
      verify(() => mockService.getInitialMessage()).called(1);
    });
  });
}
