import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

export async function DELETE(req: NextRequest) {
  const { userId } = await req.json();

  if (!userId) {
    return NextResponse.json({ error: 'userId is required' }, { status: 400 });
  }

  const supabase = createAdminClient();

  // Deletes the auth user; cascade trigger removes the profiles row
  const { error } = await supabase.auth.admin.deleteUser(userId);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  return NextResponse.json({ success: true });
}
