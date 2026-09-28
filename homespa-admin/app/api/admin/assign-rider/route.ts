import { NextRequest, NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

export async function POST(req: NextRequest) {
  const { riderId, bookingId } = await req.json();
  if (!riderId || !bookingId) {
    return NextResponse.json({ error: 'Missing riderId or bookingId' }, { status: 400 });
  }

  const supabase = createAdminClient();

  const { data: active } = await supabase
    .from('rider_assignments')
    .select('id')
    .eq('rider_id', riderId)
    .eq('status', 'on_the_way')
    .maybeSingle();

  if (active) {
    return NextResponse.json(
      { error: 'This rider is currently on the way and cannot be assigned to another booking.' },
      { status: 409 }
    );
  }

  const { error: bookingError } = await supabase
    .from('bookings')
    .update({ rider_id: riderId })
    .eq('id', bookingId);

  if (bookingError) {
    console.error('[assign-rider] bookings update error:', bookingError);
    return NextResponse.json({ error: bookingError.message }, { status: 400 });
  }

  const { error: assignError } = await supabase
    .from('rider_assignments')
    .insert({ rider_id: riderId, booking_id: bookingId, status: 'assigned', assigned_at: new Date().toISOString() });

  if (assignError) {
    console.error('[assign-rider] rider_assignments insert error:', assignError);
    return NextResponse.json({ error: assignError.message }, { status: 400 });
  }

  console.log(`[assign-rider] rider ${riderId} assigned to booking ${bookingId}`);
  return NextResponse.json({ success: true });
}
