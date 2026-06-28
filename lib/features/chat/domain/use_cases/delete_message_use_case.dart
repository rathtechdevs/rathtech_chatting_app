import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

class DeleteMessageUseCase {
  const DeleteMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, void>> execute(String messageId) =>
      _repository.deleteMessage(messageId);
}
