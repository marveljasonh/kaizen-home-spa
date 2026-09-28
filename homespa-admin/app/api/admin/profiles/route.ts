import { NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

export async function GET() {
  const supabase = createAdminClient();

  const { data: profiles, error: profilesError } = await supabase
    .from('profiles')
    .select('id, full_name, avatar_url');

  if (profilesError) {
    console.error('[API/admin/profiles] profiles error:', profilesError);
    return NextResponse.json({ error: profilesError.message }, { status: 500 });
  }

  console.log(`[API/admin/profiles] profiles row count: ${profiles?.length ?? 0}`);

  // Find profiles missing a name so we can backfill from auth.users metadata
  const missingNameIds = (profiles ?? [])
    .filter((p) => !p.full_name)
    .map((p) => p.id);

  console.log(`[API/admin/profiles] profiles with null full_name: ${missingNameIds.length}`, missingNameIds);

  const metaMap: Record<string, string> = {};

  if (missingNameIds.length > 0) {
    // auth.users is only accessible via the admin API
    const { data: authUsers, error: authError } = await supabase.auth.admin.listUsers();
    if (authError) {
      console.error('[API/admin/profiles] auth.admin.listUsers error:', authError);
    } else {
      for (const u of authUsers.users) {
        if (missingNameIds.includes(u.id)) {
          const name =
            (u.user_metadata?.full_name as string | undefined) ||
            (u.user_metadata?.name as string | undefined) ||
            u.email ||
            null;
          if (name) metaMap[u.id] = name;
          console.log(`[API/admin/profiles] auth meta for ${u.id}:`, u.user_metadata);
        }
      }
    }
  }

  const merged = (profiles ?? []).map((p) => ({
    id: p.id,
    full_name: p.full_name || metaMap[p.id] || null,
    avatar_url: p.avatar_url,
  }));

  console.log('[API/admin/profiles] sample merged profiles:', JSON.stringify(merged.slice(0, 3)));

  return NextResponse.json(merged);
}
