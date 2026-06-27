sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class ServerFailure extends Failure {
  const ServerFailure.noConnection() : super('No internet connection.');
  const ServerFailure.timeout() : super('Request timed out. Please try again.');
  const ServerFailure.server([super.message = 'A server error occurred.']);
  const ServerFailure.unknown() : super('An unexpected error occurred.');
}

final class AuthFailure extends Failure {
  const AuthFailure.unauthorized()
      : super('Your session has expired. Please log in again.');
  const AuthFailure.forbidden()
      : super('You do not have permission to perform this action.');
  const AuthFailure.invalidCredentials()
      : super('The credentials provided are invalid.');
  const AuthFailure.rateLimited()
      : super('Too many attempts. Please wait and try again.');
  const AuthFailure.userNotFound() : super('Account not found.');
  const AuthFailure.emailNotConfirmed()
      : super('Please confirm your email address first.');
  const AuthFailure.otpExpired()
      : super('The verification code has expired. Please request a new one.');
  const AuthFailure.otpInvalid()
      : super('The verification code is incorrect.');
  const AuthFailure.server([super.message = 'An authentication error occurred.']);
}

final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'A local storage error occurred.']);
}

final class EncryptionFailure extends Failure {
  const EncryptionFailure.sessionNotInitialized()
      : super('Encryption session not established. Please re-pair with your partner.');
  const EncryptionFailure.decryptionFailed()
      : super('Failed to decrypt message. The message may be corrupted.');
  const EncryptionFailure.keyGenerationFailed()
      : super('Failed to generate encryption keys.');
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class PermissionFailure extends Failure {
  const PermissionFailure.camera()
      : super('Camera permission is required to send photos.');
  const PermissionFailure.microphone()
      : super('Microphone permission is required to send voice messages.');
  const PermissionFailure.notifications()
      : super('Notification permission is required to receive messages.');
  const PermissionFailure.biometric()
      : super('Biometric authentication is not available on this device.');
}

final class PairFailure extends Failure {
  const PairFailure.invalidCode()
      : super('The invite code is invalid. Please check and try again.');
  const PairFailure.expiredCode()
      : super('This invite code has expired. Please request a new one.');
  const PairFailure.ownCode()
      : super('You cannot use your own invite code.');
  const PairFailure.alreadyPaired()
      : super('You are already paired with someone.');
  const PairFailure.notPaired() : super('You are not paired with anyone yet.');
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
