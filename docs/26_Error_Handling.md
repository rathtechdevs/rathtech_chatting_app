# 26 — Error Handling

## Purpose
Define the complete error handling strategy — failure types, Either pattern usage, UI presentation, logging, and recovery flows.

---

## 1. Error Handling Principles

1. **Failures, not exceptions** — Domain and presentation layers work with `Either<Failure, T>`; exceptions are internal to the data layer
2. **No silent failures** — Every error path produces a specific `Failure` type
3. **User-appropriate messages** — Domain failures map to human-readable messages; no stack traces in UI
4. **Recovery paths** — Every error shown to the user has an action (retry, go back, contact support)
5. **Logging** — All errors logged with context in debug mode; sanitized in production

---

## 2. Failure Hierarchy

```dart
// lib/core/error/failures.dart

sealed class Failure {
  final String message;
  const Failure(this.message);
}

// Server / network errors
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});

  const ServerFailure.noConnection()
      : statusCode = null,
        super('No internet connection. Please check your network.');

  const ServerFailure.timeout()
      : statusCode = null,
        super('Request timed out. Please try again.');

  const ServerFailure.server(String msg, {int? code})
      : statusCode = code,
        super(msg);
}

// Authentication errors
class AuthFailure extends Failure {
  const AuthFailure(super.message);

  const AuthFailure.unauthorized()
      : super('Your session has expired. Please log in again.');

  const AuthFailure.forbidden()
      : super('You do not have permission to perform this action.');

  const AuthFailure.invalidCredentials()
      : super('Invalid code. Please try again.');

  const AuthFailure.rateLimited()
      : super('Too many attempts. Please wait before trying again.');

  const AuthFailure.userNotFound()
      : super('No account found. Please register.');

  const AuthFailure.emailNotConfirmed()
      : super('Please confirm your email address.');
}

// Local database errors
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

// Signal Protocol / encryption errors
class EncryptionFailure extends Failure {
  const EncryptionFailure(super.message);

  const EncryptionFailure.sessionNotInitialized()
      : super('Encryption session not ready. Please try again.');

  const EncryptionFailure.decryptionFailed()
      : super('Could not decrypt message. The session may be out of sync.');
}

// Input validation errors
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

// Permission errors
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);

  const PermissionFailure.camera()
      : super('Camera permission is required to send photos.');

  const PermissionFailure.microphone()
      : super('Microphone permission is required to send voice messages.');

  const PermissionFailure.notifications()
      : super('Notification permission is required to receive messages when the app is closed.');
}

// Pair errors
class PairFailure extends Failure {
  const PairFailure(super.message);

  const PairFailure.invalidCode()
      : super('Invalid invite code. Please check and try again.');

  const PairFailure.expiredCode()
      : super('This invite code has expired. Ask your partner to generate a new one.');

  const PairFailure.ownCode()
      : super('You cannot connect with yourself.');

  const PairFailure.alreadyPaired()
      : super('This code has already been used.');
}

// Unknown / unexpected errors
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
  const UnknownFailure.unexpected()
      : super('An unexpected error occurred. Please try again.');
}
```

---

## 3. Exception Types (Data Layer Only)

```dart
// lib/core/error/exceptions.dart
// These are thrown inside data sources only — never reach domain or presentation

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

class EncryptionException implements Exception {
  final String message;
  const EncryptionException(this.message);
}

class UnknownMessageTypeException implements Exception {
  final String type;
  const UnknownMessageTypeException(this.type);
}
```

---

## 4. Error Conversion (Data → Domain)

```dart
// Standard try-catch pattern in every repository method
Future<Either<Failure, T>> _wrap<T>(Future<T> Function() fn) async {
  try {
    return Right(await fn());
  } on PostgrestException catch (e) {
    return Left(_mapPostgrestError(e));
  } on AuthException catch (e) {
    return Left(AuthFailure(e.message));
  } on StorageException catch (e) {
    return Left(ServerFailure(e.message));
  } on SocketException {
    return Left(const ServerFailure.noConnection());
  } on TimeoutException {
    return Left(const ServerFailure.timeout());
  } on EncryptionException catch (e) {
    return Left(EncryptionFailure(e.message));
  } on DriftException catch (e) {
    return Left(CacheFailure(e.toString()));
  } catch (e, stack) {
    AppLogger.error('Unexpected repository error', e, stack);
    return const Left(UnknownFailure.unexpected());
  }
}

Failure _mapPostgrestError(PostgrestException e) {
  return switch (e.statusCode) {
    '401' => const AuthFailure.unauthorized(),
    '403' => const AuthFailure.forbidden(),
    '404' => const ServerFailure('Resource not found.'),
    '429' => const AuthFailure.rateLimited(),
    _ => ServerFailure(e.message, statusCode: int.tryParse(e.statusCode ?? '')),
  };
}
```

---

## 5. UI Error Presentation

### 5.1 Failure to User Message Mapping

```dart
// lib/core/error/failure_message_mapper.dart
abstract class FailureMessageMapper {
  static String toMessage(Failure failure) {
    return switch (failure) {
      ServerFailure f => f.message,
      AuthFailure f => f.message,
      CacheFailure _ => 'Local storage error. Please restart the app.',
      EncryptionFailure f => f.message,
      ValidationFailure f => f.message,
      PermissionFailure f => f.message,
      PairFailure f => f.message,
      UnknownFailure _ => 'An unexpected error occurred. Please try again.',
    };
  }

  static bool isRetryable(Failure failure) {
    return switch (failure) {
      ServerFailure f => f.statusCode == null || f.statusCode! >= 500,
      CacheFailure _ => true,
      EncryptionFailure _ => false,  // Don't retry encryption errors silently
      _ => false,
    };
  }

  static bool requiresLogout(Failure failure) {
    return failure is AuthFailure &&
        (failure == const AuthFailure.unauthorized() ||
         failure == const AuthFailure.forbidden());
  }
}
```

### 5.2 Error Display in ViewModels

```dart
// In ViewModel
result.fold(
  (failure) {
    state = AsyncError(failure, StackTrace.current);

    // Auto-logout on auth failures
    if (FailureMessageMapper.requiresLogout(failure)) {
      ref.read(logoutUseCaseProvider).execute();
    }
  },
  (data) => state = AsyncData(newState),
);
```

### 5.3 Error Display in Screens

```dart
// Pattern 1: Listen for errors and show SnackBar
ref.listen(chatViewModelProvider(pairId), (_, next) {
  next.whenOrNull(
    error: (error, _) {
      if (error is Failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(FailureMessageMapper.toMessage(error)),
            action: FailureMessageMapper.isRetryable(error)
                ? SnackBarAction(
                    label: AppStrings.retry,
                    onPressed: () => _retryLastAction(),
                  )
                : null,
          ),
        );
      }
    },
  );
});

// Pattern 2: Inline error state in widget tree
Consumer(builder: (context, ref, _) {
  final state = ref.watch(profileViewModelProvider);
  return state.when(
    loading: () => const LoadingShimmer(),
    error: (error, _) => ErrorView(
      failure: error as Failure,
      onRetry: () => ref.invalidate(profileViewModelProvider),
    ),
    data: (profile) => ProfileContent(profile: profile),
  );
}),
```

---

## 6. ErrorView Widget

```dart
class ErrorView extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.failure, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(
              FailureMessageMapper.toMessage(failure),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text(AppStrings.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## 7. Logging

```dart
// lib/core/logger/app_logger.dart
abstract class AppLogger {
  static void debug(String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message${error != null ? '\nError: $error' : ''}');
      if (stack != null) debugPrintStack(stackTrace: stack);
    }
  }

  static void info(String message) {
    if (kDebugMode) debugPrint('[INFO] $message');
  }

  static void warning(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[WARN] $message${error != null ? '\nError: $error' : ''}');
    }
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message${error != null ? '\nError: $error' : ''}');
      if (stack != null) debugPrintStack(stackTrace: stack);
    }
    // In production: send to crash reporting service (Crashlytics, Sentry, etc.)
    // IMPORTANT: never log message content, user data, or keys
  }
}
```

**Logging rules:**
- Never log message content (encrypted or decrypted)
- Never log authentication tokens
- Never log private key material
- Log error types, codes, and flow context only

---

## 8. Global Error Handling

Unhandled Flutter errors (widget build errors, frame callback errors):

```dart
// In main.dart
FlutterError.onError = (FlutterErrorDetails details) {
  AppLogger.error(
    'Flutter error: ${details.exceptionAsString()}',
    details.exception,
    details.stack,
  );
};

PlatformDispatcher.instance.onError = (error, stack) {
  AppLogger.error('Platform error', error, stack);
  return true; // Handled
};
```

---

## 9. Error Recovery Checklist

For each error type, ensure:

| Failure | UI Response | Recovery Action |
|---|---|---|
| `ServerFailure.noConnection` | Inline offline banner | Auto-retry on reconnect |
| `ServerFailure.timeout` | SnackBar with retry | Retry button |
| `AuthFailure.unauthorized` | Navigate to login | Automatic logout |
| `AuthFailure.rateLimited` | SnackBar with countdown | Wait + retry |
| `ValidationFailure` | Inline field error | User corrects input |
| `EncryptionFailure.sessionNotInitialized` | SnackBar | Re-initialize session |
| `EncryptionFailure.decryptionFailed` | Show "[Unreadable message]" | Contact support |
| `PermissionFailure.camera` | Alert dialog with settings link | Open app settings |
| `PairFailure.invalidCode` | Inline field error | User re-enters code |
| `CacheFailure` | SnackBar | Restart app |
| `UnknownFailure` | SnackBar with "Try again" | Retry or restart |
