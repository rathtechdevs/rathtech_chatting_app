import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

class ReactToMessageParams {
  const ReactToMessageParams({
    required this.messageId,
    required this.pairId,
    required this.emoji,
  });

  final String messageId;
  final String pairId;
  final String emoji;
}

class ReactToMessageUseCase {
  const ReactToMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, void>> execute(ReactToMessageParams params) =>
      _repository.reactToMessage(params);
}
