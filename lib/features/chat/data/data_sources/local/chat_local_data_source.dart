import 'package:drift/drift.dart';

import '../../../../../core/logger/app_logger.dart';
import '../../../../../core/storage/app_database.dart';

abstract interface class ChatLocalDataSource {
  Future<void> upsertMessage(LocalMessagesCompanion companion);
  Future<void> updateStatus(String messageId, String status);
  Stream<List<LocalMessage>> watchMessages(String pairId, {int limit});
  Future<List<LocalMessage>> getMessagesBefore({
    required String pairId,
    required DateTime before,
    required int limit,
  });
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  const ChatLocalDataSourceImpl(this._db);

  final AppDatabase _db;

  @override
  Future<void> upsertMessage(LocalMessagesCompanion companion) async {
    try {
      await _db.into(_db.localMessages).insertOnConflictUpdate(companion);
    } catch (e, stack) {
      AppLogger.error('upsertMessage failed', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> updateStatus(String messageId, String status) async {
    try {
      await (_db.update(_db.localMessages)
            ..where(($LocalMessagesTable m) => m.id.equals(messageId)))
          .write(LocalMessagesCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ));
    } catch (e, stack) {
      AppLogger.error('updateStatus failed', e, stack);
      rethrow;
    }
  }

  @override
  Stream<List<LocalMessage>> watchMessages(String pairId, {int limit = 50}) {
    return (_db.select(_db.localMessages)
          ..where(
            ($LocalMessagesTable m) =>
                m.pairId.equals(pairId) & m.isDeleted.equals(false),
          )
          ..orderBy([
            ($LocalMessagesTable m) => OrderingTerm(
                  expression: m.createdAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(limit))
        .watch();
  }

  @override
  Future<List<LocalMessage>> getMessagesBefore({
    required String pairId,
    required DateTime before,
    required int limit,
  }) {
    return (_db.select(_db.localMessages)
          ..where(
            ($LocalMessagesTable m) =>
                m.pairId.equals(pairId) &
                m.createdAt.isSmallerThanValue(before) &
                m.isDeleted.equals(false),
          )
          ..orderBy([
            ($LocalMessagesTable m) => OrderingTerm(
                  expression: m.createdAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(limit))
        .get();
  }
}
