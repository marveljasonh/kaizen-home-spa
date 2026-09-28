import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

export async function POST(req: NextRequest) {
  const { email, password, full_name, phone } = await req.json();

  if (!email || !password || !full_name) {
    return NextResponse.json({ error: 'email, password, and full_name are required' }, { status: 400 });
  }

  if (password.length < 6) {
    return NextResponse.json({ error: 'Password must be at least 6 characters' }, { status: 400 });
  }

  const supabase = createAdminClient();

  // 1. Create auth user (confirmed immediately, no email verification needed)
  const { data: authData, error: authError } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name },
  });

  if (authError) {
    console.error('[create-rider] auth.createUser error:', authError.message);
    return NextResponse.json({ error: authError.message }, { status: 400 });
  }

  const userId = authData.user.id;

  // 2. Auth trigger auto-creates the profiles row; update role, name, and phone
  const { error: profileError } = await supabase
    .from('profiles')
    .update({ role: 'rider', full_name, phone: phone || null })
    .eq('id', userId);

  if (profileError) {
    console.error('[create-rider] profiles.update error:', profileError.message);
    return NextResponse.json({ error: profileError.message }, { status: 400 });
  }

  // 3. Insert rider_profiles row (vehicle details can be filled in later via edit)
  const { error: rpError } = await supabase.from('rider_profiles').insert({
    profile_id: userId,
    is_available: true,
  });

  if (rpError) {
    // rider_profiles may not exist yet — log but don't fail the whole request
    console.warn('[create-rider] rider_profiles.insert warning:', rpError.message);
  }

  return NextResponse.json({ success: true, user_id: userId });
}
