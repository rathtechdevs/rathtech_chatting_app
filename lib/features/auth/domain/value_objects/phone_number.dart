import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';

class PhoneNumber {
  const PhoneNumber._(this.value);

  final String value;

  static Either<Failure, PhoneNumber> create(String input) {
    final normalized = input.trim().replaceAll(' ', '').replaceAll('-', '');
    final regex = RegExp(r'^\+[1-9]\d{7,14}$');
    if (!regex.hasMatch(normalized)) {
      return const Left(
        ValidationFailure(
          'Please enter a valid phone number in international format (e.g. +1 555 000 0000).',
        ),
      );
    }
    return Right(PhoneNumber._(normalized));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PhoneNumber && other.value == value);

  @override
  int get hashCode => value.hashCode;
}
