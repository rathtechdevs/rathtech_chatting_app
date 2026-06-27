-- Migration: Create user_profiles table
-- Milestone: M1 (Authentication)
-- Depends on: Supabase auth.users (built-in)

CREATE TABLE IF NOT EXISTS public.user_profiles (
  id           UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT        NOT NULL CHECK (length(display_name) BETWEEN 1 AND 30),
  avatar_url   TEXT,
  date_of_birth DATE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-update updated_at on row modification
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Users can read only their own profile (partner profile fetched via Edge Function in M3)
CREATE POLICY "user_profiles_select_own"
  ON public.user_profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Users can insert only their own profile
CREATE POLICY "user_profiles_insert_own"
  ON public.user_profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update only their own profile
CREATE POLICY "user_profiles_update_own"
  ON public.user_profiles
  FOR UPDATE
  USING (auth.uid() = id);
