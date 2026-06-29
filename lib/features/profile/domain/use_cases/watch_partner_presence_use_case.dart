import '../entities/user_presence.dart';
import '../repositories/profile_repository.dart';

class WatchPartnerPresenceUseCase {
  const WatchPartnerPresenceUseCase(this._repository);

  final ProfileRepository _repository;

  Stream<UserPresence?> execute(String partnerId) =>
      _repository.watchPartnerPresence(partnerId);
}
