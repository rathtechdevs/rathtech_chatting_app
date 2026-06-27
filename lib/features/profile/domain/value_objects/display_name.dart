import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';

class DisplayName {
  const DisplayName._(this.value);

  final String value;

  static const int _maxLength = 30;

  static Either<Failure, DisplayName> create(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const Left(ValidationFailure('Display name cannot be empty.'));
    }
    if (trimmed.length > _maxLength) {
      return const Left(
        ValidationFailure('Display name must be 30 characters or fewer.'),
      );
    }
    return Right(DisplayName._(trimmed));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DisplayName && other.value == value);

  @override
  int get hashCode => value.hashCode;
}
