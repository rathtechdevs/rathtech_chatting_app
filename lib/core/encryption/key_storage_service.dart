import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';
import 'models/key_bundle.dart';

typedef OtpRecord = ({int id, Uint8List privateKeyBytes});

// Abstract interface for Signal Protocol key CRUD on flutter_secure_storage.
abstract class KeyStorageService {
  // Identity key seed (32 bytes). X25519 + Ed25519 key pairs are derived from it.
  Future<Either<Failure, void>> saveIdentityKeyPair(Uint8List seedBytes);
  Future<Either<Failure, Uint8List>> getIdentityKeyPair();

  Future<Either<Failure, void>> saveSignedPreKey({
    required int id,
    required Uint8List privateKeyBytes,
    required Uint8List signatureBytes,
  });

  Future<Either<Failure, Uint8List>> getSignedPreKeyPrivateBytes(int id);

  // Reconstructs own public key bundle from stored material.
  Future<Either<Failure, KeyBundle>> getOwnPublicKeyBundle(String userId);

  Future<Either<Failure, void>> saveOneTimePreKeys(List<OtpRecord> preKeys);
  Future<Either<Failure, Uint8List?>> consumeOneTimePreKeyById(int id);

  Future<Either<Failure, void>> saveSessionState(
    String pairId,
    Uint8List stateBytes,
  );
  Future<Either<Failure, Uint8List?>> getSessionState(String pairId);
  Future<Either<Failure, void>> deleteSession(String pairId);
}
