import 'dart:convert';
import 'dart:typed_data';

// Serializable state for the Signal Protocol Double Ratchet algorithm.
// Persisted to flutter_secure_storage after every send/receive.
class DoubleRatchetState {
  const DoubleRatchetState({
    required this.dhKeyPairPrivate,
    required this.dhPublicKey,
    required this.remoteDhPublicKey,
    required this.rootKey,
    this.sendingChainKey,
    this.receivingChainKey,
    this.sendCount = 0,
    this.receiveCount = 0,
    this.previousChainCount = 0,
    this.skippedMessageKeys = const {},
  });

  final Uint8List dhKeyPairPrivate;  // Own DH ratchet private key (32 bytes)
  final Uint8List dhPublicKey;       // Own DH ratchet public key (32 bytes)
  final Uint8List remoteDhPublicKey; // Partner's last DH ratchet public key (32 bytes)
  final Uint8List rootKey;           // RK (32 bytes)
  final Uint8List? sendingChainKey;  // CKs (32 bytes), null before first send ratchet step
  final Uint8List? receivingChainKey; // CKr (32 bytes), null before first receive
  final int sendCount;               // NS
  final int receiveCount;            // NR
  final int previousChainCount;      // PN
  // Key: "<dhPublicKeyHex>:<messageIndex>", Value: message key (32 bytes)
  final Map<String, Uint8List> skippedMessageKeys;

  DoubleRatchetState copyWith({
    Uint8List? dhKeyPairPrivate,
    Uint8List? dhPublicKey,
    Uint8List? remoteDhPublicKey,
    Uint8List? rootKey,
    Uint8List? sendingChainKey,
    Uint8List? receivingChainKey,
    int? sendCount,
    int? receiveCount,
    int? previousChainCount,
    Map<String, Uint8List>? skippedMessageKeys,
  }) =>
      DoubleRatchetState(
        dhKeyPairPrivate: dhKeyPairPrivate ?? this.dhKeyPairPrivate,
        dhPublicKey: dhPublicKey ?? this.dhPublicKey,
        remoteDhPublicKey: remoteDhPublicKey ?? this.remoteDhPublicKey,
        rootKey: rootKey ?? this.rootKey,
        sendingChainKey: sendingChainKey ?? this.sendingChainKey,
        receivingChainKey: receivingChainKey ?? this.receivingChainKey,
        sendCount: sendCount ?? this.sendCount,
        receiveCount: receiveCount ?? this.receiveCount,
        previousChainCount: previousChainCount ?? this.previousChainCount,
        skippedMessageKeys: skippedMessageKeys ?? this.skippedMessageKeys,
      );

  Map<String, dynamic> toJson() => {
        'dhKeyPairPrivate': base64.encode(dhKeyPairPrivate),
        'dhPublicKey': base64.encode(dhPublicKey),
        'remoteDhPublicKey': base64.encode(remoteDhPublicKey),
        'rootKey': base64.encode(rootKey),
        if (sendingChainKey != null)
          'sendingChainKey': base64.encode(sendingChainKey!),
        if (receivingChainKey != null)
          'receivingChainKey': base64.encode(receivingChainKey!),
        'sendCount': sendCount,
        'receiveCount': receiveCount,
        'previousChainCount': previousChainCount,
        'skippedMessageKeys': skippedMessageKeys.map(
          (k, v) => MapEntry(k, base64.encode(v)),
        ),
      };

  factory DoubleRatchetState.fromJson(Map<String, dynamic> json) =>
      DoubleRatchetState(
        dhKeyPairPrivate:
            Uint8List.fromList(base64.decode(json['dhKeyPairPrivate'] as String)),
        dhPublicKey:
            Uint8List.fromList(base64.decode(json['dhPublicKey'] as String)),
        remoteDhPublicKey: Uint8List.fromList(
            base64.decode(json['remoteDhPublicKey'] as String)),
        rootKey:
            Uint8List.fromList(base64.decode(json['rootKey'] as String)),
        sendingChainKey: json['sendingChainKey'] != null
            ? Uint8List.fromList(
                base64.decode(json['sendingChainKey'] as String))
            : null,
        receivingChainKey: json['receivingChainKey'] != null
            ? Uint8List.fromList(
                base64.decode(json['receivingChainKey'] as String))
            : null,
        sendCount: json['sendCount'] as int,
        receiveCount: json['receiveCount'] as int,
        previousChainCount: json['previousChainCount'] as int,
        skippedMessageKeys:
            (json['skippedMessageKeys'] as Map<String, dynamic>).map(
          (k, v) =>
              MapEntry(k, Uint8List.fromList(base64.decode(v as String))),
        ),
      );

  Uint8List toBytes() => Uint8List.fromList(utf8.encode(jsonEncode(toJson())));

  factory DoubleRatchetState.fromBytes(Uint8List bytes) =>
      DoubleRatchetState.fromJson(
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
      );
}
