import '../constants/app_strings.dart';
import 'failures.dart';

abstract final class FailureMessageMapper {
  static String toMessage(Failure failure) {
    return switch (failure) {
      final ServerFailure f => f.message,
      final AuthFailure f => f.message,
      final CacheFailure f => f.message,
      final EncryptionFailure f => f.message,
      final ValidationFailure f => f.message,
      final PermissionFailure f => f.message,
      final PairFailure f => f.message,
      UnknownFailure() => AppStrings.genericError,
    };
  }

  static bool isRetryable(Failure failure) {
    return switch (failure) {
      ServerFailure() => true,
      AuthFailure() => false,
      CacheFailure() => true,
      EncryptionFailure() => false,
      ValidationFailure() => false,
      PermissionFailure() => false,
      PairFailure() => false,
      UnknownFailure() => true,
    };
  }

  static bool requiresLogout(Failure failure) {
    return switch (failure) {
      AuthFailure() => true,
      _ => false,
    };
  }
}
