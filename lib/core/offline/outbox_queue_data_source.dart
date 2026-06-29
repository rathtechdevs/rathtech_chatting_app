import 'package:drift/drift.dart';

import '../logger/app_logger.dart';
import '../storage/app_database.dart';

abstract interface class OutboxQueueDataSource {
  Future<void> enqueue(OutboxQueueCompanion companion);

  /// Returns items with status='pending' whose nextRetryAt is <= [now].
  Future<List<OutboxQueueData>> getPendingDue(DateTime now);

  Future<void> updateRetry({
    required String id,
    required int newAttemptCount,
    required DateTime nextRetryAt,
  });

  Future<void> markFailed(String id);

  Future<void> remove(String id);

  Stream<int> watchPendingCount(String pairId);
}

class OutboxQueueDataSourceImpl implements OutboxQueueDataSource {
  const OutboxQueueDataSourceImpl(this._db);

  final AppDatabase _db;

  @override
  Future<void> enqueue(OutboxQueueCompanion companion) async {
    try {
      await _db.into(_db.outboxQueue).insertOnConflictUpdate(companion);
    } catch (e, s) {
      AppLogger.error('OutboxQueue.enqueue failed', e, s);
      rethrow;
    }
  }

  @override
  Future<List<OutboxQueueData>> getPendingDue(DateTime now) {
    return (_db.select(_db.outboxQueue)
          ..where(
            ($OutboxQueueTable q) =>
                q.status.equals('pending') &
                q.nextRetryAt.isSmallerOrEqualValue(now),
          )
          ..orderBy([
            ($OutboxQueueTable q) =>
                OrderingTerm(expression: q.createdAt),
          ]))
        .get();
  }

  @override
  Future<void> updateRetry({
    required String id,
    required int newAttemptCount,
    required DateTime nextRetryAt,
  }) async {
    try {
      await (_db.update(_db.outboxQueue)
            ..where(($OutboxQueueTable q) => q.id.equals(id)))
          .write(OutboxQueueCompanion(
        attemptCount: Value(newAttemptCount),
        nextRetryAt: Value(nextRetryAt),
      ));
    } catch (e, s) {
      AppLogger.error('OutboxQueue.updateRetry failed for $id', e, s);
    }
  }

  @override
  Future<void> markFailed(String id) async {
    try {
      await (_db.update(_db.outboxQueue)
            ..where(($OutboxQueueTable q) => q.id.equals(id)))
          .write(const OutboxQueueCompanion(status: Value('failed')));
    } catch (e, s) {
      AppLogger.error('OutboxQueue.markFailed failed for $id', e, s);
    }
  }

  @override
  Future<void> remove(String id) async {
    try {
      await (_db.delete(_db.outboxQueue)
            ..where(($OutboxQueueTable q) => q.id.equals(id)))
          .go();
    } catch (e, s) {
      AppLogger.error('OutboxQueue.remove failed for $id', e, s);
    }
  }

  @override
  Stream<int> watchPendingCount(String pairId) {
    return (_db.select(_db.outboxQueue)
          ..where(
            ($OutboxQueueTable q) =>
                q.pairId.equals(pairId) & q.status.equals('pending'),
          ))
        .watch()
        .map((rows) => rows.length);
  }
}
