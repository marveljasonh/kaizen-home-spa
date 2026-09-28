'use client';

import { useEffect, useState } from 'react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { CalendarCheck, DollarSign, Users, Clock, AlertCircle, Star } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { formatRupiah, formatDate, STATUS_LABELS, STATUS_COLORS, cn } from '@/lib/utils';
import type { Booking } from '@/types';
import { format, subDays, subMonths } from 'date-fns';
import { useRealtimeTable } from '@/lib/hooks/useRealtimeTable';

type Period = '7d' | '1m' | '1y' | '3y';

interface RevenuePoint {
  day: string;
  revenue: number;
}

const GOLD = '#B08D57';

type SalesTab = 'overall' | 'thisMonth' | 'lastMonth' | 'thisYear';

const SALES_TABS: { value: SalesTab; label: string }[] = [
  { value: 'overall', label: 'Overall' },
  { value: 'thisMonth', label: 'This Month' },
  { value: 'lastMonth', label: 'Last Month' },
  { value: 'thisYear', label: 'This Year' },
];

interface PeriodStats {
  totalRevenue: number;
  totalOrders: number;
  completedOrders: number;
  cancelledOrders: number;
  avgOrderValue: number;
}

interface SalesStats {
  overall: PeriodStats;
  thisMonth: PeriodStats;
  lastMonth: PeriodStats;
  thisYear: PeriodStats;
}

interface TopClient {
  id: string;
  full_name: string;
  order_count: number;
  total_spent: number;
}

interface TopTherapist {
  id: string;
  full_name: string;
  rating_avg: number;
  completed_orders: number;
}

const PERIODS: { value: Period; label: string }[] = [
  { value: '7d', label: 'Last 7 days' },
  { value: '1m', label: 'Last month' },
  { value: '1y', label: 'Last year' },
  { value: '3y', label: 'Last 3 years' },
];

function getPeriodStart(period: Period, now: Date): Date {
  switch (period) {
    case '7d': return subDays(now, 7);
    case '1m': return subDays(now, 30);
    case '1y': return subMonths(now, 12);
    case '3y': return subMonths(now, 36);
  }
}

function withTimeout<T>(promise: Promise<T>, ms: number, label: string): Promise<T> {
  return Promise.race([
    promise,
    new Promise<never>((_, reject) =>
      setTimeout(() => reject(new Error(`Timed out after ${ms / 1000}s (${label})`)), ms)
    ),
  ]);
}

function buildChartData(
  rows: Array<{ total_amount: number; scheduled_at: string }>,
  period: Period,
  now: Date
): RevenuePoint[] {
  const buckets = new Map<string, number>();

  if (period === '7d') {
    for (let i = 6; i >= 0; i--) {
      buckets.set(format(subDays(now, i), 'dd/MM'), 0);
    }
    for (const r of rows) {
      const key = format(new Date(r.scheduled_at), 'dd/MM');
      if (buckets.has(key)) buckets.set(key, (buckets.get(key) ?? 0) + r.total_amount);
    }
  } else if (period === '1m') {
    const weeks: Array<{ label: string; from: Date; to: Date }> = [];
    for (let i = 3; i >= 0; i--) {
      const to = subDays(now, i * 7);
      const from = subDays(now, i * 7 + 6);
      weeks.push({ label: format(from, 'dd/MM'), from, to });
    }
    for (const w of weeks) buckets.set(w.label, 0);
    for (const r of rows) {
      const d = new Date(r.scheduled_at);
      for (const w of weeks) {
        if (d >= w.from && d <= w.to) {
          buckets.set(w.label, (buckets.get(w.label) ?? 0) + r.total_amount);
          break;
        }
      }
    }
  } else if (period === '1y') {
    const months: Array<{ label: string; from: Date; to: Date }> = [];
    for (let i = 11; i >= 0; i--) {
      const d = subMonths(now, i);
      const from = new Date(d.getFullYear(), d.getMonth(), 1);
      const to = new Date(d.getFullYear(), d.getMonth() + 1, 0, 23, 59, 59);
      months.push({ label: format(from, 'MMM yy'), from, to });
    }
    for (const m of months) buckets.set(m.label, 0);
    for (const r of rows) {
      const d = new Date(r.scheduled_at);
      for (const m of months) {
        if (d >= m.from && d <= m.to) {
          buckets.set(m.label, (buckets.get(m.label) ?? 0) + r.total_amount);
          break;
        }
      }
    }
  } else {
    const now2 = new Date(now);
    const currentQStart = new Date(now2.getFullYear(), Math.floor(now2.getMonth() / 3) * 3, 1);
    const quarters: Array<{ label: string; from: Date; to: Date }> = [];
    for (let i = 11; i >= 0; i--) {
      const from = subMonths(currentQStart, i * 3);
      const to = new Date(from.getFullYear(), from.getMonth() + 3, 0, 23, 59, 59);
      const qNum = Math.floor(from.getMonth() / 3) + 1;
      const label = `Q${qNum}'${format(from, 'yy')}`;
      if (!quarters.find((q) => q.label === label)) {
        quarters.push({ label, from, to });
      }
    }
    for (const q of quarters) buckets.set(q.label, 0);
    for (const r of rows) {
      const d = new Date(r.scheduled_at);
      for (const q of quarters) {
        if (d >= q.from && d <= q.to) {
          buckets.set(q.label, (buckets.get(q.label) ?? 0) + r.total_amount);
          break;
        }
      }
    }
  }

  return [...buckets.entries()].map(([day, revenue]) => ({ day, revenue }));
}

export default function DashboardPage() {
  const [period, setPeriod] = useState<Period>('7d');
  const [totalBookings, setTotalBookings] = useState(0);
  const [revenue, setRevenue] = useState(0);
  const [activeTherapists, setActiveTherapists] = useState(0);
  const [pendingOrders, setPendingOrders] = useState(0);
  const [revenueData, setRevenueData] = useState<RevenuePoint[]>([]);
  const [recentBookings, setRecentBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [chartLoading, setChartLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [salesTab, setSalesTab] = useState<SalesTab>('overall');
  const [salesStats, setSalesStats] = useState<SalesStats | null>(null);
  const [topClients, setTopClients] = useState<TopClient[]>([]);
  const [topTherapists, setTopTherapists] = useState<TopTherapist[]>([]);
  const [salesLoading, setSalesLoading] = useState(true);

  useEffect(() => {
    loadData(period);
  }, [period]); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    loadSalesOverview();
  }, []);

  useRealtimeTable('dashboard-realtime', 'bookings', () => {
    loadData(period);
    loadSalesOverview();
  });

  async function loadSalesOverview() {
    setSalesLoading(true);
    try {
      const res = await fetch('/api/admin/dashboard-stats');
      const json = await res.json();
      if (!res.ok || json.error) throw new Error(json.error ?? `HTTP ${res.status}`);
      setSalesStats(json.sales as SalesStats);
      setTopClients((json.topClients as TopClient[]) ?? []);
      setTopTherapists((json.topTherapists as TopTherapist[]) ?? []);
    } catch (err) {
      console.error('[Dashboard] loadSalesOverview error:', err);
    } finally {
      setSalesLoading(false);
    }
  }

  async function loadData(p: Period) {
    if (totalBookings === 0 && revenue === 0) {
      setLoading(true);
    } else {
      setChartLoading(true);
    }
    setError(null);

    const supabase = createClient();
    const now = new Date();
    // Compute period start as WIB midnight (UTC+7), expressed as UTC ISO string
    const psWIB = new Date(getPeriodStart(p, now).getTime() + 7 * 60 * 60 * 1000);
    const periodStart = new Date(
      Date.UTC(psWIB.getUTCFullYear(), psWIB.getUTCMonth(), psWIB.getUTCDate()) - 7 * 60 * 60 * 1000
    ).toISOString();

    try {
      const [
        { count: bookingCount, error: e1 },
        { data: revenueRows, error: e2 },
        { count: therapistCount, error: e3 },
        { count: pendingCount, error: e4 },
        { data: chartRows, error: e5 },
        { data: recent, error: e6 },
      ] = await withTimeout(
        Promise.all([
          supabase
            .from('bookings')
            .select('id', { count: 'exact', head: true })
            .gte('created_at', periodStart),
          supabase
            .from('bookings')
            .select('total_amount')
            .eq('status', 'completed')
            .gte('created_at', periodStart),
          supabase
            .from('therapist_profiles')
            .select('id', { count: 'exact', head: true })
            .eq('is_available', true),
          supabase
            .from('bookings')
            .select('id', { count: 'exact', head: true })
            .eq('status', 'pending'),
          supabase
            .from('bookings')
            .select('total_amount, scheduled_at')
            .eq('status', 'completed')
            .gte('scheduled_at', periodStart)
            .order('scheduled_at'),
          supabase
            .from('bookings')
            .select('*')
            .order('created_at', { ascending: false })
            .limit(8),
        ]),
        10_000,
        'dashboard queries'
      );

      const queryErrors = [e1, e2, e3, e4, e5, e6].filter(Boolean);
      if (queryErrors.length > 0) {
        console.error('[Dashboard] query errors:', queryErrors);
      }

      const totalRevenue = (revenueRows ?? []).reduce(
        (sum, r) => sum + (r.total_amount ?? 0),
        0
      );

      setTotalBookings(bookingCount ?? 0);
      setRevenue(totalRevenue);
      setActiveTherapists(therapistCount ?? 0);
      setPendingOrders(pendingCount ?? 0);
      setRevenueData(buildChartData(chartRows ?? [], p, now));
      setRecentBookings((recent as Booking[]) ?? []);
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to load dashboard data';
      console.error('[Dashboard] loadData error:', msg);
      setError(msg);
    } finally {
      setLoading(false);
      setChartLoading(false);
    }
  }

  const periodLabel = PERIODS.find((x) => x.value === period)?.label ?? '';

  const activeSales = salesStats?.[salesTab] ?? null;
  const salesCards = activeSales
    ? [
        { label: 'Total Revenue', value: formatRupiah(activeSales.totalRevenue), gold: true },
        { label: 'Total Orders', value: activeSales.totalOrders.toLocaleString('id-ID') },
        { label: 'Completed', value: activeSales.completedOrders.toLocaleString('id-ID') },
        { label: 'Cancelled', value: activeSales.cancelledOrders.toLocaleString('id-ID') },
        { label: 'Avg Order Value', value: formatRupiah(activeSales.avgOrderValue), gold: true },
      ]
    : [];

  const kpis = [
    {
      label: 'Total Bookings',
      subtitle: periodLabel,
      value: totalBookings.toLocaleString('id-ID'),
      icon: CalendarCheck,
      iconBg: '#DBEAFE',
      iconColor: '#1D4ED8',
    },
    {
      label: 'Revenue',
      subtitle: `Completed · ${periodLabel}`,
      value: formatRupiah(revenue),
      icon: DollarSign,
      iconBg: '#E8EBE0',
      iconColor: '#4E523B',
    },
    {
      label: 'Active Therapists',
      subtitle: 'Currently available',
      value: activeTherapists.toLocaleString('id-ID'),
      icon: Users,
      iconBg: '#F3E8FF',
      iconColor: '#7C3AED',
    },
    {
      label: 'Pending Orders',
      subtitle: 'Awaiting confirmation',
      value: pendingOrders.toLocaleString('id-ID'),
      icon: Clock,
      iconBg: '#FEF3C7',
      iconColor: '#B45309',
    },
  ];

  if (loading) {
    return (
      <div className="space-y-6">
        <h1 className="text-2xl font-bold" style={{ color: '#2C2C2A' }}>Dashboard</h1>
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="bg-white rounded-xl border p-5 h-24 animate-pulse" style={{ borderColor: '#EBE4D9' }}>
              <div className="h-3 w-24 rounded mb-3" style={{ backgroundColor: '#EBE4D9' }} />
              <div className="h-6 w-32 rounded" style={{ backgroundColor: '#EBE4D9' }} />
            </div>
          ))}
        </div>
        <div className="bg-white rounded-xl border h-72 animate-pulse" style={{ borderColor: '#EBE4D9' }} />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-64 gap-4">
        <AlertCircle className="w-10 h-10 text-red-400" />
        <div className="text-center">
          <p className="font-semibold" style={{ color: '#2C2C2A' }}>Failed to load dashboard</p>
          <p className="text-sm mt-1" style={{ color: '#7A7A72' }}>{error}</p>
        </div>
        <button
          onClick={() => loadData(period)}
          className="px-4 py-2 rounded-lg text-sm font-medium text-white transition-colors"
          style={{ backgroundColor: '#4E523B' }}
          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
        >
          Retry
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-4 flex-wrap">
        <h1 className="text-2xl font-bold" style={{ color: '#2C2C2A' }}>Dashboard</h1>

        <div className="flex items-center gap-1 rounded-lg p-1" style={{ backgroundColor: '#F0ECE5' }}>
          {PERIODS.map(({ value, label }) => (
            <button
              key={value}
              onClick={() => setPeriod(value)}
              className="px-3 py-1.5 rounded-md text-sm font-medium transition-colors"
              style={
                period === value
                  ? { backgroundColor: 'white', color: '#2C2C2A', boxShadow: '0 1px 2px rgba(0,0,0,0.05)' }
                  : { color: '#7A7A72' }
              }
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        {kpis.map(({ label, subtitle, value, icon: Icon, iconBg, iconColor }) => (
          <div
            key={label}
            className="bg-white rounded-xl border shadow-sm p-5 flex items-start gap-4"
            style={{ borderColor: '#EBE4D9' }}
          >
            <div className="p-2.5 rounded-lg flex-shrink-0" style={{ backgroundColor: iconBg }}>
              <Icon className="w-5 h-5" style={{ color: iconColor }} />
            </div>
            <div>
              <p className="text-xs font-medium uppercase tracking-wide" style={{ color: '#7A7A72' }}>
                {label}
              </p>
              <p className="text-xl font-bold mt-0.5 leading-tight" style={{ color: '#2C2C2A' }}>
                {value}
              </p>
              <p className="text-xs mt-0.5" style={{ color: '#9A9A90' }}>
                {subtitle}
              </p>
            </div>
          </div>
        ))}
      </div>

      {/* Revenue Chart */}
      <div className="bg-white rounded-xl border shadow-sm p-5" style={{ borderColor: '#EBE4D9' }}>
        <h2 className="text-base font-semibold mb-4" style={{ color: '#2C2C2A' }}>
          Revenue — {periodLabel}
          {chartLoading && (
            <span className="ml-2 inline-block w-4 h-4 rounded-full border-2 border-t-transparent animate-spin align-middle" style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }} />
          )}
        </h2>
        <ResponsiveContainer width="100%" height={220}>
          <AreaChart data={revenueData} margin={{ top: 4, right: 8, left: 8, bottom: 0 }}>
            <defs>
              <linearGradient id="revenueGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#4E523B" stopOpacity={0.2} />
                <stop offset="95%" stopColor="#4E523B" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#EBE4D9" />
            <XAxis
              dataKey="day"
              tick={{ fontSize: 11, fill: '#9A9A90' }}
              axisLine={false}
              tickLine={false}
            />
            <YAxis
              tick={{ fontSize: 11, fill: '#9A9A90' }}
              axisLine={false}
              tickLine={false}
              tickFormatter={(v) =>
                v >= 1_000_000
                  ? `${(v / 1_000_000).toFixed(1)}jt`
                  : v >= 1_000
                  ? `${(v / 1_000).toFixed(0)}rb`
                  : String(v)
              }
            />
            <Tooltip
              formatter={(value) => [formatRupiah(Number(value ?? 0)), 'Revenue']}
              contentStyle={{
                backgroundColor: '#2C2C2A',
                border: 'none',
                borderRadius: '8px',
                color: '#FAF7F2',
                fontSize: 12,
              }}
            />
            <Area
              type="monotone"
              dataKey="revenue"
              stroke="#4E523B"
              strokeWidth={2}
              fill="url(#revenueGrad)"
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>

      {/* Sales Overview */}
      <div className="bg-white rounded-xl border shadow-sm p-5" style={{ borderColor: '#EBE4D9' }}>
        <div className="flex items-center justify-between gap-4 flex-wrap mb-4">
          <h2 className="text-base font-semibold" style={{ color: '#2C2C2A' }}>
            Sales Overview
          </h2>
          <div className="flex items-center gap-1 rounded-lg p-1" style={{ backgroundColor: '#F0ECE5' }}>
            {SALES_TABS.map(({ value, label }) => (
              <button
                key={value}
                onClick={() => setSalesTab(value)}
                className="px-3 py-1.5 rounded-md text-sm font-medium transition-colors"
                style={
                  salesTab === value
                    ? { backgroundColor: '#4E523B', color: 'white' }
                    : { backgroundColor: 'transparent', color: '#7A7A72' }
                }
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        {salesLoading || !activeSales ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="rounded-lg border p-4 h-[68px] animate-pulse" style={{ borderColor: '#EBE4D9' }}>
                <div className="h-3 w-20 rounded mb-3" style={{ backgroundColor: '#EBE4D9' }} />
                <div className="h-5 w-24 rounded" style={{ backgroundColor: '#EBE4D9' }} />
              </div>
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
            {salesCards.map((c) => (
              <div key={c.label} className="rounded-lg border p-4" style={{ borderColor: '#EBE4D9' }}>
                <p className="text-xs font-medium uppercase tracking-wide" style={{ color: '#7A7A72' }}>
                  {c.label}
                </p>
                <p className="text-lg font-bold mt-1" style={{ color: c.gold ? GOLD : '#2C2C2A' }}>
                  {c.value}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Top Clients & Top Therapists */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="bg-white rounded-xl border shadow-sm" style={{ borderColor: '#EBE4D9' }}>
          <div className="px-5 py-4 border-b" style={{ borderColor: '#EBE4D9' }}>
            <h2 className="text-base font-semibold" style={{ color: '#2C2C2A' }}>Top Clients</h2>
          </div>
          <div className="p-2">
            {salesLoading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="flex items-center gap-3 px-3 py-2.5 animate-pulse">
                  <div className="w-7 h-7 rounded-full flex-shrink-0" style={{ backgroundColor: '#EBE4D9' }} />
                  <div className="h-3 flex-1 rounded" style={{ backgroundColor: '#EBE4D9' }} />
                </div>
              ))
            ) : topClients.length === 0 ? (
              <p className="text-sm text-center py-8" style={{ color: '#9A9A90' }}>No client data yet</p>
            ) : (
              topClients.map((c, i) => (
                <div
                  key={c.id}
                  className="flex items-center justify-between gap-3 px-3 py-2.5 rounded-lg transition-colors"
                  onMouseEnter={(e) => { (e.currentTarget as HTMLDivElement).style.backgroundColor = '#FAF7F2'; }}
                  onMouseLeave={(e) => { (e.currentTarget as HTMLDivElement).style.backgroundColor = 'transparent'; }}
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <span
                      className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 text-xs font-bold text-white"
                      style={{ backgroundColor: '#4E523B' }}
                    >
                      {i + 1}
                    </span>
                    <div className="min-w-0">
                      <p className="text-sm font-medium truncate" style={{ color: '#2C2C2A' }}>{c.full_name}</p>
                      <p className="text-xs" style={{ color: '#9A9A90' }}>
                        {c.order_count} {c.order_count === 1 ? 'order' : 'orders'}
                      </p>
                    </div>
                  </div>
                  <p className="text-sm font-semibold flex-shrink-0" style={{ color: GOLD }}>
                    {formatRupiah(c.total_spent)}
                  </p>
                </div>
              ))
            )}
          </div>
        </div>

        <div className="bg-white rounded-xl border shadow-sm" style={{ borderColor: '#EBE4D9' }}>
          <div className="px-5 py-4 border-b" style={{ borderColor: '#EBE4D9' }}>
            <h2 className="text-base font-semibold" style={{ color: '#2C2C2A' }}>Top Therapists</h2>
          </div>
          <div className="p-2">
            {salesLoading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="flex items-center gap-3 px-3 py-2.5 animate-pulse">
                  <div className="w-7 h-7 rounded-full flex-shrink-0" style={{ backgroundColor: '#EBE4D9' }} />
                  <div className="h-3 flex-1 rounded" style={{ backgroundColor: '#EBE4D9' }} />
                </div>
              ))
            ) : topTherapists.length === 0 ? (
              <p className="text-sm text-center py-8" style={{ color: '#9A9A90' }}>No therapist data yet</p>
            ) : (
              topTherapists.map((t, i) => (
                <div
                  key={t.id}
                  className="flex items-center justify-between gap-3 px-3 py-2.5 rounded-lg transition-colors"
                  onMouseEnter={(e) => { (e.currentTarget as HTMLDivElement).style.backgroundColor = '#FAF7F2'; }}
                  onMouseLeave={(e) => { (e.currentTarget as HTMLDivElement).style.backgroundColor = 'transparent'; }}
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <span
                      className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 text-xs font-bold text-white"
                      style={{ backgroundColor: '#4E523B' }}
                    >
                      {i + 1}
                    </span>
                    <div className="min-w-0">
                      <p className="text-sm font-medium truncate" style={{ color: '#2C2C2A' }}>{t.full_name}</p>
                      <p className="text-xs flex items-center gap-1" style={{ color: '#9A9A90' }}>
                        <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                        {t.rating_avg.toFixed(1)}
                      </p>
                    </div>
                  </div>
                  <p className="text-sm font-semibold flex-shrink-0" style={{ color: '#2C2C2A' }}>
                    {t.completed_orders} completed
                  </p>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* Recent Bookings */}
      <div className="bg-white rounded-xl border shadow-sm" style={{ borderColor: '#EBE4D9' }}>
        <div className="px-5 py-4 border-b" style={{ borderColor: '#EBE4D9' }}>
          <h2 className="text-base font-semibold" style={{ color: '#2C2C2A' }}>
            Recent Bookings
          </h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr style={{ backgroundColor: '#FAF7F2' }}>
                <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>ID</th>
                <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Scheduled</th>
                <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Status</th>
                <th className="text-right px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Total</th>
              </tr>
            </thead>
            <tbody>
              {recentBookings.length === 0 && (
                <tr>
                  <td colSpan={4} className="px-5 py-8 text-center" style={{ color: '#9A9A90' }}>
                    No bookings found
                  </td>
                </tr>
              )}
              {recentBookings.map((b) => (
                <tr key={b.id} className="border-t transition-colors" style={{ borderColor: '#EBE4D9' }}
                  onMouseEnter={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = '#FAF7F2'; }}
                  onMouseLeave={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = 'transparent'; }}
                >
                  <td className="px-5 py-3 font-mono text-xs" style={{ color: '#5A5A52' }}>
                    #{b.id.slice(0, 8).toUpperCase()}
                  </td>
                  <td className="px-5 py-3" style={{ color: '#3D3D38' }}>
                    {formatDate(b.scheduled_at, true)}
                  </td>
                  <td className="px-5 py-3">
                    <span className={cn('inline-flex px-2 py-0.5 rounded-full text-xs font-medium', STATUS_COLORS[b.status] ?? '')}>
                      {STATUS_LABELS[b.status] ?? b.status}
                    </span>
                  </td>
                  <td className="px-5 py-3 text-right font-medium" style={{ color: '#2C2C2A' }}>
                    {formatRupiah(b.total_amount)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
