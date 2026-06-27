import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_case/use_case.dart';
import '../repositories/auth_repository.dart';
import '../value_objects/otp_code.dart';
import '../value_objects/phone_number.dart';

class VerifyOtpParams {
  const VerifyOtpParams({required this.phone, required this.code});

  final PhoneNumber phone;
  final OtpCode code;
}

class VerifyOtpUseCase extends UseCase<void, VerifyOtpParams> {
  VerifyOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> execute(VerifyOtpParams params) =>
      _repository.verifyPhoneOtp(params.phone, params.code);
}
