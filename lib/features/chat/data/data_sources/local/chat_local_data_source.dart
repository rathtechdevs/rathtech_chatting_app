import 'package:drift/drift.dart';

import '../../../../../core/logger/app_logger.dart';
import '../../../../../core/storage/app_database.dart';

abstract interface class ChatLocalDataSource {
  Future<void> upsertMessage(LocalMessagesCompanion companion);
  Future<void> updateStatus(String messageId, String status);
  Future<void> updateDecryptedText(String messageId, String text);
  Stream<List<LocalMessage>> watchMessages(String pairId, {int limit});
  Future<List<LocalMessage>> getMessagesBefore({
    required String pairId,
    required DateTime before,
    required int limit,
  });

  /// Returns the most-recent message for [pairId], or null if none.
  Future<LocalMessage?> getLatestMessage(String pairId);

  /// Returns the message with [id], or null if not found.
  Future<LocalMessage?> getMessageById(String id);

  // Reactions
  Future<void> upsertReaction(LocalReactionsCompanion companion);
  Future<void> deleteReaction({
    required String messageId,
    required String userId,
  });
  Stream<List<LocalReaction>> watchReactions(String pairId);
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
  Future<void> updateDecryptedText(String messageId, String text) async {
    try {
      await (_db.update(_db.localMessages)
            ..where(($LocalMessagesTable m) => m.id.equals(messageId)))
          .write(LocalMessagesCompanion(
        decryptedText: Value(text),
        updatedAt: Value(DateTime.now()),
      ));
    } catch (e, stack) {
      AppLogger.error('updateDecryptedText failed', e, stack);
      rethrow;
    }
  }

  @override
  Stream<List<LocalMessage>> watchMessages(String pairId, {int limit = 50}) {
    return (_db.select(_db.localMessages)
          ..where(
            ($LocalMessagesTable m) => m.pairId.equals(pairId),
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
                m.createdAt.isSmallerThanValue(before),
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

  @override
  Future<LocalMessage?> getLatestMessage(String pairId) async {
    final rows = await (_db.select(_db.localMessages)
          ..where(($LocalMessagesTable m) => m.pairId.equals(pairId))
          ..orderBy([
            ($LocalMessagesTable m) => OrderingTerm(
                  expression: m.createdAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<LocalMessage?> getMessageById(String id) async {
    final rows = await (_db.select(_db.localMessages)
          ..where(($LocalMessagesTable m) => m.id.equals(id))
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<void> upsertReaction(LocalReactionsCompanion companion) async {
    try {
      await _db.into(_db.localReactions).insertOnConflictUpdate(companion);
    } catch (e, stack) {
      AppLogger.error('upsertReaction failed', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> deleteReaction({
    required String messageId,
    required String userId,
  }) async {
    try {
      await (_db.delete(_db.localReactions)
            ..where(
              ($LocalReactionsTable r) =>
                  r.messageId.equals(messageId) & r.userId.equals(userId),
            ))
          .go();
    } catch (e, stack) {
      AppLogger.error('deleteReaction failed', e, stack);
      rethrow;
    }
  }

  @override
  Stream<List<LocalReaction>> watchReactions(String pairId) {
    // Join local_reactions with local_messages to filter by pair_id.
    final query = _db.select(_db.localReactions).join([
      innerJoin(
        _db.localMessages,
        _db.localMessages.id.equalsExp(_db.localReactions.messageId),
      ),
    ])
      ..where(_db.localMessages.pairId.equals(pairId));

    return query.watch().map(
          (rows) => rows
              .map((r) => r.readTable(_db.localReactions))
              .toList(),
        );
  }
}
