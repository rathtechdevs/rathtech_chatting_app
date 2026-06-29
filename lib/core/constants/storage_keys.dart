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
  static const pinSalt = 'app_lock_pin_salt';
  static const lockType = 'app_lock_type';
  static const lockTimeoutMinutes = 'app_lock_timeout_minutes';
  static const lockBackgroundTs = 'app_lock_background_ts';

  // ── Settings ───────────────────────────────────────────────────────────────
  static const settingsThemeMode = 'settings_theme_mode';
  static const settingsMuteNotifications = 'settings_mute_notifications';
  static const settingsShowNotificationPreview =
      'settings_show_notification_preview';
  static const settingsReadReceipts = 'settings_read_receipts';
  static const settingsTypingIndicator = 'settings_typing_indicator';
  static const settingsDisappearingMessageHours =
      'settings_disappearing_message_hours';

  // ── Pairing ────────────────────────────────────────────────────────────────
  static const currentPairId = 'current_pair_id';
  static const partnerId = 'partner_id';
}
