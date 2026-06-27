import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rathtech_chatting_app/core/error/failures.dart';
import 'package:rathtech_chatting_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:rathtech_chatting_app/features/auth/domain/use_cases/verify_otp_use_case.dart';
import 'package:rathtech_chatting_app/features/auth/domain/value_objects/otp_code.dart';
import 'package:rathtech_chatting_app/features/auth/domain/value_objects/phone_number.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

PhoneNumber _phone(String raw) =>
    PhoneNumber.create(raw).fold((_) => throw Exception('bad test data'), (p) => p);

OtpCode _code(String raw) =>
    OtpCode.create(raw).fold((_) => throw Exception('bad test data'), (c) => c);

void main() {
  late MockAuthRepository mockRepo;
  late VerifyOtpUseCase useCase;
  late PhoneNumber validPhone;
  late OtpCode validCode;

  setUpAll(() {
    registerFallbackValue(_phone('+14155552671'));
    registerFallbackValue(_code('123456'));
  });

  setUp(() {
    mockRepo = MockAuthRepository();
    useCase = VerifyOtpUseCase(mockRepo);
    validPhone = _phone('+14155552671');
    validCode = _code('123456');
  });

  group('VerifyOtpUseCase', () {
    test('returns Right(void) when repository succeeds', () async {
      when(
        () => mockRepo.verifyPhoneOtp(any(), any()),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase.execute(
        VerifyOtpParams(phone: validPhone, code: validCode),
      );

      expect(result.isRight(), isTrue);
      verify(() => mockRepo.verifyPhoneOtp(validPhone, validCode)).called(1);
    });

    test('returns Left(AuthFailure) when OTP is invalid', () async {
      const failure = AuthFailure.otpInvalid();
      when(
        () => mockRepo.verifyPhoneOtp(any(), any()),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase.execute(
        VerifyOtpParams(phone: validPhone, code: validCode),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<AuthFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(AuthFailure) when OTP is expired', () async {
      const failure = AuthFailure.otpExpired();
      when(
        () => mockRepo.verifyPhoneOtp(any(), any()),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase.execute(
        VerifyOtpParams(phone: validPhone, code: validCode),
      );

      expect(result.isLeft(), isTrue);
    });

    test('returns Left(ServerFailure) when no connection', () async {
      const failure = ServerFailure.noConnection();
      when(
        () => mockRepo.verifyPhoneOtp(any(), any()),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase.execute(
        VerifyOtpParams(phone: validPhone, code: validCode),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
