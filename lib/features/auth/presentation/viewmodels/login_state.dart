import '../../domain/value_objects/phone_number.dart';

sealed class LoginState {
  const LoginState();
}

final class LoginInitial extends LoginState {
  const LoginInitial();
}

final class LoginLoading extends LoginState {
  const LoginLoading();
}

final class LoginOtpSent extends LoginState {
  const LoginOtpSent(this.phone);

  final PhoneNumber phone;
}

final class LoginMagicLinkSent extends LoginState {
  const LoginMagicLinkSent();
}

final class LoginError extends LoginState {
  const LoginError(this.message);

  final String message;
}
