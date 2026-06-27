import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure_message_mapper.dart';
import '../../domain/use_cases/verify_otp_use_case.dart';
import '../../domain/value_objects/otp_code.dart';
import '../../domain/value_objects/phone_number.dart';
import '../../providers.dart';
import 'otp_state.dart';

class OtpViewModel extends FamilyNotifier<OtpState, PhoneNumber> {
  @override
  OtpState build(PhoneNumber arg) => const OtpInitial();

  Future<void> verifyOtp(String rawCode) async {
    final codeResult = OtpCode.create(rawCode);

    await codeResult.fold(
      (failure) async =>
          state = OtpError(FailureMessageMapper.toMessage(failure)),
      (code) async {
        state = const OtpLoading();
        final result = await ref
            .read(verifyOtpUseCaseProvider)
            .execute(VerifyOtpParams(phone: arg, code: code));
        state = result.fold(
          (failure) => OtpError(FailureMessageMapper.toMessage(failure)),
          (_) => const OtpVerified(),
        );
      },
    );
  }

  Future<void> resendOtp() async {
    state = const OtpResending();
    final result = await ref
        .read(requestOtpUseCaseProvider)
        .execute(arg);
    state = result.fold(
      (failure) => OtpError(FailureMessageMapper.toMessage(failure)),
      (_) => const OtpInitial(),
    );
  }

  void reset() => state = const OtpInitial();
}

final otpViewModelProvider =
    NotifierProvider.family<OtpViewModel, OtpState, PhoneNumber>(
  OtpViewModel.new,
);
