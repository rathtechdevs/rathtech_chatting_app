// Holds the public key material needed to establish a Signal Protocol session.
// Transmitted from the server; private keys never leave the device.
class KeyBundle {
  const KeyBundle({
    required this.userId,
    required this.identityKey,
    required this.signedPreKey,
    required this.signedPreKeySignature,
    required this.signedPreKeyId,
    this.oneTimePreKey,
    this.oneTimePreKeyId,
  });

  final String userId;
  final String identityKey;         // Base64-encoded Curve25519 public key
  final String signedPreKey;        // Base64-encoded Curve25519 public key
  final String signedPreKeySignature; // Base64-encoded Ed25519 signature
  final int signedPreKeyId;
  final String? oneTimePreKey;      // Base64-encoded, nullable (may be exhausted)
  final int? oneTimePreKeyId;

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'identity_key': identityKey,
        'signed_prekey': signedPreKey,
        'signed_prekey_signature': signedPreKeySignature,
        'signed_prekey_id': signedPreKeyId,
        if (oneTimePreKey != null) 'one_time_prekey': oneTimePreKey,
        if (oneTimePreKeyId != null) 'one_time_prekey_id': oneTimePreKeyId,
      };

  factory KeyBundle.fromJson(Map<String, dynamic> json) => KeyBundle(
        userId: json['user_id'] as String,
        identityKey: json['identity_key'] as String,
        signedPreKey: json['signed_prekey'] as String,
        signedPreKeySignature: json['signed_prekey_signature'] as String,
        signedPreKeyId: json['signed_prekey_id'] as int,
        oneTimePreKey: json['one_time_prekey'] as String?,
        oneTimePreKeyId: json['one_time_prekey_id'] as int?,
      );
}
