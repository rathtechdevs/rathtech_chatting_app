import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';

abstract class UseCase<Output, Params> {
  Future<Either<Failure, Output>> execute(Params params);
}

abstract class UseCaseNoParams<Output> {
  Future<Either<Failure, Output>> execute();
}

abstract class StreamUseCase<Output, Params> {
  Stream<Either<Failure, Output>> execute(Params params);
}

class NoParams {
  const NoParams();
}
