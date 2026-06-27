import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';
import 'models/encrypted_payload.dart';
import 'models/key_bundle.dart';

// Abstract interface for the Signal Protocol encryption service.
// Implemented in M2. All session state persisted after every ratchet step.
abstract class EncryptionService {
  Future<Either<Failure, void>> initializeSession({
    required String pairId,
    required KeyBundle partnerBundle,
  });

  Future<Either<Failure, EncryptedPayload>> encrypt({
    required String pairId,
    required String plaintext,
  });

  Future<Either<Failure, String>> decrypt({
    required String pairId,
    required EncryptedPayload payload,
  });

  Future<Either<Failure, ({Uint8List encryptedData, Uint8List key, Uint8List iv})>>
      encryptMedia(Uint8List data);

  Future<Either<Failure, Uint8List>> decryptMedia({
    required Uint8List encryptedData,
    required Uint8List key,
    required Uint8List iv,
  });

  bool hasSession(String pairId);
}
