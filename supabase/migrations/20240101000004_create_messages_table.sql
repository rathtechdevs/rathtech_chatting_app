-- ── messages ─────────────────────────────────────────────────────────────────
-- ciphertext / signal_header stored as TEXT (base64 strings from Signal Protocol).
-- Server cannot decrypt them; TEXT is simpler than BYTEA for supabase-flutter.

CREATE TABLE messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pair_id         UUID NOT NULL REFERENCES pairs(id) ON DELETE CASCADE,
    sender_id       UUID NOT NULL REFERENCES auth.users(id),
    message_type    TEXT NOT NULL DEFAULT 'text'
                        CHECK (message_type IN ('text', 'image', 'voice', 'video', 'system')),
    ciphertext      TEXT NOT NULL,    -- Base64 AES-CBC ciphertext (from EncryptedPayload)
    signal_header   TEXT NOT NULL,    -- Base64 Double Ratchet header JSON
    message_index   INTEGER NOT NULL, -- Ratchet counter; used for out-of-order detection
    signal_type     TEXT NOT NULL DEFAULT 'signal'
                        CHECK (signal_type IN ('prekey', 'signal')),
    status          TEXT NOT NULL DEFAULT 'sent'
                        CHECK (status IN ('sent', 'delivered', 'read', 'deleted')),
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    edited_at       TIMESTAMPTZ,
    expires_at      TIMESTAMPTZ,
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_messages_pair_sent ON messages(pair_id, sent_at DESC);
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

-- ── Enable Realtime for messages ──────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
