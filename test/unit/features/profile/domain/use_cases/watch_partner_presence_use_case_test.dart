import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/features/profile/domain/entities/user_presence.dart';
import 'package:rathtech_chatting_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:rathtech_chatting_app/features/profile/domain/use_cases/watch_partner_presence_use_case.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _MockProfileRepository mockRepo;
  late WatchPartnerPresenceUseCase sut;

  const tPartnerId = 'partner-uid';

  setUp(() {
    mockRepo = _MockProfileRepository();
    sut = WatchPartnerPresenceUseCase(mockRepo);
  });

  group('WatchPartnerPresenceUseCase', () {
    test('emits UserPresence events from repository', () async {
      final presence = UserPresence(
        userId: tPartnerId,
        isOnline: true,
        lastSeenAt: DateTime(2024),
      );
      final ctrl = StreamController<UserPresence?>();
      when(() => mockRepo.watchPartnerPresence(any()))
          .thenAnswer((_) => ctrl.stream);

      final stream = sut.execute(tPartnerId);
      final future = stream.first;
      ctrl.add(presence);

      final result = await future;
      expect(result?.userId, tPartnerId);
      expect(result?.isOnline, isTrue);
      await ctrl.close();
    });

    test('emits null when partner goes offline', () async {
      final ctrl = StreamController<UserPresence?>();
      when(() => mockRepo.watchPartnerPresence(any()))
          .thenAnswer((_) => ctrl.stream);

      final stream = sut.execute(tPartnerId);
      final future = stream.first;
      ctrl.add(null);

      final result = await future;
      expect(result, isNull);
      await ctrl.close();
    });
  });
}
