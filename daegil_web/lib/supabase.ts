import { createClient, type SupabaseClient } from '@supabase/supabase-js';

let client: SupabaseClient | null = null;

export function getSupabaseClient(): SupabaseClient | null {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if (!url || !key) return null;
  client ??= createClient(url, key, {
    // The callback route performs the one-time PKCE exchange explicitly.
    // Keeping automatic URL detection enabled would make both the client
    // initializer and /auth/callback consume the same authorization code.
    auth: { flowType: 'pkce', detectSessionInUrl: false, persistSession: true },
  });
  return client;
}

export function getWebRedirectUrl(): string {
  if (typeof window !== 'undefined') return `${window.location.origin}/auth/callback`;
  return 'https://daegil.allinfoworld119.com/auth/callback';
}
