-- ── M5: Message Features ─────────────────────────────────────────────────────

-- message_reactions — one emoji per user per message (toggle model)
CREATE TABLE message_reactions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id  UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    emoji       TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (message_id, user_id)   -- one active reaction per user per message
);

CREATE INDEX idx_reactions_message ON message_reactions(message_id);

-- REPLICA IDENTITY FULL so Realtime DELETE payloads include the full old row.
ALTER TABLE message_reactions REPLICA IDENTITY FULL;
ALTER TABLE messages REPLICA IDENTITY FULL;

ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pair_members_can_read_reactions"
    ON message_reactions FOR SELECT
    USING (
        message_id IN (
            SELECT id FROM messages
            WHERE pair_id IN (
                SELECT id FROM pairs
                WHERE user_a_id = auth.uid() OR user_b_id = auth.uid()
            )
        )
    );

CREATE POLICY "user_can_manage_own_reaction"
    ON message_reactions FOR ALL
    USING (user_id = auth.uid());

-- Enable Realtime for reactions
ALTER PUBLICATION supabase_realtime ADD TABLE message_reactions;
