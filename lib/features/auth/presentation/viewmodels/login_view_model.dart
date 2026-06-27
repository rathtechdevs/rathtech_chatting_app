import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_message_mapper.dart';
import '../../domain/value_objects/email_address.dart';
import '../../domain/value_objects/phone_number.dart';
import '../../providers.dart';
import 'login_state.dart';

class LoginViewModel extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginInitial();

  Future<void> requestPhoneOtp(String rawPhone) async {
    final phoneResult = PhoneNumber.create(rawPhone);

    phoneResult.fold(
      (failure) => state = LoginError(FailureMessageMapper.toMessage(failure)),
      (phone) async {
        state = const LoginLoading();
        final result = await ref
            .read(requestOtpUseCaseProvider)
            .execute(phone);
        state = result.fold(
          (failure) => LoginError(FailureMessageMapper.toMessage(failure)),
          (_) => LoginOtpSent(phone),
        );
      },
    );
  }

  Future<void> requestMagicLink(String rawEmail) async {
    final emailResult = EmailAddress.create(rawEmail);

    emailResult.fold(
      (failure) => state = LoginError(FailureMessageMapper.toMessage(failure)),
      (email) async {
        state = const LoginLoading();
        final result = await ref
            .read(requestMagicLinkUseCaseProvider)
            .execute(email);
        state = result.fold(
          (failure) => LoginError(FailureMessageMapper.toMessage(failure)),
          (_) => const LoginMagicLinkSent(),
        );
      },
    );
  }

  void reset() => state = const LoginInitial();
}

final loginViewModelProvider =
    NotifierProvider<LoginViewModel, LoginState>(LoginViewModel.new);
