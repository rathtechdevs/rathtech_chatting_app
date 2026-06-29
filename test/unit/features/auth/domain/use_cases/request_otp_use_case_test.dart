import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:rathtech_chatting_app/features/auth/domain/use_cases/request_otp_use_case.dart';
import 'package:rathtech_chatting_app/features/auth/domain/value_objects/phone_number.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

PhoneNumber _phone(String raw) =>
    PhoneNumber.create(raw).fold((_) => throw Exception('bad test data'), (p) => p);

void main() {
  late _MockAuthRepository mockRepo;
  late RequestOtpUseCase sut;

  final tPhone = _phone('+14155552671');

  setUpAll(() => registerFallbackValue(tPhone));

  setUp(() {
    mockRepo = _MockAuthRepository();
    sut = RequestOtpUseCase(mockRepo);
  });

  group('RequestOtpUseCase', () {
    test('returns Right(null) when repository succeeds', () async {
      when(() => mockRepo.requestPhoneOtp(any()))
          .thenAnswer((_) async => const Right(null));

      final result = await sut.execute(tPhone);

      expect(result, const Right<Failure, void>(null));
      verify(() => mockRepo.requestPhoneOtp(tPhone)).called(1);
    });

    test('returns Left(AuthFailure) when OTP rate-limited', () async {
      const failure = AuthFailure.rateLimited();
      when(() => mockRepo.requestPhoneOtp(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await sut.execute(tPhone);

      expect(result, const Left<Failure, void>(failure));
    });
  });
}
