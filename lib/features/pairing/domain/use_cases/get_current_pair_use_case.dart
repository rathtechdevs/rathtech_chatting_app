import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_case/use_case.dart';
import '../entities/pair.dart';
import '../repositories/pairing_repository.dart';

class GetCurrentPairUseCase implements UseCaseNoParams<Pair?> {
  const GetCurrentPairUseCase(this._repository);

  final PairingRepository _repository;

  @override
  Future<Either<Failure, Pair?>> execute() => _repository.getCurrentPair();
}
