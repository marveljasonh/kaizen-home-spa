import { NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

export async function POST(req: Request) {
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 });
  }

  const { table, operation, payload, match } = body as {
    table: string;
    operation: 'insert' | 'update' | 'delete';
    payload?: Record<string, unknown>;
    match?: Record<string, unknown>;
  };

  if (!table || !operation) {
    return NextResponse.json({ error: 'table and operation are required' }, { status: 400 });
  }

  const supabase = createAdminClient();
  let result: { data: unknown; error: { message: string } | null };

  if (operation === 'insert') {
    if (!payload) {
      return NextResponse.json({ error: 'Payload is required' }, { status: 400 });
    }
    result = await supabase.from(table).insert(payload).select();
  } else if (operation === 'update') {
    if (!payload) {
      return NextResponse.json({ error: 'Payload is required' }, { status: 400 });
    }
    let q = supabase.from(table).update(payload);
    for (const [k, v] of Object.entries(match ?? {})) {
      q = q.eq(k, v as string);
    }
    result = await q.select();
  } else if (operation === 'delete') {
    let q = supabase.from(table).delete();
    for (const [k, v] of Object.entries(match ?? {})) {
      q = q.eq(k, v as string);
    }
    result = await q;
  } else {
    return NextResponse.json({ error: `Unknown operation: ${operation}` }, { status: 400 });
  }

  if (result.error) {
    console.error(`[admin/mutate] ${operation} ${table}:`, result.error);
    return NextResponse.json({ error: result.error.message }, { status: 400 });
  }

  console.log(`[admin/mutate] ${operation} ${table} OK`);
  return NextResponse.json({ data: result.data });
}
