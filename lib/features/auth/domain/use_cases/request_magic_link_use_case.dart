import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/use_case/use_case.dart';
import '../repositories/auth_repository.dart';
import '../value_objects/email_address.dart';

class RequestMagicLinkUseCase extends UseCase<void, EmailAddress> {
  RequestMagicLinkUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, void>> execute(EmailAddress params) =>
      _repository.requestEmailMagicLink(params);
}
