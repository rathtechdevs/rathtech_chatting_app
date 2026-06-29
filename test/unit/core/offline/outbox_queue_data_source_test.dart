import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rathtech_chatting_app/core/offline/outbox_queue_data_source.dart';
import 'package:rathtech_chatting_app/core/storage/app_database.dart';

AppDatabase _openInMemory() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;
  late OutboxQueueDataSourceImpl sut;

  const tPairId = 'pair-1';
  const tId = 'msg-1';
  final tPayload = Uint8List.fromList([1, 2, 3, 4]);
  final tNow = DateTime(2024, 1, 1, 12);

  OutboxQueueCompanion buildCompanion({
    String id = tId,
    String pairId = tPairId,
    DateTime? nextRetryAt,
  }) =>
      OutboxQueueCompanion.insert(
        id: id,
        pairId: pairId,
        encryptedPayload: tPayload,
        messageType: 'text',
        createdAt: tNow,
        nextRetryAt: nextRetryAt ?? tNow,
      );

  setUp(() {
    db = _openInMemory();
    sut = OutboxQueueDataSourceImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('enqueue', () {
    test('inserts a new item with pending status', () async {
      await sut.enqueue(buildCompanion());

      final rows = await (db.select(db.outboxQueue)).get();
      expect(rows.length, 1);
      expect(rows.first.id, tId);
      expect(rows.first.status, 'pending');
      expect(rows.first.attemptCount, 0);
    });

    test('upserts on conflict without throwing', () async {
      await sut.enqueue(buildCompanion());
      // Second enqueue with same id should not throw.
      await expectLater(sut.enqueue(buildCompanion()), completes);
    });
  });

  group('getPendingDue', () {
    test('returns items whose nextRetryAt is <= now', () async {
      final future = tNow.add(const Duration(hours: 1));
      await sut.enqueue(buildCompanion(id: 'due', nextRetryAt: tNow));
      await sut.enqueue(buildCompanion(id: 'not-due', nextRetryAt: future));

      final result = await sut.getPendingDue(tNow);

      expect(result.length, 1);
      expect(result.first.id, 'due');
    });

    test('excludes failed items', () async {
      await sut.enqueue(buildCompanion());
      await sut.markFailed(tId);

      final result = await sut.getPendingDue(tNow);
      expect(result, isEmpty);
    });
  });

  group('updateRetry', () {
    test('updates attempt count and nextRetryAt', () async {
      await sut.enqueue(buildCompanion());
      final nextRetry = tNow.add(const Duration(seconds: 30));

      await sut.updateRetry(
        id: tId,
        newAttemptCount: 2,
        nextRetryAt: nextRetry,
      );

      final rows = await (db.select(db.outboxQueue)).get();
      expect(rows.first.attemptCount, 2);
      expect(rows.first.nextRetryAt, nextRetry);
    });
  });

  group('markFailed', () {
    test('sets status to failed', () async {
      await sut.enqueue(buildCompanion());
      await sut.markFailed(tId);

      final rows = await (db.select(db.outboxQueue)).get();
      expect(rows.first.status, 'failed');
    });
  });

  group('remove', () {
    test('deletes the item', () async {
      await sut.enqueue(buildCompanion());
      await sut.remove(tId);

      final rows = await (db.select(db.outboxQueue)).get();
      expect(rows, isEmpty);
    });
  });

  group('watchPendingCount', () {
    test('emits count of pending items for pairId', () async {
      await sut.enqueue(buildCompanion(id: 'a'));
      await sut.enqueue(buildCompanion(id: 'b'));
      await sut.enqueue(buildCompanion(id: 'c', pairId: 'other-pair'));

      final count = await sut.watchPendingCount(tPairId).first;
      expect(count, 2);
    });

    test('excludes failed items from count', () async {
      await sut.enqueue(buildCompanion());
      await sut.markFailed(tId);

      final count = await sut.watchPendingCount(tPairId).first;
      expect(count, 0);
    });
  });
}
