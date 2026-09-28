export type MutateOperation = 'insert' | 'update' | 'delete';

export interface MutateResult {
  data: unknown[] | null;
  error: string | null;
}

/**
 * Sends a write operation to the server-side admin API route,
 * which uses the Supabase service role key to bypass RLS.
 */
export async function adminMutate(
  table: string,
  operation: MutateOperation,
  payload?: Record<string, unknown>,
  match?: Record<string, unknown>
): Promise<MutateResult> {
  try {
    const res = await fetch('/api/admin/mutate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ table, operation, payload, match }),
    });

    const json = await res.json();

    if (!res.ok || json.error) {
      console.error(`[adminMutate] ${operation} ${table} failed:`, json.error);
      return { data: null, error: json.error ?? `HTTP ${res.status}` };
    }

    console.log(`[adminMutate] ${operation} ${table} OK`, json.data);
    return { data: json.data ?? null, error: null };
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(`[adminMutate] ${operation} ${table} threw:`, msg);
    return { data: null, error: msg };
  }
}
