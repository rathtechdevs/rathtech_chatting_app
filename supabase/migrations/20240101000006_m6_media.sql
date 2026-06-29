-- M6: Media Messages
-- Add media columns to messages table
ALTER TABLE messages
  ADD COLUMN media_storage_path TEXT,
  ADD COLUMN media_duration_ms  INTEGER;

-- Supabase Storage: private bucket for encrypted media blobs.
-- All files are opaque binary (AES-256-GCM ciphertext) — the bucket
-- never holds plaintext media.
INSERT INTO storage.buckets (id, name, public)
VALUES ('media', 'media', false)
ON CONFLICT (id) DO NOTHING;

-- RLS for the media bucket: any authenticated user can read/write.
-- Row-level security on the messages table (pair_id check) provides the
-- real access control — the bucket path "{pair_id}/{message_id}.bin"
-- is only meaningful to authenticated clients who already have the
-- Signal-encrypted media key from the messages table.

CREATE POLICY "authenticated_users_select_media"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'media' AND auth.uid() IS NOT NULL);

CREATE POLICY "authenticated_users_insert_media"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'media' AND auth.uid() IS NOT NULL);

CREATE POLICY "authenticated_users_delete_media"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'media' AND auth.uid() IS NOT NULL);
