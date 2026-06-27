import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_case/use_case.dart';
import '../repositories/auth_repository.dart';
import '../value_objects/phone_number.dart';

class RequestOtpUseCase extends UseCase<void, PhoneNumber> {
  RequestOtpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> execute(PhoneNumber params) =>
      _repository.requestPhoneOtp(params);
}
