import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_case/use_case.dart';
import '../entities/pair_invite_code.dart';
import '../repositories/pairing_repository.dart';

class GenerateInviteCodeUseCase implements UseCaseNoParams<PairInviteCode> {
  const GenerateInviteCodeUseCase(this._repository);

  final PairingRepository _repository;

  @override
  Future<Either<Failure, PairInviteCode>> execute() =>
      _repository.generateInviteCode();
}
