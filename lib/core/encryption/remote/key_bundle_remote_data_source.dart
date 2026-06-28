import 'package:supabase_flutter/supabase_flutter.dart';

import '../../error/exceptions.dart';
import '../../logger/app_logger.dart';
import '../models/key_bundle.dart';

abstract class KeyBundleRemoteDataSource {
  Future<void> publishIdentityKey({
    required String userId,
    required String identityKey,
    required String identitySigningKey,
    required int registrationId,
  });

  Future<void> publishSignedPreKey({
    required String userId,
    required int preKeyId,
    required String publicKey,
    required String signature,
  });

  Future<void> publishOneTimePreKeys({
    required String userId,
    required List<({int id, String publicKey})> preKeys,
  });

  Future<KeyBundle> fetchPartnerKeyBundle(String partnerId);

  Future<void> markOneTimePreKeyConsumed({
    required String userId,
    required int preKeyId,
  });
}

class KeyBundleRemoteDataSourceImpl implements KeyBundleRemoteDataSource {
  const KeyBundleRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<void> publishIdentityKey({
    required String userId,
    required String identityKey,
    required String identitySigningKey,
    required int registrationId,
  }) async {
    try {
      await _client.from('user_identity_keys').upsert({
        'user_id': userId,
        'identity_key': identityKey,
        'identity_signing_key': identitySigningKey,
        'registration_id': registrationId,
      });
    } on PostgrestException catch (e) {
      AppLogger.error('publishIdentityKey failed', e);
      throw ServerException(message: e.message, statusCode: int.tryParse(e.code ?? ''));
    }
  }

  @override
  Future<void> publishSignedPreKey({
    required String userId,
    required int preKeyId,
    required String publicKey,
    required String signature,
  }) async {
    try {
      await _client.from('user_prekey_bundles').upsert({
        'user_id': userId,
        'prekey_type': 'signed',
        'prekey_id': preKeyId,
        'public_key': publicKey,
        'signature': signature,
        'is_consumed': false,
      });
    } on PostgrestException catch (e) {
      AppLogger.error('publishSignedPreKey failed', e);
      throw ServerException(message: e.message, statusCode: int.tryParse(e.code ?? ''));
    }
  }

  @override
  Future<void> publishOneTimePreKeys({
    required String userId,
    required List<({int id, String publicKey})> preKeys,
  }) async {
    try {
      final rows = preKeys
          .map((pk) => {
                'user_id': userId,
                'prekey_type': 'one_time',
                'prekey_id': pk.id,
                'public_key': pk.publicKey,
                'is_consumed': false,
              })
          .toList();
      await _client.from('user_prekey_bundles').upsert(rows);
    } on PostgrestException catch (e) {
      AppLogger.error('publishOneTimePreKeys failed', e);
      throw ServerException(message: e.message, statusCode: int.tryParse(e.code ?? ''));
    }
  }

  @override
  Future<KeyBundle> fetchPartnerKeyBundle(String partnerId) async {
    try {
      final identityRow = await _client
          .from('user_identity_keys')
          .select()
          .eq('user_id', partnerId)
          .single();

      final spkRow = await _client
          .from('user_prekey_bundles')
          .select()
          .eq('user_id', partnerId)
          .eq('prekey_type', 'signed')
          .eq('is_consumed', false)
          .order('prekey_id', ascending: false)
          .limit(1)
          .single();

      // Fetch one unconsumed OPK; null-safe (may be exhausted)
      final otpRows = await _client
          .from('user_prekey_bundles')
          .select()
          .eq('user_id', partnerId)
          .eq('prekey_type', 'one_time')
          .eq('is_consumed', false)
          .limit(1);

      final otp = otpRows.isNotEmpty ? otpRows.first : null;

      return KeyBundle(
        userId: partnerId,
        identityKey: identityRow['identity_key'] as String,
        identitySigningKey: identityRow['identity_signing_key'] as String,
        signedPreKey: spkRow['public_key'] as String,
        signedPreKeySignature: spkRow['signature'] as String,
        signedPreKeyId: spkRow['prekey_id'] as int,
        oneTimePreKey: otp?['public_key'] as String?,
        oneTimePreKeyId: otp?['prekey_id'] as int?,
      );
    } on PostgrestException catch (e) {
      AppLogger.error('fetchPartnerKeyBundle failed', e);
      throw ServerException(message: e.message, statusCode: int.tryParse(e.code ?? ''));
    }
  }

  @override
  Future<void> markOneTimePreKeyConsumed({
    required String userId,
    required int preKeyId,
  }) async {
    try {
      await _client
          .from('user_prekey_bundles')
          .update({'is_consumed': true})
          .eq('user_id', userId)
          .eq('prekey_type', 'one_time')
          .eq('prekey_id', preKeyId);
    } on PostgrestException catch (e) {
      AppLogger.error('markOneTimePreKeyConsumed failed', e);
      throw ServerException(message: e.message, statusCode: int.tryParse(e.code ?? ''));
    }
  }
}
