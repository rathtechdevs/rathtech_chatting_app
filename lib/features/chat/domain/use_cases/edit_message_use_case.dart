import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class EditMessageParams {
  const EditMessageParams({
    required this.messageId,
    required this.pairId,
    required this.newText,
    required this.originalCreatedAt,
  });

  final String messageId;
  final String pairId;
  final String newText;
  final DateTime originalCreatedAt;
}

class EditMessageUseCase {
  const EditMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, Message>> execute(EditMessageParams params) {
    // Editing is only allowed within 15 minutes of the original send.
    final elapsed = DateTime.now().difference(params.originalCreatedAt);
    if (elapsed.inMinutes >= 15) {
      return Future.value(
        const Left(ValidationFailure('Messages can only be edited within 15 minutes of sending.')),
      );
    }
    return _repository.editMessage(params);
  }
}
