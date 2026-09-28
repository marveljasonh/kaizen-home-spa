import { NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/admin';

interface PeriodStats {
  totalRevenue: number;
  totalOrders: number;
  completedOrders: number;
  cancelledOrders: number;
  avgOrderValue: number;
}

interface BookingRow {
  status: string;
  total_amount: number;
  scheduled_at: string;
  client_id: string | null;
  therapist_id: string | null;
}

function computeStats(rows: BookingRow[]): PeriodStats {
  const totalOrders = rows.length;
  const completedOrders = rows.filter((r) => r.status === 'completed').length;
  const cancelledOrders = rows.filter((r) => r.status === 'cancelled').length;
  const totalRevenue = rows
    .filter((r) => r.status !== 'cancelled')
    .reduce((sum, r) => sum + (r.total_amount ?? 0), 0);
  const avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;
  return { totalRevenue, totalOrders, completedOrders, cancelledOrders, avgOrderValue };
}

// WIB (UTC+7) midnight for a given UTC-field-expressed calendar date
function wibDate(y: number, m: number, d: number): Date {
  return new Date(Date.UTC(y, m, d, 0, 0, 0) - 7 * 60 * 60 * 1000);
}

function nowWIBParts(now: Date) {
  const shifted = new Date(now.getTime() + 7 * 60 * 60 * 1000);
  return { y: shifted.getUTCFullYear(), m: shifted.getUTCMonth() };
}

export async function GET() {
  const supabase = createAdminClient();

  const { data, error } = await supabase
    .from('bookings')
    .select('status, total_amount, scheduled_at, client_id, therapist_id');

  if (error) {
    console.error('[dashboard-stats] bookings query error:', error.message);
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  const rows = (data ?? []) as BookingRow[];

  const now = new Date();
  const { y, m } = nowWIBParts(now);
  const startOfThisMonth = wibDate(y, m, 1);
  const startOfLastMonth = wibDate(y, m - 1, 1);
  const startOfThisYear = wibDate(y, 0, 1);

  const scheduledAt = (r: BookingRow) => new Date(r.scheduled_at);

  const sales = {
    overall: computeStats(rows),
    thisMonth: computeStats(rows.filter((r) => scheduledAt(r) >= startOfThisMonth)),
    lastMonth: computeStats(
      rows.filter((r) => scheduledAt(r) >= startOfLastMonth && scheduledAt(r) < startOfThisMonth)
    ),
    thisYear: computeStats(rows.filter((r) => scheduledAt(r) >= startOfThisYear)),
  };

  // Top 5 clients by order count (non-cancelled bookings)
  const clientAgg = new Map<string, { order_count: number; total_spent: number }>();
  for (const r of rows) {
    if (!r.client_id || r.status === 'cancelled') continue;
    const cur = clientAgg.get(r.client_id) ?? { order_count: 0, total_spent: 0 };
    cur.order_count += 1;
    cur.total_spent += r.total_amount ?? 0;
    clientAgg.set(r.client_id, cur);
  }
  const topClientEntries = [...clientAgg.entries()]
    .sort((a, b) => b[1].order_count - a[1].order_count)
    .slice(0, 5);

  const clientIds = topClientEntries.map(([id]) => id);
  const { data: clientProfiles } = clientIds.length
    ? await supabase.from('profiles').select('id, full_name').in('id', clientIds)
    : { data: [] };
  const clientNameMap = Object.fromEntries(
    (clientProfiles ?? []).map((p) => [p.id, p.full_name as string | null])
  );

  const topClients = topClientEntries.map(([id, agg]) => ({
    id,
    full_name: clientNameMap[id] ?? 'Unknown',
    order_count: agg.order_count,
    total_spent: agg.total_spent,
  }));

  // Top 5 therapists by completed order count
  const therapistAgg = new Map<string, number>();
  for (const r of rows) {
    if (!r.therapist_id || r.status !== 'completed') continue;
    therapistAgg.set(r.therapist_id, (therapistAgg.get(r.therapist_id) ?? 0) + 1);
  }
  const topTherapistEntries = [...therapistAgg.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);

  // bookings.therapist_id stores the therapist's profile id (same as client_id),
  // not therapist_profiles.id — so both lookups key off profile id.
  const therapistProfileIds = topTherapistEntries.map(([id]) => id);
  const { data: therapistProfiles } = therapistProfileIds.length
    ? await supabase
        .from('therapist_profiles')
        .select('profile_id, rating_avg')
        .in('profile_id', therapistProfileIds)
    : { data: [] };
  const ratingMap = Object.fromEntries(
    (therapistProfiles ?? []).map((tp) => [tp.profile_id as string, tp.rating_avg as number | null])
  );

  const { data: therapistUserProfiles } = therapistProfileIds.length
    ? await supabase.from('profiles').select('id, full_name').in('id', therapistProfileIds)
    : { data: [] };
  const therapistNameMap = Object.fromEntries(
    (therapistUserProfiles ?? []).map((p) => [p.id, p.full_name as string | null])
  );

  const topTherapists = topTherapistEntries.map(([id, count]) => ({
    id,
    full_name: therapistNameMap[id] ?? 'Unknown',
    rating_avg: ratingMap[id] ?? 0,
    completed_orders: count,
  }));

  return NextResponse.json({ sales, topClients, topTherapists });
}
