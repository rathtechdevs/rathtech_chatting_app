import 'package:fpdart/fpdart.dart';

import '../../../../core/encryption/encryption_service.dart';
import '../../../../core/encryption/remote/key_bundle_remote_data_source.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logger/app_logger.dart';

class InitializePairSessionUseCase {
  const InitializePairSessionUseCase({
    required EncryptionService encryptionService,
    required KeyBundleRemoteDataSource keyBundleRemoteDataSource,
  })  : _encryption = encryptionService,
        _remote = keyBundleRemoteDataSource;

  final EncryptionService _encryption;
  final KeyBundleRemoteDataSource _remote;

  Future<Either<Failure, void>> execute({
    required String pairId,
    required String partnerUserId,
  }) async {
    try {
      final bundle = await _remote.fetchPartnerKeyBundle(partnerUserId);
      return _encryption.initializeSession(
        pairId: pairId,
        partnerBundle: bundle,
      );
    } on ServerException catch (e) {
      AppLogger.error('InitializePairSessionUseCase: fetchBundle failed', e);
      return Left(ServerFailure.server(e.message));
    } catch (e, stack) {
      AppLogger.error('InitializePairSessionUseCase failed', e, stack);
      return const Left(UnknownFailure());
    }
  }
}
