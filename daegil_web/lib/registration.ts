import type { SupabaseClient } from '@supabase/supabase-js';

export const registrationStorageKey = 'daegil-web-registration';

export async function withAuthDeadline<T>(operation: PromiseLike<T>, timeoutMs = 15_000): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    return await Promise.race([
      Promise.resolve(operation),
      new Promise<never>((_, reject) => {
        timer = setTimeout(() => reject(new Error('AUTH_REQUEST_TIMEOUT')), timeoutMs);
      }),
    ]);
  } finally {
    if (timer !== undefined) clearTimeout(timer);
  }
}

export function isRegistrationComplete(state: { gate?: string } | null | undefined): boolean {
  return state?.gate === 'NONE';
}

export async function completePendingRegistration(
  client: Pick<SupabaseClient, 'rpc'>,
  storage: Pick<Storage, 'getItem' | 'removeItem'>,
) {
  const raw = storage.getItem(registrationStorageKey);
  if (!raw) return;
  const registration = JSON.parse(raw) as {
    age14PlusAttested: boolean; displayedDocumentIds: string[]; acceptedDocumentIds: string[];
  };
  const { error } = await withAuthDeadline(client.rpc('complete_my_registration', {
    age_14_plus_attested: registration.age14PlusAttested,
    displayed_document_ids: registration.displayedDocumentIds,
    accepted_document_ids: registration.acceptedDocumentIds,
    analytics_enabled: false,
  }));
  if (error) throw error;
  // Do not erase a newer selection written while this request was in flight.
  if (storage.getItem(registrationStorageKey) === raw) storage.removeItem(registrationStorageKey);
}
