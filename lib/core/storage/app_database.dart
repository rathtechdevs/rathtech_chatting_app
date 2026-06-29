import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// ── Tables ────────────────────────────────────────────────────────────────────

class OutboxQueue extends Table {
  TextColumn get id => text()();
  TextColumn get pairId => text()();
  BlobColumn get encryptedPayload => blob()();
  TextColumn get messageType => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attemptCount =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime()();
  // 'pending' | 'sending' | 'failed'
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalMessages extends Table {
  TextColumn get id => text()();
  TextColumn get pairId => text()();
  TextColumn get senderId => text()();
  // 'text' | 'image' | 'voice' | 'system'
  TextColumn get contentType => text()();
  TextColumn get decryptedText => text().nullable()();
  TextColumn get mediaLocalPath => text().nullable()();
  TextColumn get mediaStorageUrl => text().nullable()();
  // Maps to MessageStatus enum value
  TextColumn get status => text()();
  TextColumn get replyToId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
  // Unix timestamp ms, null = no disappearing
  IntColumn get disappearAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalReactions extends Table {
  TextColumn get id => text()();
  TextColumn get messageId => text()();
  TextColumn get userId => text()();
  TextColumn get emoji => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// ── Database ──────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [OutboxQueue, LocalMessages, LocalReactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openDatabase());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openDatabase() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'secure_chat.sqlite'));
      return NativeDatabase.createInBackground(
        file,
        setup: (db) {
          db.execute('PRAGMA journal_mode=WAL');
          db.execute('PRAGMA cache_size=-4096');
          db.execute('PRAGMA foreign_keys=ON');
        },
      );
    });
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
