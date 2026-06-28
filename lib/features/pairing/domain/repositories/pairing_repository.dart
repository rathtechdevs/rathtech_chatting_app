import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/pair.dart';
import '../entities/pair_invite_code.dart';

abstract interface class PairingRepository {
  Future<Either<Failure, PairInviteCode>> generateInviteCode();
  Future<Either<Failure, Pair>> acceptInviteCode(String code);
  Future<Either<Failure, Pair?>> getCurrentPair();
  Stream<Either<Failure, Pair?>> watchPairStatus();
}
