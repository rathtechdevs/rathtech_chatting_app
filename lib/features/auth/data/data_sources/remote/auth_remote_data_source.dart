import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/error/exceptions.dart' hide AuthException;
import '../../../../../core/logger/app_logger.dart';

abstract class AuthRemoteDataSource {
  User? get currentUser;

  Stream<AuthState> get onAuthStateChange;

  Future<void> requestPhoneOtp(String phone);

  Future<void> verifyPhoneOtp(String phone, String token);

  Future<void> requestEmailMagicLink(String email);

  Future<void> refreshSession();

  Future<void> signOut();

  Future<bool> hasProfile(String userId);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  @override
  Future<void> requestPhoneOtp(String phone) async {
    try {
      await _client.auth.signInWithOtp(phone: phone);
    } on AuthException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('requestPhoneOtp failed', e, stack);
      throw const ServerException(message: 'Failed to send OTP.');
    }
  }

  @override
  Future<void> verifyPhoneOtp(String phone, String token) async {
    try {
      await _client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
    } on AuthException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('verifyPhoneOtp failed', e, stack);
      throw const ServerException(message: 'Failed to verify OTP.');
    }
  }

  @override
  Future<void> requestEmailMagicLink(String email) async {
    try {
      await _client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.securechat://login-callback/',
      );
    } on AuthException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('requestEmailMagicLink failed', e, stack);
      throw const ServerException(message: 'Failed to send magic link.');
    }
  }

  @override
  Future<void> refreshSession() async {
    try {
      await _client.auth.refreshSession();
    } on AuthException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('refreshSession failed', e, stack);
      throw const ServerException(message: 'Failed to refresh session.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e, stack) {
      AppLogger.error('signOut failed', e, stack);
      throw const ServerException(message: 'Failed to sign out.');
    }
  }

  @override
  Future<bool> hasProfile(String userId) async {
    try {
      final result = await _client
          .from('user_profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      return result != null;
    } catch (e, stack) {
      AppLogger.error('hasProfile check failed', e, stack);
      return false;
    }
  }
}
