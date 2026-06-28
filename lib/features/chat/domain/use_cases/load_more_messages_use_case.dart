import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

class LoadMoreMessagesUseCase {
  const LoadMoreMessagesUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, List<Message>>> execute(LoadMoreParams params) =>
      _repository.loadMoreMessages(params);
}
