import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';
import 'models/key_bundle.dart';

// Abstract interface for Signal Protocol key CRUD on flutter_secure_storage.
// Implemented in M2.
abstract class KeyStorageService {
  Future<Either<Failure, void>> saveIdentityKeyPair(Uint8List keyPairBytes);
  Future<Either<Failure, Uint8List>> getIdentityKeyPair();

  Future<Either<Failure, void>> saveSignedPreKey({
    required int id,
    required Uint8List keyPairBytes,
    required Uint8List signatureBytes,
  });

  Future<Either<Failure, KeyBundle>> getOwnPublicKeyBundle();

  Future<Either<Failure, void>> saveOneTimePreKeys(List<Uint8List> preKeyBytes);
  Future<Either<Failure, Uint8List?>> consumeOneTimePreKey();

  Future<Either<Failure, void>> saveSessionState(
    String pairId,
    Uint8List stateBytes,
  );
  Future<Either<Failure, Uint8List?>> getSessionState(String pairId);
  Future<Either<Failure, void>> deleteSession(String pairId);
}
