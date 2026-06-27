import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';

class OtpCode {
  const OtpCode._(this.value);

  final String value;

  static Either<Failure, OtpCode> create(String input) {
    final trimmed = input.trim();
    if (trimmed.length != 6 || !RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      return const Left(
        ValidationFailure('Please enter the 6-digit verification code.'),
      );
    }
    return Right(OtpCode._(trimmed));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is OtpCode && other.value == value);

  @override
  int get hashCode => value.hashCode;
}
