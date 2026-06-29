import 'package:local_auth/local_auth.dart';

abstract interface class BiometricDataSource {
  Future<bool> isAvailable();
  Future<bool> authenticate(String localizedReason);
}

class BiometricDataSourceImpl implements BiometricDataSource {
  const BiometricDataSourceImpl(this._localAuth);
  final LocalAuthentication _localAuth;

  @override
  Future<bool> isAvailable() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return false;
      return _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String localizedReason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
