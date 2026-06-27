// Wraps the ciphertext produced by the Signal Protocol Double Ratchet.
// Stored as BYTEA in Supabase — the server never sees plaintext.
class EncryptedPayload {
  const EncryptedPayload({
    required this.ciphertext,
    required this.header,
    required this.messageIndex,
    required this.messageType,
  });

  final String ciphertext;   // Base64-encoded ciphertext
  final String header;       // Base64-encoded ratchet header (public key + index)
  final int messageIndex;
  // 'prekey' = first message (establishes session), 'signal' = subsequent
  final String messageType;

  Map<String, dynamic> toJson() => {
        'ciphertext': ciphertext,
        'header': header,
        'message_index': messageIndex,
        'message_type': messageType,
      };

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) =>
      EncryptedPayload(
        ciphertext: json['ciphertext'] as String,
        header: json['header'] as String,
        messageIndex: json['message_index'] as int,
        messageType: json['message_type'] as String,
      );
}
