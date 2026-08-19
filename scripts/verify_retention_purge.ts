// Tests the retention purge RPC function (OPS-001) against Supabase.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.1";

const supabaseUrl = Deno.env.get("SUPABASE_URL") || "http://127.0.0.1:54321";
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "ci-service-role-key";

console.log(`Connecting to Supabase at ${supabaseUrl}...`);
const supabase = createClient(supabaseUrl, serviceRoleKey);

// Verify calling purge_ai_usage_events with service_role
const { data, error } = await supabase.rpc("purge_ai_usage_events", {
  p_before: new Date(Date.now() - 90 * 86400 * 1000).toISOString(),
});

if (error) {
  console.error("Error executing purge_ai_usage_events:", error);
  Deno.exit(1);
}

console.log(`Retention purge test successful. Rows purged: ${data}`);
