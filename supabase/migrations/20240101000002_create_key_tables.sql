-- Migration: Create Signal Protocol key tables
-- Milestone: M2 (Encryption Core)
-- Depends on: auth.users, set_updated_at() from M1

CREATE TABLE IF NOT EXISTS public.user_identity_keys (
  user_id             UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  identity_key        TEXT        NOT NULL, -- X25519 public key (base64)
  identity_signing_key TEXT       NOT NULL, -- Ed25519 public key (base64) for SPK verification
  registration_id     INT         NOT NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_user_identity_keys_updated_at
  BEFORE UPDATE ON public.user_identity_keys
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.user_prekey_bundles (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  prekey_type TEXT        NOT NULL CHECK (prekey_type IN ('signed', 'one_time')),
  prekey_id   INT         NOT NULL,
  public_key  TEXT        NOT NULL, -- X25519 public key (base64)
  signature   TEXT,                 -- Ed25519 signature (base64), signed prekeys only
  is_consumed BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, prekey_type, prekey_id)
);

-- Row Level Security
ALTER TABLE public.user_identity_keys   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_prekey_bundles  ENABLE ROW LEVEL SECURITY;

-- Identity keys: any authenticated user can read (needed for X3DH session setup)
CREATE POLICY "identity_keys_select_authenticated"
  ON public.user_identity_keys FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "identity_keys_insert_own"
  ON public.user_identity_keys FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "identity_keys_update_own"
  ON public.user_identity_keys FOR UPDATE
  USING (auth.uid() = user_id);

-- Prekey bundles: any authenticated user can read (needed for X3DH)
CREATE POLICY "prekey_bundles_select_authenticated"
  ON public.user_prekey_bundles FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "prekey_bundles_insert_own"
  ON public.user_prekey_bundles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Owner updates their own keys (e.g. rotate SPK); any authenticated user can
-- mark a one-time prekey consumed (happens when fetching partner's OPK for X3DH).
CREATE POLICY "prekey_bundles_update_own"
  ON public.user_prekey_bundles FOR UPDATE
  USING (auth.uid() = user_id OR prekey_type = 'one_time');
