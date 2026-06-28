import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { corsHeaders } from '../_shared/cors.ts'

// Deletes messages whose expires_at has passed.
// Invoked by Supabase Cron (pg_cron) or manually via Edge Function call.
// Schedule: every 15 minutes (set in Supabase Dashboard → Database → Extensions → pg_cron)
Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    { auth: { autoRefreshToken: false, persistSession: false } }
  )

  const now = new Date().toISOString()

  // Soft-delete by setting status = 'deleted' so partners get Realtime UPDATE.
  const { data, error } = await supabaseAdmin
    .from('messages')
    .update({ status: 'deleted', deleted_at: now })
    .lt('expires_at', now)
    .neq('status', 'deleted')
    .select('id')

  if (error) {
    console.error('cleanup-expired-messages error:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }

  const deletedCount = data?.length ?? 0
  console.log(`cleanup-expired-messages: soft-deleted ${deletedCount} messages`)

  return new Response(
    JSON.stringify({ deleted: deletedCount, timestamp: now }),
    { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  )
})
