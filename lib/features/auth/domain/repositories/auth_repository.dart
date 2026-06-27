import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_session.dart';
import '../value_objects/email_address.dart';
import '../value_objects/otp_code.dart';
import '../value_objects/phone_number.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> requestPhoneOtp(PhoneNumber phone);

  Future<Either<Failure, void>> verifyPhoneOtp(
    PhoneNumber phone,
    OtpCode code,
  );

  Future<Either<Failure, void>> requestEmailMagicLink(EmailAddress email);

  Future<Either<Failure, void>> refreshSession();

  Future<Either<Failure, void>> logout();

  Stream<AppAuthState> watchAuthState();
}
