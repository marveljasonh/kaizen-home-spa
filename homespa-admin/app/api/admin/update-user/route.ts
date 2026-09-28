import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

export async function GET(req: NextRequest) {
  const userId = new URL(req.url).searchParams.get('userId');
  if (!userId) {
    return NextResponse.json({ error: 'userId is required' }, { status: 400 });
  }

  const supabase = createAdminClient();
  const { data, error } = await supabase.auth.admin.getUserById(userId);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  return NextResponse.json({ email: data.user.email ?? null });
}

export async function PATCH(req: NextRequest) {
  const { userId, email, password } = await req.json();

  if (!userId) {
    return NextResponse.json({ error: 'userId is required' }, { status: 400 });
  }

  if (password && password.length < 6) {
    return NextResponse.json({ error: 'Password must be at least 6 characters' }, { status: 400 });
  }

  const updates: { email?: string; password?: string } = {};
  if (email !== undefined) updates.email = email;
  if (password) updates.password = password;

  if (Object.keys(updates).length === 0) {
    return NextResponse.json({ error: 'Nothing to update' }, { status: 400 });
  }

  const supabase = createAdminClient();
  const { error } = await supabase.auth.admin.updateUserById(userId, updates);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  return NextResponse.json({ success: true });
}
