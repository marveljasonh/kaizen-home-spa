import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

export async function POST(req: NextRequest) {
  const { therapistProfileId } = await req.json();
  if (!therapistProfileId) {
    return NextResponse.json({ error: 'therapistProfileId required' }, { status: 400 });
  }

  const supabase = createAdminClient();

  const { data, error } = await supabase
    .from('therapist_reviews')
    .select('id, rating, review_text, client_id, created_at')
    .eq('therapist_id', therapistProfileId)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('[therapist-reviews] query error:', error.message);
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  const rows = data ?? [];

  // Resolve client names via admin client (bypasses RLS on profiles)
  const clientIds = [...new Set(rows.map((r) => r.client_id).filter(Boolean))];
  const nameMap: Record<string, string> = {};

  if (clientIds.length > 0) {
    const { data: profiles } = await supabase
      .from('profiles')
      .select('id, full_name')
      .in('id', clientIds);

    for (const p of profiles ?? []) {
      if (p.full_name) nameMap[p.id] = p.full_name;
    }

    // Fall back to auth.users metadata for any still-missing names
    const missingIds = clientIds.filter((id) => !nameMap[id]);
    if (missingIds.length > 0) {
      const { data: authUsers } = await supabase.auth.admin.listUsers();
      for (const u of authUsers?.users ?? []) {
        if (missingIds.includes(u.id)) {
          nameMap[u.id] =
            (u.user_metadata?.full_name as string | undefined) ??
            (u.user_metadata?.name as string | undefined) ??
            u.email ??
            'Anonymous';
        }
      }
    }
  }

  const reviews = rows.map((r) => ({
    id: r.id,
    rating: r.rating as number,
    review_text: r.review_text as string | null,
    client_name: nameMap[r.client_id] ?? 'Anonymous',
    created_at: r.created_at as string,
  }));

  return NextResponse.json({ reviews });
}
