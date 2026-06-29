abstract final class AppStrings {
  // ── App ───────────────────────────────────────────────────────────────────
  static const appName = 'SecureChat';
  static const appTagline = 'Private. Secure. Just the two of you.';

  // ── Common actions ────────────────────────────────────────────────────────
  static const ok = 'OK';
  static const cancel = 'Cancel';
  static const confirm = 'Confirm';
  static const delete = 'Delete';
  static const edit = 'Edit';
  static const save = 'Save';
  static const retry = 'Retry';
  static const back = 'Back';
  static const done = 'Done';
  static const next = 'Next';
  static const skip = 'Skip';
  static const continueLabel = 'Continue';
  static const close = 'Close';
  static const send = 'Send';
  static const copy = 'Copy';
  static const share = 'Share';
  static const loading = 'Loading…';

  // ── Errors ────────────────────────────────────────────────────────────────
  static const genericError = 'Something went wrong. Please try again.';
  static const noInternetError = 'No internet connection.';
  static const timeoutError = 'Request timed out. Please try again.';
  static const serverError = 'Server error. Please try again later.';
  static const sessionExpiredError = 'Your session has expired. Please log in again.';
  static const unexpectedError = 'An unexpected error occurred.';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const authWelcome = 'Welcome to SecureChat';
  static const authSubtitle = 'Encrypted messaging for two.';
  static const authTabPhone = 'Phone';
  static const authTabEmail = 'Email';
  static const authPhoneHint = 'Phone number (e.g. +1 555 000 0000)';
  static const authEmailHint = 'Email address';
  static const authGetOtp = 'Get verification code';
  static const authGetMagicLink = 'Send magic link';
  static const authOtpTitle = 'Enter verification code';
  static const authOtpSubtitle = 'We sent a 6-digit code to';
  static const authOtpHint = '000000';
  static const authVerify = 'Verify';
  static const authResendCode = 'Resend code';
  static const authResendIn = 'Resend in';
  static const authMagicLinkTitle = 'Check your email';
  static const authMagicLinkSubtitle =
      'We sent a sign-in link to your email. Tap the link to continue.';
  static const authMagicLinkOpenEmail = 'Open email app';
  static const authMagicLinkResend = 'Resend link';
  static const authAgeConfirmation =
      'By continuing, you confirm that you are 18 years of age or older.';

  // ── Profile setup ─────────────────────────────────────────────────────────
  static const profileSetupTitle = 'Set up your profile';
  static const profileSetupSubtitle = 'This is what your partner will see.';
  static const profileDisplayNameHint = 'Display name (1–30 characters)';
  static const profileAddPhoto = 'Add photo';
  static const profileChangePhoto = 'Change photo';
  static const profileSave = 'Save profile';

  // ── Pairing ───────────────────────────────────────────────────────────────
  static const pairTitle = 'Connect with your partner';
  static const pairSubtitle =
      'SecureChat is designed for exactly two people. Connect once.';
  static const pairGenerateButton = 'Generate invite code';
  static const pairEnterButton = 'Enter partner\'s code';
  static const generateInviteTitle = 'Your invite code';
  static const generateInviteSubtitle = 'Share this code with your partner.';
  static const generateInviteExpiry = 'Expires in 10 minutes';
  static const generateInviteCopied = 'Code copied!';
  static const enterInviteTitle = 'Enter invite code';
  static const enterInviteHint = 'Partner\'s 8-character code';
  static const enterInviteButton = 'Connect';
  static const pairSuccessTitle = 'You\'re connected!';
  static const pairSuccessSubtitle = 'End-to-end encrypted. Only you two can read these messages.';
  static const pairSuccessButton = 'Start chatting';

  // ── Chat ──────────────────────────────────────────────────────────────────
  static const chatInputHint = 'Message…';
  static const chatEmptyTitle = 'No messages yet';
  static const chatEmptySubtitle = 'Say hello to start your encrypted conversation.';
  static const chatTyping = 'typing…';
  static const chatOnline = 'Online';
  static const chatLastSeen = 'Last seen';
  static const chatMessageDeleted = 'Message deleted';
  static const chatMessageEdited = 'Edited';
  static const chatReactLabel = 'React';
  static const chatReplyLabel = 'Reply';
  static const chatEditLabel = 'Edit';
  static const chatDeleteLabel = 'Delete';
  static const chatCopyLabel = 'Copy text';
  static const chatDeleteConfirmTitle = 'Delete message?';
  static const chatDeleteConfirmBody =
      'This message will be deleted for both of you.';
  static const chatDeleteForEveryone = 'Delete for everyone';
  static const chatScrollToBottom = 'Scroll to bottom';
  static const chatDisappearingOn = 'Disappearing messages on';
  static const chatDisappearingOff = 'Disappearing messages off';
  static const chatSendImage = 'Photo';
  static const chatSendVoice = 'Voice';
  static const chatVoiceRecording = 'Recording…';
  static const chatVoiceRelease = 'Release to send';
  static const chatVoiceSlide = 'Slide to cancel';
  static const chatImageViewerTitle = 'Photo';
  static const chatSearchHint = 'Search messages…';
  static const chatSearchEmpty = 'No messages match your search.';

  // ── Profile ───────────────────────────────────────────────────────────────
  static const myProfileTitle = 'My profile';
  static const partnerProfileTitle = 'Partner\'s profile';
  static const profileEditButton = 'Edit profile';
  static const profileLogoutButton = 'Log out';
  static const profileLogoutConfirmTitle = 'Log out?';
  static const profileLogoutConfirmBody =
      'You will need to log in again to access your messages.';

  // ── Settings ──────────────────────────────────────────────────────────────
  static const settingsTitle = 'Settings';
  static const settingsNotifications = 'Notifications';
  static const settingsPrivacy = 'Privacy';
  static const settingsSecurity = 'Security';
  static const settingsChat = 'Chat';
  static const settingsAccount = 'Account';
  static const settingsTheme = 'Theme';
  static const settingsThemeSystem = 'System';
  static const settingsThemeLight = 'Light';
  static const settingsThemeDark = 'Dark';
  static const settingsChatBackground = 'Chat background';
  static const settingsDisappearingMessages = 'Disappearing messages';
  static const settingsOff = 'Off';
  static const settings24h = '24 hours';
  static const settings7d = '7 days';
  static const settings30d = '30 days';
  static const settingsMuteNotifications = 'Mute notifications';
  static const settingsShowNotificationPreview = 'Show notification preview';
  static const settingsReadReceipts = 'Read receipts';
  static const settingsTypingIndicator = 'Typing indicator';
  static const settingsDeleteAccount = 'Delete account';
  static const settingsDeleteAccountConfirmTitle = 'Delete account?';
  static const settingsDeleteAccountConfirmBody =
      'All your messages and data will be permanently deleted. This cannot be undone.';

  // ── App Lock ──────────────────────────────────────────────────────────────
  static const appLockTitle = 'App Lock';
  static const appLockSubtitle = 'Authenticate to continue';
  static const appLockUseBiometric = 'Use biometric';
  static const appLockUsePin = 'Use PIN instead';
  static const appLockEnterPin = 'Enter your PIN';
  static const appLockSetPin = 'Set a 6-digit PIN';
  static const appLockConfirmPin = 'Confirm your PIN';
  static const appLockPinMismatch = 'PINs do not match. Please try again.';
  static const appLockEnableBiometric = 'Enable biometric lock';
  static const appLockEnablePin = 'Enable PIN lock';
  static const appLockDisable = 'Disable app lock';
  static const appLockAutoLock = 'Auto-lock after';
  static const appLockImmediately = 'Immediately';
  static const appLockAfter1min = '1 minute';
  static const appLockAfter5min = '5 minutes';
  static const appLockAfter15min = '15 minutes';

  // ── Offline ───────────────────────────────────────────────────────────────
  static const offlineBannerLabel = 'You\'re offline — messages will send when online';

  static String offlineBannerWithQueue(int count) {
    final noun = count == 1 ? 'message' : 'messages';
    return 'You\'re offline · $count $noun queued';
  }

  // ── Permissions ───────────────────────────────────────────────────────────
  static const permissionDeniedCamera = 'Camera access denied. Enable it in Settings.';
  static const permissionDeniedMicrophone =
      'Microphone access denied. Enable it in Settings.';
  static const permissionOpenSettings = 'Open Settings';
}
