import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_case/use_case.dart';
import '../entities/pair.dart';
import '../repositories/pairing_repository.dart';

class WatchPairStatusUseCase implements StreamUseCase<Pair?, NoParams> {
  const WatchPairStatusUseCase(this._repository);

  final PairingRepository _repository;

  @override
  Stream<Either<Failure, Pair?>> execute(NoParams params) =>
      _repository.watchPairStatus();
}
