// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OutboxQueueTable extends OutboxQueue
    with TableInfo<$OutboxQueueTable, OutboxQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pairIdMeta = const VerificationMeta('pairId');
  @override
  late final GeneratedColumn<String> pairId = GeneratedColumn<String>(
    'pair_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedPayloadMeta = const VerificationMeta(
    'encryptedPayload',
  );
  @override
  late final GeneratedColumn<Uint8List> encryptedPayload =
      GeneratedColumn<Uint8List>(
        'encrypted_payload',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _messageTypeMeta = const VerificationMeta(
    'messageType',
  );
  @override
  late final GeneratedColumn<String> messageType = GeneratedColumn<String>(
    'message_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pairId,
    encryptedPayload,
    messageType,
    createdAt,
    attemptCount,
    nextRetryAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pair_id')) {
      context.handle(
        _pairIdMeta,
        pairId.isAcceptableOrUnknown(data['pair_id']!, _pairIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pairIdMeta);
    }
    if (data.containsKey('encrypted_payload')) {
      context.handle(
        _encryptedPayloadMeta,
        encryptedPayload.isAcceptableOrUnknown(
          data['encrypted_payload']!,
          _encryptedPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedPayloadMeta);
    }
    if (data.containsKey('message_type')) {
      context.handle(
        _messageTypeMeta,
        messageType.isAcceptableOrUnknown(
          data['message_type']!,
          _messageTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_messageTypeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextRetryAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pairId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pair_id'],
      )!,
      encryptedPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}encrypted_payload'],
      )!,
      messageType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $OutboxQueueTable createAlias(String alias) {
    return $OutboxQueueTable(attachedDatabase, alias);
  }
}

class OutboxQueueData extends DataClass implements Insertable<OutboxQueueData> {
  final String id;
  final String pairId;
  final Uint8List encryptedPayload;
  final String messageType;
  final DateTime createdAt;
  final int attemptCount;
  final DateTime nextRetryAt;
  final String status;
  const OutboxQueueData({
    required this.id,
    required this.pairId,
    required this.encryptedPayload,
    required this.messageType,
    required this.createdAt,
    required this.attemptCount,
    required this.nextRetryAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pair_id'] = Variable<String>(pairId);
    map['encrypted_payload'] = Variable<Uint8List>(encryptedPayload);
    map['message_type'] = Variable<String>(messageType);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempt_count'] = Variable<int>(attemptCount);
    map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    map['status'] = Variable<String>(status);
    return map;
  }

  OutboxQueueCompanion toCompanion(bool nullToAbsent) {
    return OutboxQueueCompanion(
      id: Value(id),
      pairId: Value(pairId),
      encryptedPayload: Value(encryptedPayload),
      messageType: Value(messageType),
      createdAt: Value(createdAt),
      attemptCount: Value(attemptCount),
      nextRetryAt: Value(nextRetryAt),
      status: Value(status),
    );
  }

  factory OutboxQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxQueueData(
      id: serializer.fromJson<String>(json['id']),
      pairId: serializer.fromJson<String>(json['pairId']),
      encryptedPayload: serializer.fromJson<Uint8List>(
        json['encryptedPayload'],
      ),
      messageType: serializer.fromJson<String>(json['messageType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      nextRetryAt: serializer.fromJson<DateTime>(json['nextRetryAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pairId': serializer.toJson<String>(pairId),
      'encryptedPayload': serializer.toJson<Uint8List>(encryptedPayload),
      'messageType': serializer.toJson<String>(messageType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'nextRetryAt': serializer.toJson<DateTime>(nextRetryAt),
      'status': serializer.toJson<String>(status),
    };
  }

  OutboxQueueData copyWith({
    String? id,
    String? pairId,
    Uint8List? encryptedPayload,
    String? messageType,
    DateTime? createdAt,
    int? attemptCount,
    DateTime? nextRetryAt,
    String? status,
  }) => OutboxQueueData(
    id: id ?? this.id,
    pairId: pairId ?? this.pairId,
    encryptedPayload: encryptedPayload ?? this.encryptedPayload,
    messageType: messageType ?? this.messageType,
    createdAt: createdAt ?? this.createdAt,
    attemptCount: attemptCount ?? this.attemptCount,
    nextRetryAt: nextRetryAt ?? this.nextRetryAt,
    status: status ?? this.status,
  );
  OutboxQueueData copyWithCompanion(OutboxQueueCompanion data) {
    return OutboxQueueData(
      id: data.id.present ? data.id.value : this.id,
      pairId: data.pairId.present ? data.pairId.value : this.pairId,
      encryptedPayload: data.encryptedPayload.present
          ? data.encryptedPayload.value
          : this.encryptedPayload,
      messageType: data.messageType.present
          ? data.messageType.value
          : this.messageType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxQueueData(')
          ..write('id: $id, ')
          ..write('pairId: $pairId, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('messageType: $messageType, ')
          ..write('createdAt: $createdAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pairId,
    $driftBlobEquality.hash(encryptedPayload),
    messageType,
    createdAt,
    attemptCount,
    nextRetryAt,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxQueueData &&
          other.id == this.id &&
          other.pairId == this.pairId &&
          $driftBlobEquality.equals(
            other.encryptedPayload,
            this.encryptedPayload,
          ) &&
          other.messageType == this.messageType &&
          other.createdAt == this.createdAt &&
          other.attemptCount == this.attemptCount &&
          other.nextRetryAt == this.nextRetryAt &&
          other.status == this.status);
}

class OutboxQueueCompanion extends UpdateCompanion<OutboxQueueData> {
  final Value<String> id;
  final Value<String> pairId;
  final Value<Uint8List> encryptedPayload;
  final Value<String> messageType;
  final Value<DateTime> createdAt;
  final Value<int> attemptCount;
  final Value<DateTime> nextRetryAt;
  final Value<String> status;
  final Value<int> rowid;
  const OutboxQueueCompanion({
    this.id = const Value.absent(),
    this.pairId = const Value.absent(),
    this.encryptedPayload = const Value.absent(),
    this.messageType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxQueueCompanion.insert({
    required String id,
    required String pairId,
    required Uint8List encryptedPayload,
    required String messageType,
    required DateTime createdAt,
    this.attemptCount = const Value.absent(),
    required DateTime nextRetryAt,
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pairId = Value(pairId),
       encryptedPayload = Value(encryptedPayload),
       messageType = Value(messageType),
       createdAt = Value(createdAt),
       nextRetryAt = Value(nextRetryAt);
  static Insertable<OutboxQueueData> custom({
    Expression<String>? id,
    Expression<String>? pairId,
    Expression<Uint8List>? encryptedPayload,
    Expression<String>? messageType,
    Expression<DateTime>? createdAt,
    Expression<int>? attemptCount,
    Expression<DateTime>? nextRetryAt,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pairId != null) 'pair_id': pairId,
      if (encryptedPayload != null) 'encrypted_payload': encryptedPayload,
      if (messageType != null) 'message_type': messageType,
      if (createdAt != null) 'created_at': createdAt,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? pairId,
    Value<Uint8List>? encryptedPayload,
    Value<String>? messageType,
    Value<DateTime>? createdAt,
    Value<int>? attemptCount,
    Value<DateTime>? nextRetryAt,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return OutboxQueueCompanion(
      id: id ?? this.id,
      pairId: pairId ?? this.pairId,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pairId.present) {
      map['pair_id'] = Variable<String>(pairId.value);
    }
    if (encryptedPayload.present) {
      map['encrypted_payload'] = Variable<Uint8List>(encryptedPayload.value);
    }
    if (messageType.present) {
      map['message_type'] = Variable<String>(messageType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxQueueCompanion(')
          ..write('id: $id, ')
          ..write('pairId: $pairId, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('messageType: $messageType, ')
          ..write('createdAt: $createdAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMessagesTable extends LocalMessages
    with TableInfo<$LocalMessagesTable, LocalMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pairIdMeta = const VerificationMeta('pairId');
  @override
  late final GeneratedColumn<String> pairId = GeneratedColumn<String>(
    'pair_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
    'sender_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _decryptedTextMeta = const VerificationMeta(
    'decryptedText',
  );
  @override
  late final GeneratedColumn<String> decryptedText = GeneratedColumn<String>(
    'decrypted_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaLocalPathMeta = const VerificationMeta(
    'mediaLocalPath',
  );
  @override
  late final GeneratedColumn<String> mediaLocalPath = GeneratedColumn<String>(
    'media_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaStorageUrlMeta = const VerificationMeta(
    'mediaStorageUrl',
  );
  @override
  late final GeneratedColumn<String> mediaStorageUrl = GeneratedColumn<String>(
    'media_storage_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _replyToIdMeta = const VerificationMeta(
    'replyToId',
  );
  @override
  late final GeneratedColumn<String> replyToId = GeneratedColumn<String>(
    'reply_to_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _disappearAtMeta = const VerificationMeta(
    'disappearAt',
  );
  @override
  late final GeneratedColumn<int> disappearAt = GeneratedColumn<int>(
    'disappear_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pairId,
    senderId,
    contentType,
    decryptedText,
    mediaLocalPath,
    mediaStorageUrl,
    status,
    replyToId,
    createdAt,
    updatedAt,
    isDeleted,
    disappearAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pair_id')) {
      context.handle(
        _pairIdMeta,
        pairId.isAcceptableOrUnknown(data['pair_id']!, _pairIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pairIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
    }
    if (data.containsKey('decrypted_text')) {
      context.handle(
        _decryptedTextMeta,
        decryptedText.isAcceptableOrUnknown(
          data['decrypted_text']!,
          _decryptedTextMeta,
        ),
      );
    }
    if (data.containsKey('media_local_path')) {
      context.handle(
        _mediaLocalPathMeta,
        mediaLocalPath.isAcceptableOrUnknown(
          data['media_local_path']!,
          _mediaLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('media_storage_url')) {
      context.handle(
        _mediaStorageUrlMeta,
        mediaStorageUrl.isAcceptableOrUnknown(
          data['media_storage_url']!,
          _mediaStorageUrlMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('reply_to_id')) {
      context.handle(
        _replyToIdMeta,
        replyToId.isAcceptableOrUnknown(data['reply_to_id']!, _replyToIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('disappear_at')) {
      context.handle(
        _disappearAtMeta,
        disappearAt.isAcceptableOrUnknown(
          data['disappear_at']!,
          _disappearAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pairId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pair_id'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_id'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      decryptedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}decrypted_text'],
      ),
      mediaLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_local_path'],
      ),
      mediaStorageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_storage_url'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      replyToId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reply_to_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      disappearAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}disappear_at'],
      ),
    );
  }

  @override
  $LocalMessagesTable createAlias(String alias) {
    return $LocalMessagesTable(attachedDatabase, alias);
  }
}

class LocalMessage extends DataClass implements Insertable<LocalMessage> {
  final String id;
  final String pairId;
  final String senderId;
  final String contentType;
  final String? decryptedText;
  final String? mediaLocalPath;
  final String? mediaStorageUrl;
  final String status;
  final String? replyToId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final int? disappearAt;
  const LocalMessage({
    required this.id,
    required this.pairId,
    required this.senderId,
    required this.contentType,
    this.decryptedText,
    this.mediaLocalPath,
    this.mediaStorageUrl,
    required this.status,
    this.replyToId,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    this.disappearAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pair_id'] = Variable<String>(pairId);
    map['sender_id'] = Variable<String>(senderId);
    map['content_type'] = Variable<String>(contentType);
    if (!nullToAbsent || decryptedText != null) {
      map['decrypted_text'] = Variable<String>(decryptedText);
    }
    if (!nullToAbsent || mediaLocalPath != null) {
      map['media_local_path'] = Variable<String>(mediaLocalPath);
    }
    if (!nullToAbsent || mediaStorageUrl != null) {
      map['media_storage_url'] = Variable<String>(mediaStorageUrl);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || replyToId != null) {
      map['reply_to_id'] = Variable<String>(replyToId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || disappearAt != null) {
      map['disappear_at'] = Variable<int>(disappearAt);
    }
    return map;
  }

  LocalMessagesCompanion toCompanion(bool nullToAbsent) {
    return LocalMessagesCompanion(
      id: Value(id),
      pairId: Value(pairId),
      senderId: Value(senderId),
      contentType: Value(contentType),
      decryptedText: decryptedText == null && nullToAbsent
          ? const Value.absent()
          : Value(decryptedText),
      mediaLocalPath: mediaLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaLocalPath),
      mediaStorageUrl: mediaStorageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaStorageUrl),
      status: Value(status),
      replyToId: replyToId == null && nullToAbsent
          ? const Value.absent()
          : Value(replyToId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      disappearAt: disappearAt == null && nullToAbsent
          ? const Value.absent()
          : Value(disappearAt),
    );
  }

  factory LocalMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMessage(
      id: serializer.fromJson<String>(json['id']),
      pairId: serializer.fromJson<String>(json['pairId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      contentType: serializer.fromJson<String>(json['contentType']),
      decryptedText: serializer.fromJson<String?>(json['decryptedText']),
      mediaLocalPath: serializer.fromJson<String?>(json['mediaLocalPath']),
      mediaStorageUrl: serializer.fromJson<String?>(json['mediaStorageUrl']),
      status: serializer.fromJson<String>(json['status']),
      replyToId: serializer.fromJson<String?>(json['replyToId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      disappearAt: serializer.fromJson<int?>(json['disappearAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pairId': serializer.toJson<String>(pairId),
      'senderId': serializer.toJson<String>(senderId),
      'contentType': serializer.toJson<String>(contentType),
      'decryptedText': serializer.toJson<String?>(decryptedText),
      'mediaLocalPath': serializer.toJson<String?>(mediaLocalPath),
      'mediaStorageUrl': serializer.toJson<String?>(mediaStorageUrl),
      'status': serializer.toJson<String>(status),
      'replyToId': serializer.toJson<String?>(replyToId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'disappearAt': serializer.toJson<int?>(disappearAt),
    };
  }

  LocalMessage copyWith({
    String? id,
    String? pairId,
    String? senderId,
    String? contentType,
    Value<String?> decryptedText = const Value.absent(),
    Value<String?> mediaLocalPath = const Value.absent(),
    Value<String?> mediaStorageUrl = const Value.absent(),
    String? status,
    Value<String?> replyToId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    Value<int?> disappearAt = const Value.absent(),
  }) => LocalMessage(
    id: id ?? this.id,
    pairId: pairId ?? this.pairId,
    senderId: senderId ?? this.senderId,
    contentType: contentType ?? this.contentType,
    decryptedText: decryptedText.present
        ? decryptedText.value
        : this.decryptedText,
    mediaLocalPath: mediaLocalPath.present
        ? mediaLocalPath.value
        : this.mediaLocalPath,
    mediaStorageUrl: mediaStorageUrl.present
        ? mediaStorageUrl.value
        : this.mediaStorageUrl,
    status: status ?? this.status,
    replyToId: replyToId.present ? replyToId.value : this.replyToId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    disappearAt: disappearAt.present ? disappearAt.value : this.disappearAt,
  );
  LocalMessage copyWithCompanion(LocalMessagesCompanion data) {
    return LocalMessage(
      id: data.id.present ? data.id.value : this.id,
      pairId: data.pairId.present ? data.pairId.value : this.pairId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      decryptedText: data.decryptedText.present
          ? data.decryptedText.value
          : this.decryptedText,
      mediaLocalPath: data.mediaLocalPath.present
          ? data.mediaLocalPath.value
          : this.mediaLocalPath,
      mediaStorageUrl: data.mediaStorageUrl.present
          ? data.mediaStorageUrl.value
          : this.mediaStorageUrl,
      status: data.status.present ? data.status.value : this.status,
      replyToId: data.replyToId.present ? data.replyToId.value : this.replyToId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      disappearAt: data.disappearAt.present
          ? data.disappearAt.value
          : this.disappearAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessage(')
          ..write('id: $id, ')
          ..write('pairId: $pairId, ')
          ..write('senderId: $senderId, ')
          ..write('contentType: $contentType, ')
          ..write('decryptedText: $decryptedText, ')
          ..write('mediaLocalPath: $mediaLocalPath, ')
          ..write('mediaStorageUrl: $mediaStorageUrl, ')
          ..write('status: $status, ')
          ..write('replyToId: $replyToId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('disappearAt: $disappearAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pairId,
    senderId,
    contentType,
    decryptedText,
    mediaLocalPath,
    mediaStorageUrl,
    status,
    replyToId,
    createdAt,
    updatedAt,
    isDeleted,
    disappearAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMessage &&
          other.id == this.id &&
          other.pairId == this.pairId &&
          other.senderId == this.senderId &&
          other.contentType == this.contentType &&
          other.decryptedText == this.decryptedText &&
          other.mediaLocalPath == this.mediaLocalPath &&
          other.mediaStorageUrl == this.mediaStorageUrl &&
          other.status == this.status &&
          other.replyToId == this.replyToId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.disappearAt == this.disappearAt);
}

class LocalMessagesCompanion extends UpdateCompanion<LocalMessage> {
  final Value<String> id;
  final Value<String> pairId;
  final Value<String> senderId;
  final Value<String> contentType;
  final Value<String?> decryptedText;
  final Value<String?> mediaLocalPath;
  final Value<String?> mediaStorageUrl;
  final Value<String> status;
  final Value<String?> replyToId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  final Value<int?> disappearAt;
  final Value<int> rowid;
  const LocalMessagesCompanion({
    this.id = const Value.absent(),
    this.pairId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.contentType = const Value.absent(),
    this.decryptedText = const Value.absent(),
    this.mediaLocalPath = const Value.absent(),
    this.mediaStorageUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.replyToId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.disappearAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMessagesCompanion.insert({
    required String id,
    required String pairId,
    required String senderId,
    required String contentType,
    this.decryptedText = const Value.absent(),
    this.mediaLocalPath = const Value.absent(),
    this.mediaStorageUrl = const Value.absent(),
    required String status,
    this.replyToId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isDeleted = const Value.absent(),
    this.disappearAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pairId = Value(pairId),
       senderId = Value(senderId),
       contentType = Value(contentType),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalMessage> custom({
    Expression<String>? id,
    Expression<String>? pairId,
    Expression<String>? senderId,
    Expression<String>? contentType,
    Expression<String>? decryptedText,
    Expression<String>? mediaLocalPath,
    Expression<String>? mediaStorageUrl,
    Expression<String>? status,
    Expression<String>? replyToId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<int>? disappearAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pairId != null) 'pair_id': pairId,
      if (senderId != null) 'sender_id': senderId,
      if (contentType != null) 'content_type': contentType,
      if (decryptedText != null) 'decrypted_text': decryptedText,
      if (mediaLocalPath != null) 'media_local_path': mediaLocalPath,
      if (mediaStorageUrl != null) 'media_storage_url': mediaStorageUrl,
      if (status != null) 'status': status,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (disappearAt != null) 'disappear_at': disappearAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? pairId,
    Value<String>? senderId,
    Value<String>? contentType,
    Value<String?>? decryptedText,
    Value<String?>? mediaLocalPath,
    Value<String?>? mediaStorageUrl,
    Value<String>? status,
    Value<String?>? replyToId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isDeleted,
    Value<int?>? disappearAt,
    Value<int>? rowid,
  }) {
    return LocalMessagesCompanion(
      id: id ?? this.id,
      pairId: pairId ?? this.pairId,
      senderId: senderId ?? this.senderId,
      contentType: contentType ?? this.contentType,
      decryptedText: decryptedText ?? this.decryptedText,
      mediaLocalPath: mediaLocalPath ?? this.mediaLocalPath,
      mediaStorageUrl: mediaStorageUrl ?? this.mediaStorageUrl,
      status: status ?? this.status,
      replyToId: replyToId ?? this.replyToId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      disappearAt: disappearAt ?? this.disappearAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pairId.present) {
      map['pair_id'] = Variable<String>(pairId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (decryptedText.present) {
      map['decrypted_text'] = Variable<String>(decryptedText.value);
    }
    if (mediaLocalPath.present) {
      map['media_local_path'] = Variable<String>(mediaLocalPath.value);
    }
    if (mediaStorageUrl.present) {
      map['media_storage_url'] = Variable<String>(mediaStorageUrl.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (replyToId.present) {
      map['reply_to_id'] = Variable<String>(replyToId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (disappearAt.present) {
      map['disappear_at'] = Variable<int>(disappearAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessagesCompanion(')
          ..write('id: $id, ')
          ..write('pairId: $pairId, ')
          ..write('senderId: $senderId, ')
          ..write('contentType: $contentType, ')
          ..write('decryptedText: $decryptedText, ')
          ..write('mediaLocalPath: $mediaLocalPath, ')
          ..write('mediaStorageUrl: $mediaStorageUrl, ')
          ..write('status: $status, ')
          ..write('replyToId: $replyToId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('disappearAt: $disappearAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalReactionsTable extends LocalReactions
    with TableInfo<$LocalReactionsTable, LocalReaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalReactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    messageId,
    userId,
    emoji,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_reactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalReaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalReaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalReaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalReactionsTable createAlias(String alias) {
    return $LocalReactionsTable(attachedDatabase, alias);
  }
}

class LocalReaction extends DataClass implements Insertable<LocalReaction> {
  final String id;
  final String messageId;
  final String userId;
  final String emoji;
  final DateTime createdAt;
  const LocalReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['message_id'] = Variable<String>(messageId);
    map['user_id'] = Variable<String>(userId);
    map['emoji'] = Variable<String>(emoji);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalReactionsCompanion toCompanion(bool nullToAbsent) {
    return LocalReactionsCompanion(
      id: Value(id),
      messageId: Value(messageId),
      userId: Value(userId),
      emoji: Value(emoji),
      createdAt: Value(createdAt),
    );
  }

  factory LocalReaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalReaction(
      id: serializer.fromJson<String>(json['id']),
      messageId: serializer.fromJson<String>(json['messageId']),
      userId: serializer.fromJson<String>(json['userId']),
      emoji: serializer.fromJson<String>(json['emoji']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'messageId': serializer.toJson<String>(messageId),
      'userId': serializer.toJson<String>(userId),
      'emoji': serializer.toJson<String>(emoji),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalReaction copyWith({
    String? id,
    String? messageId,
    String? userId,
    String? emoji,
    DateTime? createdAt,
  }) => LocalReaction(
    id: id ?? this.id,
    messageId: messageId ?? this.messageId,
    userId: userId ?? this.userId,
    emoji: emoji ?? this.emoji,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalReaction copyWithCompanion(LocalReactionsCompanion data) {
    return LocalReaction(
      id: data.id.present ? data.id.value : this.id,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      userId: data.userId.present ? data.userId.value : this.userId,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalReaction(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('userId: $userId, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, messageId, userId, emoji, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalReaction &&
          other.id == this.id &&
          other.messageId == this.messageId &&
          other.userId == this.userId &&
          other.emoji == this.emoji &&
          other.createdAt == this.createdAt);
}

class LocalReactionsCompanion extends UpdateCompanion<LocalReaction> {
  final Value<String> id;
  final Value<String> messageId;
  final Value<String> userId;
  final Value<String> emoji;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalReactionsCompanion({
    this.id = const Value.absent(),
    this.messageId = const Value.absent(),
    this.userId = const Value.absent(),
    this.emoji = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalReactionsCompanion.insert({
    required String id,
    required String messageId,
    required String userId,
    required String emoji,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       messageId = Value(messageId),
       userId = Value(userId),
       emoji = Value(emoji),
       createdAt = Value(createdAt);
  static Insertable<LocalReaction> custom({
    Expression<String>? id,
    Expression<String>? messageId,
    Expression<String>? userId,
    Expression<String>? emoji,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (messageId != null) 'message_id': messageId,
      if (userId != null) 'user_id': userId,
      if (emoji != null) 'emoji': emoji,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalReactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? messageId,
    Value<String>? userId,
    Value<String>? emoji,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalReactionsCompanion(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalReactionsCompanion(')
          ..write('id: $id, ')
          ..write('messageId: $messageId, ')
          ..write('userId: $userId, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OutboxQueueTable outboxQueue = $OutboxQueueTable(this);
  late final $LocalMessagesTable localMessages = $LocalMessagesTable(this);
  late final $LocalReactionsTable localReactions = $LocalReactionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    outboxQueue,
    localMessages,
    localReactions,
  ];
}

typedef $$OutboxQueueTableCreateCompanionBuilder =
    OutboxQueueCompanion Function({
      required String id,
      required String pairId,
      required Uint8List encryptedPayload,
      required String messageType,
      required DateTime createdAt,
      Value<int> attemptCount,
      required DateTime nextRetryAt,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$OutboxQueueTableUpdateCompanionBuilder =
    OutboxQueueCompanion Function({
      Value<String> id,
      Value<String> pairId,
      Value<Uint8List> encryptedPayload,
      Value<String> messageType,
      Value<DateTime> createdAt,
      Value<int> attemptCount,
      Value<DateTime> nextRetryAt,
      Value<String> status,
      Value<int> rowid,
    });

class $$OutboxQueueTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxQueueTable> {
  $$OutboxQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pairId => $composableBuilder(
    column: $table.pairId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxQueueTable> {
  $$OutboxQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pairId => $composableBuilder(
    column: $table.pairId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxQueueTable> {
  $$OutboxQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pairId =>
      $composableBuilder(column: $table.pairId, builder: (column) => column);

  GeneratedColumn<Uint8List> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => column,
  );

  GeneratedColumn<String> get messageType => $composableBuilder(
    column: $table.messageType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$OutboxQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxQueueTable,
          OutboxQueueData,
          $$OutboxQueueTableFilterComposer,
          $$OutboxQueueTableOrderingComposer,
          $$OutboxQueueTableAnnotationComposer,
          $$OutboxQueueTableCreateCompanionBuilder,
          $$OutboxQueueTableUpdateCompanionBuilder,
          (
            OutboxQueueData,
            BaseReferences<_$AppDatabase, $OutboxQueueTable, OutboxQueueData>,
          ),
          OutboxQueueData,
          PrefetchHooks Function()
        > {
  $$OutboxQueueTableTableManager(_$AppDatabase db, $OutboxQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pairId = const Value.absent(),
                Value<Uint8List> encryptedPayload = const Value.absent(),
                Value<String> messageType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime> nextRetryAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxQueueCompanion(
                id: id,
                pairId: pairId,
                encryptedPayload: encryptedPayload,
                messageType: messageType,
                createdAt: createdAt,
                attemptCount: attemptCount,
                nextRetryAt: nextRetryAt,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pairId,
                required Uint8List encryptedPayload,
                required String messageType,
                required DateTime createdAt,
                Value<int> attemptCount = const Value.absent(),
                required DateTime nextRetryAt,
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxQueueCompanion.insert(
                id: id,
                pairId: pairId,
                encryptedPayload: encryptedPayload,
                messageType: messageType,
                createdAt: createdAt,
                attemptCount: attemptCount,
                nextRetryAt: nextRetryAt,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxQueueTable,
      OutboxQueueData,
      $$OutboxQueueTableFilterComposer,
      $$OutboxQueueTableOrderingComposer,
      $$OutboxQueueTableAnnotationComposer,
      $$OutboxQueueTableCreateCompanionBuilder,
      $$OutboxQueueTableUpdateCompanionBuilder,
      (
        OutboxQueueData,
        BaseReferences<_$AppDatabase, $OutboxQueueTable, OutboxQueueData>,
      ),
      OutboxQueueData,
      PrefetchHooks Function()
    >;
typedef $$LocalMessagesTableCreateCompanionBuilder =
    LocalMessagesCompanion Function({
      required String id,
      required String pairId,
      required String senderId,
      required String contentType,
      Value<String?> decryptedText,
      Value<String?> mediaLocalPath,
      Value<String?> mediaStorageUrl,
      required String status,
      Value<String?> replyToId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> isDeleted,
      Value<int?> disappearAt,
      Value<int> rowid,
    });
typedef $$LocalMessagesTableUpdateCompanionBuilder =
    LocalMessagesCompanion Function({
      Value<String> id,
      Value<String> pairId,
      Value<String> senderId,
      Value<String> contentType,
      Value<String?> decryptedText,
      Value<String?> mediaLocalPath,
      Value<String?> mediaStorageUrl,
      Value<String> status,
      Value<String?> replyToId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isDeleted,
      Value<int?> disappearAt,
      Value<int> rowid,
    });

class $$LocalMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pairId => $composableBuilder(
    column: $table.pairId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get decryptedText => $composableBuilder(
    column: $table.decryptedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaStorageUrl => $composableBuilder(
    column: $table.mediaStorageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replyToId => $composableBuilder(
    column: $table.replyToId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get disappearAt => $composableBuilder(
    column: $table.disappearAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pairId => $composableBuilder(
    column: $table.pairId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get decryptedText => $composableBuilder(
    column: $table.decryptedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaStorageUrl => $composableBuilder(
    column: $table.mediaStorageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replyToId => $composableBuilder(
    column: $table.replyToId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get disappearAt => $composableBuilder(
    column: $table.disappearAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pairId =>
      $composableBuilder(column: $table.pairId, builder: (column) => column);

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get decryptedText => $composableBuilder(
    column: $table.decryptedText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaLocalPath => $composableBuilder(
    column: $table.mediaLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaStorageUrl => $composableBuilder(
    column: $table.mediaStorageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get replyToId =>
      $composableBuilder(column: $table.replyToId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get disappearAt => $composableBuilder(
    column: $table.disappearAt,
    builder: (column) => column,
  );
}

class $$LocalMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMessagesTable,
          LocalMessage,
          $$LocalMessagesTableFilterComposer,
          $$LocalMessagesTableOrderingComposer,
          $$LocalMessagesTableAnnotationComposer,
          $$LocalMessagesTableCreateCompanionBuilder,
          $$LocalMessagesTableUpdateCompanionBuilder,
          (
            LocalMessage,
            BaseReferences<_$AppDatabase, $LocalMessagesTable, LocalMessage>,
          ),
          LocalMessage,
          PrefetchHooks Function()
        > {
  $$LocalMessagesTableTableManager(_$AppDatabase db, $LocalMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pairId = const Value.absent(),
                Value<String> senderId = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<String?> decryptedText = const Value.absent(),
                Value<String?> mediaLocalPath = const Value.absent(),
                Value<String?> mediaStorageUrl = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> replyToId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int?> disappearAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMessagesCompanion(
                id: id,
                pairId: pairId,
                senderId: senderId,
                contentType: contentType,
                decryptedText: decryptedText,
                mediaLocalPath: mediaLocalPath,
                mediaStorageUrl: mediaStorageUrl,
                status: status,
                replyToId: replyToId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                disappearAt: disappearAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pairId,
                required String senderId,
                required String contentType,
                Value<String?> decryptedText = const Value.absent(),
                Value<String?> mediaLocalPath = const Value.absent(),
                Value<String?> mediaStorageUrl = const Value.absent(),
                required String status,
                Value<String?> replyToId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> isDeleted = const Value.absent(),
                Value<int?> disappearAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMessagesCompanion.insert(
                id: id,
                pairId: pairId,
                senderId: senderId,
                contentType: contentType,
                decryptedText: decryptedText,
                mediaLocalPath: mediaLocalPath,
                mediaStorageUrl: mediaStorageUrl,
                status: status,
                replyToId: replyToId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                disappearAt: disappearAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMessagesTable,
      LocalMessage,
      $$LocalMessagesTableFilterComposer,
      $$LocalMessagesTableOrderingComposer,
      $$LocalMessagesTableAnnotationComposer,
      $$LocalMessagesTableCreateCompanionBuilder,
      $$LocalMessagesTableUpdateCompanionBuilder,
      (
        LocalMessage,
        BaseReferences<_$AppDatabase, $LocalMessagesTable, LocalMessage>,
      ),
      LocalMessage,
      PrefetchHooks Function()
    >;
typedef $$LocalReactionsTableCreateCompanionBuilder =
    LocalReactionsCompanion Function({
      required String id,
      required String messageId,
      required String userId,
      required String emoji,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalReactionsTableUpdateCompanionBuilder =
    LocalReactionsCompanion Function({
      Value<String> id,
      Value<String> messageId,
      Value<String> userId,
      Value<String> emoji,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalReactionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalReactionsTable> {
  $$LocalReactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalReactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalReactionsTable> {
  $$LocalReactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalReactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalReactionsTable> {
  $$LocalReactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalReactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalReactionsTable,
          LocalReaction,
          $$LocalReactionsTableFilterComposer,
          $$LocalReactionsTableOrderingComposer,
          $$LocalReactionsTableAnnotationComposer,
          $$LocalReactionsTableCreateCompanionBuilder,
          $$LocalReactionsTableUpdateCompanionBuilder,
          (
            LocalReaction,
            BaseReferences<_$AppDatabase, $LocalReactionsTable, LocalReaction>,
          ),
          LocalReaction,
          PrefetchHooks Function()
        > {
  $$LocalReactionsTableTableManager(
    _$AppDatabase db,
    $LocalReactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalReactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalReactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalReactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> messageId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalReactionsCompanion(
                id: id,
                messageId: messageId,
                userId: userId,
                emoji: emoji,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String messageId,
                required String userId,
                required String emoji,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalReactionsCompanion.insert(
                id: id,
                messageId: messageId,
                userId: userId,
                emoji: emoji,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalReactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalReactionsTable,
      LocalReaction,
      $$LocalReactionsTableFilterComposer,
      $$LocalReactionsTableOrderingComposer,
      $$LocalReactionsTableAnnotationComposer,
      $$LocalReactionsTableCreateCompanionBuilder,
      $$LocalReactionsTableUpdateCompanionBuilder,
      (
        LocalReaction,
        BaseReferences<_$AppDatabase, $LocalReactionsTable, LocalReaction>,
      ),
      LocalReaction,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OutboxQueueTableTableManager get outboxQueue =>
      $$OutboxQueueTableTableManager(_db, _db.outboxQueue);
  $$LocalMessagesTableTableManager get localMessages =>
      $$LocalMessagesTableTableManager(_db, _db.localMessages);
  $$LocalReactionsTableTableManager get localReactions =>
      $$LocalReactionsTableTableManager(_db, _db.localReactions);
}
