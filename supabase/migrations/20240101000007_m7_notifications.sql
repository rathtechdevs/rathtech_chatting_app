-- M7: Push Notifications
-- Add FCM token storage to user profiles.
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Trigger: call send-push-notification Edge Function on every new message.
-- Requires the pg_net extension (enabled by default on Supabase).
--
-- Before applying this migration, set the Supabase project URL as a
-- database parameter via the Supabase dashboard → Settings → Database:
--   app.supabase_url  = 'https://<project-ref>.supabase.co'
--
-- The Edge Function authenticates itself using the service role key, which
-- Supabase makes available inside the function via the
-- SUPABASE_SERVICE_ROLE_KEY environment variable automatically.

CREATE OR REPLACE FUNCTION public.notify_send_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_project_url TEXT;
BEGIN
  -- Skip deleted / system messages.
  IF NEW.status = 'deleted' THEN
    RETURN NEW;
  END IF;

  v_project_url := current_setting('app.supabase_url', true);

  -- Fire-and-forget HTTP call; errors are logged but do not block the INSERT.
  PERFORM net.http_post(
    url     := v_project_url || '/functions/v1/send-push-notification',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      'Authorization', 'Bearer ' || current_setting('app.supabase_service_role_key', true)
    ),
    body    := jsonb_build_object(
      'message_id',   NEW.id,
      'pair_id',      NEW.pair_id,
      'sender_id',    NEW.sender_id,
      'message_type', NEW.message_type
    )
  );

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Never let a notification error break message delivery.
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_new_message_notify ON public.messages;

CREATE TRIGGER on_new_message_notify
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_send_push();
