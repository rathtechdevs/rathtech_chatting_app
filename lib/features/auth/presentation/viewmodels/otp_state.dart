sealed class OtpState {
  const OtpState();
}

final class OtpInitial extends OtpState {
  const OtpInitial();
}

final class OtpLoading extends OtpState {
  const OtpLoading();
}

final class OtpVerified extends OtpState {
  const OtpVerified();
}

final class OtpResending extends OtpState {
  const OtpResending();
}

final class OtpError extends OtpState {
  const OtpError(this.message);

  final String message;
}
