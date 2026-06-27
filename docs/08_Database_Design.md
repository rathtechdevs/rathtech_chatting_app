# 08 — Database Design

## Purpose
Define the complete PostgreSQL schema for Supabase, including all tables, columns, types, indexes, constraints, RLS policies, and relationships. Also defines the local SQLite schema via Drift.

---

## 1. Supabase Database Design

### 1.1 Schema Overview

```
auth.users (Supabase managed)
    │
    ├── user_profiles (1:1)
    ├── user_devices (1:many)
    ├── user_settings (1:1)
    └── user_presence (1:1)

pairs
    ├── user_a_id → auth.users
    ├── user_b_id → auth.users
    └── pair_id (PK)
            │
            ├── pair_invite_codes (1:1 active)
            ├── messages (1:many)
            │       └── message_reactions (1:many)
            └── signal_sessions (1:many)

user_prekey_bundles → auth.users
user_identity_keys → auth.users
```

---

### 1.2 Table: `user_profiles`

```sql
CREATE TABLE user_profiles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name    TEXT NOT NULL CHECK (char_length(display_name) BETWEEN 1 AND 30),
    avatar_url      TEXT,
    bio             TEXT CHECK (char_length(bio) <= 150),
    date_of_birth   DATE NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);

-- RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_can_read_own_and_partner_profile"
    ON user_profiles FOR SELECT
    USING (
        user_id = auth.uid()
        OR user_id IN (
            SELECT CASE
                WHEN user_a_id = auth.uid() THEN user_b_id
                WHEN user_b_id = auth.uid() THEN user_a_id
            END
            FROM pairs
            WHERE user_a_id = auth.uid() OR user_b_id = auth.uid()
        )
    );

CREATE POLICY "user_can_update_own_profile"
    ON user_profiles FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "user_can_insert_own_profile"
    ON user_profiles FOR INSERT
    WITH CHECK (user_id = auth.uid());
```

**Columns:**
| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | UUID | PK | Internal ID |
| user_id | UUID | FK → auth.users, UNIQUE | One profile per user |
| display_name | TEXT | 1–30 chars | Shown to partner |
| avatar_url | TEXT | Nullable | Supabase Storage URL |
| bio | TEXT | ≤150 chars, Nullable | Optional |
| date_of_birth | DATE | Not null | Age verification (18+) |
| created_at | TIMESTAMPTZ | Default NOW() | |
| updated_at | TIMESTAMPTZ | Default NOW() | Updated by trigger |

---

### 1.3 Table: `user_devices`

```sql
CREATE TABLE user_devices (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fcm_token   TEXT NOT NULL,
    platform    TEXT NOT NULL CHECK (platform IN ('android', 'ios')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, fcm_token)
);

CREATE INDEX idx_user_devices_user_id ON user_devices(user_id);

ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_can_manage_own_devices"
    ON user_devices FOR ALL
    USING (user_id = auth.uid());
```

**Notes:** Stores FCM tokens for push notification delivery. Upserted (insert or update) every app launch.

---

### 1.4 Table: `user_settings`

```sql
CREATE TABLE user_settings (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    show_last_seen          BOOLEAN NOT NULL DEFAULT TRUE,
    read_receipts_enabled   BOOLEAN NOT NULL DEFAULT TRUE,
    typing_indicator_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    notification_sound      TEXT NOT NULL DEFAULT 'default',
    notification_muted_until TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_can_manage_own_settings"
    ON user_settings FOR ALL
    USING (user_id = auth.uid());
```

---

### 1.5 Table: `user_presence`

```sql
CREATE TABLE user_presence (
    user_id     UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    is_online   BOOLEAN NOT NULL DEFAULT FALSE,
    last_seen   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE user_presence ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pair_members_can_read_presence"
    ON user_presence FOR SELECT
    USING (
        user_id = auth.uid()
        OR user_id IN (
            SELECT CASE
                WHEN user_a_id = auth.uid() THEN user_b_id
                ELSE user_a_id
            END
            FROM pairs
            WHERE user_a_id = auth.uid() OR user_b_id = auth.uid()
        )
    );

CREATE POLICY "user_can_update_own_presence"
    ON user_presence FOR ALL
    USING (user_id = auth.uid());
```

---

### 1.6 Table: `pairs`

```sql
CREATE TABLE pairs (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_a_id                   UUID NOT NULL REFERENCES auth.users(id),
    user_b_id                   UUID NOT NULL REFERENCES auth.users(id),
    disappearing_message_hours  INTEGER,   -- NULL = off; 1, 24, 168, 720
    pending_disappearing_hours  INTEGER,   -- Proposed but not yet confirmed by partner
    proposed_by                 UUID REFERENCES auth.users(id),
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT pair_no_self_join CHECK (user_a_id <> user_b_id),
    CONSTRAINT pair_unique_users UNIQUE (
        LEAST(user_a_id::TEXT, user_b_id::TEXT)::UUID,
        GREATEST(user_a_id::TEXT, user_b_id::TEXT)::UUID
    )
);

CREATE INDEX idx_pairs_user_a ON pairs(user_a_id);
CREATE INDEX idx_pairs_user_b ON pairs(user_b_id);

ALTER TABLE pairs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pair_members_can_read_pair"
    ON pairs FOR SELECT
    USING (user_a_id = auth.uid() OR user_b_id = auth.uid());

CREATE POLICY "pair_members_can_update_pair"
    ON pairs FOR UPDATE
    USING (user_a_id = auth.uid() OR user_b_id = auth.uid());

-- INSERT handled by invite code Edge Function only (not direct client insert)
```

**Notes:** The `UNIQUE` constraint on `LEAST/GREATEST` ensures (A, B) and (B, A) are treated as the same pair, preventing duplicate pairs.

---

### 1.7 Table: `pair_invite_codes`

```sql
CREATE TABLE pair_invite_codes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code        TEXT NOT NULL UNIQUE CHECK (char_length(code) = 8),
    creator_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    expires_at  TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '48 hours'),
    used        BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_invite_codes_creator ON pair_invite_codes(creator_id);
CREATE INDEX idx_invite_codes_code ON pair_invite_codes(code);

ALTER TABLE pair_invite_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "creator_can_read_own_codes"
    ON pair_invite_codes FOR SELECT
    USING (creator_id = auth.uid());

CREATE POLICY "authenticated_can_lookup_code"
    ON pair_invite_codes FOR SELECT
    USING (auth.uid() IS NOT NULL AND NOT used AND expires_at > NOW());

CREATE POLICY "creator_can_insert_code"
    ON pair_invite_codes FOR INSERT
    WITH CHECK (creator_id = auth.uid());
```

---

### 1.8 Table: `messages`

```sql
CREATE TABLE messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pair_id         UUID NOT NULL REFERENCES pairs(id) ON DELETE CASCADE,
    sender_id       UUID NOT NULL REFERENCES auth.users(id),
    message_type    TEXT NOT NULL CHECK (message_type IN ('text', 'image', 'voice', 'video', 'system')),
    ciphertext      BYTEA NOT NULL,   -- Signal Protocol encrypted blob
    iv              BYTEA,            -- For media: AES-GCM IV
    status          TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'read', 'deleted')),
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    edited_at       TIMESTAMPTZ,
    expires_at      TIMESTAMPTZ,      -- NULL = never expires
    deleted_at      TIMESTAMPTZ,
    CONSTRAINT message_sender_in_pair CHECK (
        sender_id IN (
            SELECT user_a_id FROM pairs WHERE id = pair_id
            UNION
            SELECT user_b_id FROM pairs WHERE id = pair_id
        )
    )
);

CREATE INDEX idx_messages_pair_id_sent_at ON messages(pair_id, sent_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_expires ON messages(expires_at) WHERE expires_at IS NOT NULL;

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pair_members_can_read_messages"
    ON messages FOR SELECT
    USING (
        pair_id IN (
            SELECT id FROM pairs
            WHERE user_a_id = auth.uid() OR user_b_id = auth.uid()
        )
    );

CREATE POLICY "sender_can_insert_message"
    ON messages FOR INSERT
    WITH CHECK (
        sender_id = auth.uid()
        AND pair_id IN (
            SELECT id FROM pairs
            WHERE user_a_id = auth.uid() OR user_b_id = auth.uid()
        )
    );

CREATE POLICY "sender_can_update_own_message"
    ON messages FOR UPDATE
    USING (sender_id = auth.uid());
```

**Critical Design Notes:**
- `ciphertext` is `BYTEA` — opaque binary. Server cannot read it.
- `message_type` determines how the receiver interprets the decrypted content.
- `expires_at` populated when disappearing messages enabled.
- Deleted messages: `ciphertext` cleared, `status` = 'deleted', `deleted_at` set.

---

### 1.9 Table: `message_receipts`

```sql
CREATE TABLE message_receipts (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id  UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES auth.users(id),
    read_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (message_id, user_id)
);

CREATE INDEX idx_receipts_message ON message_receipts(message_id);

ALTER TABLE message_receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pair_members_can_manage_receipts"
    ON message_receipts FOR ALL
    USING (
        user_id = auth.uid()
        OR message_id IN (
            SELECT id FROM messages
            WHERE pair_id IN (
                SELECT id FROM pairs
                WHERE user_a_id = auth.uid() OR user_b_id = auth.uid()
            )
        )
    );
```

---

### 1.10 Table: `message_reactions`

```sql
CREATE TABLE message_reactions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id  UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES auth.users(id),
    emoji       TEXT NOT NULL CHECK (char_length(emoji) <= 8),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (message_id, user_id)
);

CREATE INDEX idx_reactions_message ON message_reactions(message_id);

ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pair_members_can_manage_reactions"
    ON message_reactions FOR ALL
    USING (
        message_id IN (
            SELECT id FROM messages
            WHERE pair_id IN (
                SELECT id FROM pairs
                WHERE user_a_id = auth.uid() OR user_b_id = auth.uid()
            )
        )
    );
```

---

### 1.11 Table: `user_identity_keys`

```sql
CREATE TABLE user_identity_keys (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    public_key          BYTEA NOT NULL,   -- Identity public key (Curve25519)
    registration_id     INTEGER NOT NULL, -- Signal Protocol registration ID
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE user_identity_keys ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pair_members_can_read_identity_keys"
    ON user_identity_keys FOR SELECT
    USING (
        user_id = auth.uid()
        OR user_id IN (
            SELECT CASE
                WHEN user_a_id = auth.uid() THEN user_b_id
                ELSE user_a_id
            END FROM pairs
            WHERE user_a_id = auth.uid() OR user_b_id = auth.uid()
        )
    );

CREATE POLICY "user_can_insert_own_identity_key"
    ON user_identity_keys FOR INSERT
    WITH CHECK (user_id = auth.uid());
```

---

### 1.12 Table: `user_prekey_bundles`

```sql
CREATE TABLE user_prekey_bundles (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    prekey_id           INTEGER NOT NULL,
    public_key          BYTEA NOT NULL,
    signed_prekey_id    INTEGER,
    signed_public_key   BYTEA,
    signature           BYTEA,
    is_one_time         BOOLEAN NOT NULL DEFAULT TRUE,
    used                BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, prekey_id, is_one_time)
);

CREATE INDEX idx_prekeys_user_unused ON user_prekey_bundles(user_id, used) WHERE NOT used;

ALTER TABLE user_prekey_bundles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pair_member_can_fetch_partner_prekey"
    ON user_prekey_bundles FOR SELECT
    USING (
        user_id = auth.uid()
        OR user_id IN (
            SELECT CASE
                WHEN user_a_id = auth.uid() THEN user_b_id
                ELSE user_a_id
            END FROM pairs
            WHERE user_a_id = auth.uid() OR user_b_id = auth.uid()
        )
    );

CREATE POLICY "user_can_insert_own_prekeys"
    ON user_prekey_bundles FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "user_can_update_own_prekeys"
    ON user_prekey_bundles FOR UPDATE
    USING (user_id = auth.uid());
```

---

## 2. Supabase Storage Buckets

### Bucket: `avatars`
- **Access:** Public (avatars visible to partner, no encryption needed)
- **Max file size:** 5MB
- **Allowed MIME types:** image/jpeg, image/png, image/webp
- **RLS:** Any authenticated user can read; only owner can write

### Bucket: `chat-media`
- **Access:** Private (requires JWT to access)
- **Max file size:** 50MB
- **Allowed MIME types:** image/*, audio/*, video/*
- **Naming:** `{pair_id}/{message_id}/{encrypted_blob}`
- **RLS:** Only pair members can read/write to their pair folder

---

## 3. Local SQLite Schema (Drift)

### Table: `local_messages`

```dart
class LocalMessages extends Table {
  TextColumn get id => text()();                    // UUID
  TextColumn get pairId => text()();
  TextColumn get senderId => text()();
  TextColumn get messageType => text()();           // text|image|voice|video|system
  TextColumn get content => text()();               // DECRYPTED plaintext or media path
  TextColumn get mediaLocalPath => text().nullable()();
  TextColumn get status => text()();               // pending|sending|sent|delivered|read|failed|queued
  DateTimeColumn get sentAt => dateTime()();
  DateTimeColumn get editedAt => dateTime().nullable()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Table: `local_reactions`

```dart
class LocalReactions extends Table {
  TextColumn get id => text()();
  TextColumn get messageId => text()();
  TextColumn get userId => text()();
  TextColumn get emoji => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Table: `outbox_queue`

```dart
class OutboxQueue extends Table {
  TextColumn get id => text()();                    // Temp UUID
  TextColumn get pairId => text()();
  TextColumn get ciphertext => text()();            // Base64 encoded
  TextColumn get messageType => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### FTS5 Virtual Table

```dart
// Drift FTS5 for full-text search on decrypted content
@DriftDatabase(tables: [LocalMessages, LocalReactions, OutboxQueue])
class AppDatabase extends _$AppDatabase {
  // FTS5 index created via customStatement in migration
}
```

---

## 4. Database Migration Strategy

- Supabase migrations managed via `supabase/migrations/` directory
- Local Drift migrations managed via `schemaVersion` and `MigrationStrategy`
- Never drop columns without a deprecation period
- All migrations reversible where possible

---

## 5. Index Strategy

| Table | Index | Purpose |
|---|---|---|
| messages | (pair_id, sent_at DESC) | Primary message list query |
| messages | expires_at WHERE NOT NULL | Efficient cleanup job |
| user_prekey_bundles | (user_id, used) WHERE NOT used | Fetch unused prekeys |
| local_messages | (pair_id, sent_at DESC) | Primary chat list query |
| local_messages | FTS5 on content | Full-text search |
