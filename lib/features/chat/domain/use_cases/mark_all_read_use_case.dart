import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

class MarkAllReadUseCase {
  const MarkAllReadUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, void>> execute(String pairId) =>
      _repository.markAllRead(pairId);
}
