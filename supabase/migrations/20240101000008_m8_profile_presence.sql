-- M8: User Profile & Partner Presence

-- ── Profile RLS: allow pair members to read each other's profiles ─────────────

-- Replace the own-only SELECT policy with one that also allows pair members.
DROP POLICY IF EXISTS "user_profiles_select_own" ON public.user_profiles;

CREATE POLICY "user_profiles_select_self_or_partner"
  ON public.user_profiles
  FOR SELECT
  USING (
    id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.pairs p
      WHERE (p.user_a_id = auth.uid() AND p.user_b_id = id)
         OR (p.user_b_id = auth.uid() AND p.user_a_id = id)
    )
  );

-- ── user_presence table ───────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.user_presence (
  user_id      UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  is_online    BOOL        NOT NULL DEFAULT FALSE,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Realtime so partners receive live presence updates.
ALTER TABLE public.user_presence REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_presence;

ALTER TABLE public.user_presence ENABLE ROW LEVEL SECURITY;

-- Users can upsert only their own presence.
CREATE POLICY "presence_upsert_own"
  ON public.user_presence
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Pair members can read each other's presence.
CREATE POLICY "presence_select_pair_member"
  ON public.user_presence
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.pairs p
      WHERE (p.user_a_id = auth.uid() AND p.user_b_id = user_id)
         OR (p.user_b_id = auth.uid() AND p.user_a_id = user_id)
    )
  );

-- ── avatars storage bucket ────────────────────────────────────────────────────
-- Public bucket — avatar URLs are opaque UUIDs, acceptable for a private app.

INSERT INTO storage.buckets (id, name, public)
  VALUES ('avatars', 'avatars', TRUE)
  ON CONFLICT (id) DO NOTHING;

-- Users can manage only their own avatar file (named <user_id>.jpg).
CREATE POLICY "avatars_manage_own"
  ON storage.objects
  FOR ALL
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND name = (auth.uid()::TEXT || '.jpg')
  )
  WITH CHECK (
    bucket_id = 'avatars'
    AND name = (auth.uid()::TEXT || '.jpg')
  );

-- Any authenticated user can read avatars (required to show partner's avatar).
CREATE POLICY "avatars_read_authenticated"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'avatars');
