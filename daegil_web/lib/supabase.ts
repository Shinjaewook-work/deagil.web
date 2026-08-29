import { createClient, type SupabaseClient } from '@supabase/supabase-js';

let client: SupabaseClient | null = null;

export function getSupabaseClient(): SupabaseClient | null {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if (!url || !key) return null;
  client ??= createClient(url, key, {
    auth: { flowType: 'pkce', detectSessionInUrl: true, persistSession: true },
  });
  return client;
}

export function getWebRedirectUrl(): string {
  if (typeof window !== 'undefined') return `${window.location.origin}/auth/callback`;
  return 'https://daegil.allinfoworld119.com/auth/callback';
}
