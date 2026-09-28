import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

// GET — list all client profiles with email from auth.users
export async function GET() {
  const supabase = createAdminClient();

  const [profilesRes, authRes] = await Promise.all([
    supabase
      .from('profiles')
      .select('id, full_name, phone, gender, avatar_url, created_at')
      .eq('role', 'client')
      .order('created_at', { ascending: false }),
    supabase.auth.admin.listUsers({ page: 1, perPage: 1000 }),
  ]);

  if (profilesRes.error) {
    return NextResponse.json({ error: profilesRes.error.message }, { status: 500 });
  }

  const emailMap: Record<string, string> = {};
  for (const u of authRes.data?.users ?? []) {
    if (u.email) emailMap[u.id] = u.email;
  }

  const customers = (profilesRes.data ?? []).map((p) => ({
    ...p,
    email: emailMap[p.id] ?? null,
  }));

  return NextResponse.json({ customers });
}

// POST — create a new customer account
export async function POST(req: NextRequest) {
  const { email, full_name, phone, gender } = await req.json();

  if (!email?.trim() || !full_name?.trim()) {
    return NextResponse.json({ error: 'email and full_name are required' }, { status: 400 });
  }

  const supabase = createAdminClient();

  // Generate a temporary password the customer can reset via "Forgot Password"
  const tempPassword =
    Math.random().toString(36).slice(-8) +
    Math.random().toString(36).toUpperCase().slice(-4) +
    '1!';

  const { data: authData, error: authError } = await supabase.auth.admin.createUser({
    email: email.trim(),
    password: tempPassword,
    email_confirm: true,
    user_metadata: { full_name: full_name.trim() },
  });

  if (authError) {
    return NextResponse.json({ error: authError.message }, { status: 400 });
  }

  const userId = authData.user.id;

  // Upsert profile (trigger may or may not have auto-created it)
  const { error: profileError } = await supabase.from('profiles').upsert({
    id: userId,
    role: 'client',
    full_name: full_name.trim(),
    phone: phone?.trim() || null,
    gender: gender || null,
  });

  if (profileError) {
    return NextResponse.json({ error: profileError.message }, { status: 400 });
  }

  return NextResponse.json({ success: true, user_id: userId });
}
