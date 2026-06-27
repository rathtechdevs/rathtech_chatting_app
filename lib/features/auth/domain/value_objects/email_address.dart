import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';

class EmailAddress {
  const EmailAddress._(this.value);

  final String value;

  static Either<Failure, EmailAddress> create(String input) {
    final trimmed = input.trim().toLowerCase();
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(trimmed)) {
      return const Left(
        ValidationFailure('Please enter a valid email address.'),
      );
    }
    return Right(EmailAddress._(trimmed));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is EmailAddress && other.value == value);

  @override
  int get hashCode => value.hashCode;
}
