import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

export async function POST(req: NextRequest) {
  const { bookingId, clientId } = await req.json();
  console.log('[booking-detail] bookingId:', bookingId, 'clientId:', clientId);
  if (!bookingId) return NextResponse.json({ error: 'Missing bookingId' }, { status: 400 });

  const supabase = createAdminClient();

  // Debug: confirm the table has data and the service role key can read it
  const { data: sampleIds, error: sampleError } = await supabase
    .from('booking_items')
    .select('booking_id')
    .limit(5);
  console.log('[booking-detail] sample booking_ids in table:', JSON.stringify(sampleIds), 'error:', JSON.stringify(sampleError));

  const { data: rawItems, error: itemsError } = await supabase
    .from('booking_items')
    .select('*')
    .eq('booking_id', bookingId);

  console.log('[booking-detail] rawItems count:', rawItems?.length ?? 0, 'error:', JSON.stringify(itemsError));
  console.log('[booking-detail] rawItems full:', JSON.stringify(rawItems));

  const { data: rawAddons, error: addonsError } = await supabase
    .from('booking_addons')
    .select('*')
    .eq('booking_id', bookingId);

  console.log('[booking-detail] rawAddons count:', rawAddons?.length ?? 0, 'error:', JSON.stringify(addonsError));
  console.log('[booking-detail] rawAddons full:', JSON.stringify(rawAddons));

  const items = (rawItems ?? []).map((item) => {
    const snap = (item.treatment_snapshot ?? {}) as Record<string, unknown>;
    console.log('[booking-detail] item raw:', JSON.stringify(item));
    console.log('[booking-detail] item snapshot:', JSON.stringify(snap));
    const name =
      (snap.treatment_name as string) ||
      (snap.name as string) ||
      (item.treatment_name as string) ||
      'Unknown treatment';
    return {
      name,
      duration_minutes: (snap.duration_minutes as number) ?? 0,
      price: (item.unit_price as number) ?? 0,
      quantity: (item.quantity as number) ?? 1,
    };
  });

  const addons = (rawAddons ?? []).map((addon) => {
    const snap = (addon.addon_snapshot ?? {}) as Record<string, unknown>;
    return {
      name: (snap.addon_name as string) ?? 'Unknown add-on',
      price: (addon.unit_price as number) ?? 0,
      quantity: (addon.quantity as number) ?? 1,
    };
  });

  // Fetch client contact info, therapist review, and reward redemptions in parallel
  let client: { email: string | null; phone: string | null } = { email: null, phone: null };
  let review: { rating: number; review_text: string | null; created_at: string } | null = null;

  const [clientResult, reviewResult, redemptionResult] = await Promise.all([
    clientId
      ? Promise.all([
          supabase.from('profiles').select('phone').eq('id', clientId).single(),
          supabase.auth.admin.getUserById(clientId),
        ])
      : Promise.resolve(null),
    supabase
      .from('therapist_reviews')
      .select('rating, review_text, created_at')
      .eq('booking_id', bookingId)
      .maybeSingle(),
    supabase
      .from('reward_redemptions')
      .select('id', { count: 'exact', head: true })
      .eq('booking_id', bookingId),
  ]);

  if (clientResult) {
    const [profileResult, authResult] = clientResult;
    client = {
      phone: (profileResult.data as { phone: string | null } | null)?.phone ?? null,
      email: authResult.data?.user?.email ?? null,
    };
  }

  if (reviewResult.data) {
    review = {
      rating: reviewResult.data.rating as number,
      review_text: reviewResult.data.review_text as string | null,
      created_at: reviewResult.data.created_at as string,
    };
  }

  const hasFreeReward = (redemptionResult.count ?? 0) > 0;

  // Fetch latest rider assignment for this booking
  let rider: { name: string | null; assignmentStatus: string } | null = null;
  const { data: assignment } = await supabase
    .from('rider_assignments')
    .select('rider_id, status')
    .eq('booking_id', bookingId)
    .order('assigned_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (assignment) {
    const { data: riderProfile } = await supabase
      .from('profiles')
      .select('full_name')
      .eq('id', assignment.rider_id as string)
      .single();
    rider = {
      name: (riderProfile as { full_name: string | null } | null)?.full_name ?? null,
      assignmentStatus: assignment.status as string,
    };
  }

  return NextResponse.json({ items, addons, client, review, rider, hasFreeReward });
}
