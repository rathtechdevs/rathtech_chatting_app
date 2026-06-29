-- ── pairs ────────────────────────────────────────────────────────────────────

CREATE TABLE pairs (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_a_id                   UUID NOT NULL REFERENCES auth.users(id),
    user_b_id                   UUID NOT NULL REFERENCES auth.users(id),
    disappearing_message_hours  INTEGER,
    pending_disappearing_hours  INTEGER,
    proposed_by                 UUID REFERENCES auth.users(id),
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT pair_no_self_join CHECK (user_a_id <> user_b_id)
);

CREATE INDEX idx_pairs_user_a ON pairs(user_a_id);
CREATE INDEX idx_pairs_user_b ON pairs(user_b_id);

-- Ensures (user_a, user_b) and (user_b, user_a) are treated as the same pair.
-- UNIQUE constraints don't support expressions; a unique index does.
CREATE UNIQUE INDEX idx_pair_unique_users ON pairs(
    LEAST(user_a_id, user_b_id),
    GREATEST(user_a_id, user_b_id)
);

ALTER TABLE pairs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pair_members_can_read_pair"
    ON pairs FOR SELECT
    USING (user_a_id = auth.uid() OR user_b_id = auth.uid());

CREATE POLICY "pair_members_can_update_pair"
    ON pairs FOR UPDATE
    USING (user_a_id = auth.uid() OR user_b_id = auth.uid());

-- INSERT handled exclusively by the accept-invite-code Edge Function (service role).

-- ── pair_invite_codes ─────────────────────────────────────────────────────────

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

-- Allows any authenticated user to look up a valid (unused, unexpired) code.
CREATE POLICY "authenticated_can_lookup_valid_code"
    ON pair_invite_codes FOR SELECT
    USING (auth.uid() IS NOT NULL AND NOT used AND expires_at > NOW());

CREATE POLICY "creator_can_insert_code"
    ON pair_invite_codes FOR INSERT
    WITH CHECK (creator_id = auth.uid());
