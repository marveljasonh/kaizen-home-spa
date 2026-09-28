import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

export async function POST(req: NextRequest) {
  const { email, password, full_name, bio, specialties, branch_id, is_available } = await req.json();

  if (!email || !password || !full_name) {
    return NextResponse.json({ error: 'email, password, and full_name are required' }, { status: 400 });
  }

  if (password.length < 6) {
    return NextResponse.json({ error: 'Password must be at least 6 characters' }, { status: 400 });
  }

  const supabase = createAdminClient();

  // 1. Create auth user with password (confirmed immediately)
  const { data: authData, error: authError } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name },
  });

  if (authError) {
    console.error('[create-therapist] auth.createUser error:', authError.message);
    return NextResponse.json({ error: authError.message }, { status: 400 });
  }

  const userId = authData.user.id;

  // 2. Trigger auto-creates the profiles row; update role and full_name
  const { error: profileError } = await supabase
    .from('profiles')
    .update({ role: 'therapist', full_name })
    .eq('id', userId);

  if (profileError) {
    console.error('[create-therapist] profiles.update error:', profileError.message);
    return NextResponse.json({ error: profileError.message }, { status: 400 });
  }

  // 3. Insert therapist_profiles row
  const { error: tpError } = await supabase.from('therapist_profiles').insert({
    profile_id: userId,
    branch_id: branch_id || null,
    bio: bio || null,
    specialties: specialties ?? [],
    is_available: is_available ?? true,
  });

  if (tpError) {
    console.error('[create-therapist] therapist_profiles.insert error:', tpError.message);
    return NextResponse.json({ error: tpError.message }, { status: 400 });
  }

  return NextResponse.json({ success: true, user_id: userId });
}
