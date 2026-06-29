import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:rathtech_chatting_app/features/auth/domain/use_cases/request_magic_link_use_case.dart';
import 'package:rathtech_chatting_app/features/auth/domain/value_objects/email_address.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository mockRepo;
  late RequestMagicLinkUseCase sut;
  late EmailAddress validEmail;

  setUpAll(() {
    registerFallbackValue(
      (EmailAddress.create('fallback@example.com') as Right).value
          as EmailAddress,
    );
  });

  setUp(() {
    mockRepo = _MockAuthRepository();
    sut = RequestMagicLinkUseCase(mockRepo);
    validEmail =
        (EmailAddress.create('test@example.com') as Right).value as EmailAddress;
  });

  group('RequestMagicLinkUseCase', () {
    test('delegates to repository and returns Right(null) on success', () async {
      when(() => mockRepo.requestEmailMagicLink(any()))
          .thenAnswer((_) async => const Right(null));

      final result = await sut.execute(validEmail);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepo.requestEmailMagicLink(validEmail)).called(1);
    });

    test('returns Left(failure) when repository fails', () async {
      const failure = ServerFailure.noConnection();
      when(() => mockRepo.requestEmailMagicLink(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await sut.execute(validEmail);

      expect(result, const Left<Failure, void>(failure));
    });
  });
}
