abstract final class StorageKeys {
  // ── Auth ───────────────────────────────────────────────────────────────────
  static const accessToken = 'auth_access_token';
  static const refreshToken = 'auth_refresh_token';
  static const userId = 'auth_user_id';

  // ── Signal Protocol ────────────────────────────────────────────────────────
  static const identityKeyPair = 'signal_identity_key_pair';
  static const signedPreKeyPair = 'signal_signed_prekey_pair';
  static const signedPreKeyId = 'signal_signed_prekey_id';
  static const signedPreKeySignature = 'signal_signed_prekey_signature';
  static const oneTimePreKeys = 'signal_one_time_prekeys';
  static const sessionStatePrefix = 'signal_session_'; // + pairId

  // ── App Lock ───────────────────────────────────────────────────────────────
  static const pinHash = 'app_lock_pin_hash';
  static const lockType = 'app_lock_type';
  static const lockTimeoutMinutes = 'app_lock_timeout_minutes';

  // ── Pairing ────────────────────────────────────────────────────────────────
  static const currentPairId = 'current_pair_id';
  static const partnerId = 'partner_id';
}
