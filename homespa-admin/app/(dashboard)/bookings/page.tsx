'use client';

import { useEffect, useState } from 'react';
import {
  ChevronLeft,
  ChevronRight,
  ChevronDown,
  ChevronUp,
  UserCheck,
  X,
  Star,
  Mail,
  Phone,
  MapPin,
  Bike,
  MessageCircle,
  Gift,
} from 'lucide-react';
import toast from 'react-hot-toast';
import { createClient } from '@/lib/supabase/client';
import { adminMutate } from '@/lib/adminMutate';
import { useRealtimeTable } from '@/lib/hooks/useRealtimeTable';
import {
  cn,
  formatRupiah,
  formatDate,
  STATUS_LABELS,
  STATUS_COLORS,
} from '@/lib/utils';
import { formatWIBDate } from '@/lib/utils/wib';
import type { Booking, BookingStatus, Profile, TherapistProfile, RiderProfile } from '@/types';

const DEFAULT_PAGE_SIZE = 10;

const ALL_STATUSES: BookingStatus[] = [
  'pending',
  'accepted',
  'therapist_assigned',
  'on_the_way',
  'arrived',
  'in_progress',
  'completed',
  'cancelled',
];

// ── Date range ───────────────────────────────────────────────────────────────
type DateRangeKey = 'all' | 'today' | 'week' | 'month' | 'year';
interface DateRangeDef { key: DateRangeKey; label: string; }
const DATE_RANGES: DateRangeDef[] = [
  { key: 'all',   label: 'All' },
  { key: 'today', label: 'Today' },
  { key: 'week',  label: 'This Week' },
  { key: 'month', label: 'This Month' },
  { key: 'year',  label: 'This Year' },
];
function getDateRange(key: DateRangeKey): { gte: string; lt: string } | null {
  if (key === 'all') return null;
  // Determine today's date in WIB (UTC+7)
  const nowWIB = new Date(Date.now() + 7 * 60 * 60 * 1000);
  const y = nowWIB.getUTCFullYear(), m = nowWIB.getUTCMonth(), d = nowWIB.getUTCDate();
  // Midnight WIB as a UTC ISO string (midnight WIB = UTC−7 h)
  const wibMid = (yw: number, mw: number, dw: number) =>
    new Date(Date.UTC(yw, mw, dw) - 7 * 60 * 60 * 1000).toISOString();
  if (key === 'today') return { gte: wibMid(y, m, d),    lt: wibMid(y, m, d + 1) };
  if (key === 'week')  { const dow = nowWIB.getUTCDay(); return { gte: wibMid(y, m, d - dow), lt: wibMid(y, m, d - dow + 7) }; }
  if (key === 'month') return { gte: wibMid(y, m, 1),    lt: wibMid(y, m + 1, 1) };
  if (key === 'year')  return { gte: wibMid(y, 0, 1),    lt: wibMid(y + 1, 0, 1) };
  return null;
}

// ── Tab bar ───────────────────────────────────────────────────────────────────
type TabKey = 'all' | 'new_open' | 'assigned' | 'on_progress' | 'closed' | 'cancelled' | 'pending';
interface TabDef { key: TabKey; label: string; statuses: string[]; }
const TABS: TabDef[] = [
  { key: 'all',         label: 'All',         statuses: [] },
  { key: 'new_open',    label: 'New/Open',    statuses: ['pending', 'accepted', 'new'] },
  { key: 'assigned',    label: 'Assigned',    statuses: ['therapist_assigned', 'assigned'] },
  { key: 'on_progress', label: 'On Progress', statuses: ['in_progress', 'on_the_way', 'arrived'] },
  { key: 'closed',      label: 'Closed',      statuses: ['completed'] },
  { key: 'cancelled',   label: 'Cancelled',   statuses: ['cancelled'] },
  { key: 'pending',     label: 'Pending',     statuses: ['pending'] },
];

// ── Types ─────────────────────────────────────────────────────────────────────
interface TreatmentLine { name: string; duration_minutes: number; price: number; quantity: number; }
interface AddonLine { name: string; price: number; quantity: number; }
interface ClientContact { email: string | null; phone: string | null; }
interface BookingReview { rating: number; review_text: string | null; created_at: string; }
interface RiderInfo { name: string | null; assignmentStatus: string; }
interface DetailEntry {
  loading: boolean;
  items: TreatmentLine[];
  addons: AddonLine[];
  client: ClientContact | null;
  review: BookingReview | null;
  rider: RiderInfo | null;
  hasFreeReward: boolean;
}

// ── Helpers ───────────────────────────────────────────────────────────────────
const parseAddress = (snapshot: string | null): string => {
  if (!snapshot) return 'No address';
  try {
    const parsed = JSON.parse(snapshot);
    return parsed.address_line || parsed.label || parsed.address || snapshot;
  } catch {
    return snapshot;
  }
};

function getInitials(name: string): string {
  return name.split(' ').filter(Boolean).slice(0, 2).map((w) => w[0].toUpperCase()).join('');
}

const AVATAR_COLORS = [
  'bg-blue-500', 'bg-purple-500', 'bg-pink-500', 'bg-orange-500',
  'bg-teal-500', 'bg-indigo-500', 'bg-rose-500', 'bg-cyan-500',
];

function avatarColor(name: string): string {
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

// ── CustomerAvatar ────────────────────────────────────────────────────────────
function CustomerAvatar({ name, avatarUrl, clientId }: { name: string | null; avatarUrl: string | null; clientId: string }) {
  const hasName = name && name.trim();
  const displayName = hasName ? name!.trim() : `Customer ${clientId.slice(0, 6).toUpperCase()}`;
  const initials = getInitials(displayName);
  return (
    <div className="flex items-center gap-2.5 min-w-0">
      {avatarUrl ? (
        <img src={avatarUrl} alt={displayName} className="w-7 h-7 rounded-full object-cover flex-shrink-0" />
      ) : (
        <span className={cn('w-7 h-7 rounded-full flex-shrink-0 flex items-center justify-center text-white text-xs font-semibold', avatarColor(displayName))}>
          {initials}
        </span>
      )}
      <span className={cn('truncate text-sm', hasName ? '' : 'font-mono')} style={{ color: hasName ? '#2C2C2A' : '#9A9A90' }}>
        {displayName}
      </span>
    </div>
  );
}

// ── AssignTherapistModal ──────────────────────────────────────────────────────
interface TherapistWithStatus extends TherapistProfile { status: string | null; }

function AvailabilityBadge({ isAvailable, status }: { isAvailable: boolean; status?: string | null }) {
  if (status === 'off')
    return <span className="inline-flex items-center gap-1 text-xs font-medium" style={{ color: '#7A7A72' }}><span className="w-1.5 h-1.5 rounded-full flex-shrink-0" style={{ backgroundColor: '#9A9A90' }} />Day Off</span>;
  if (status === 'break')
    return <span className="inline-flex items-center gap-1 text-xs font-medium" style={{ color: '#B45309' }}><span className="w-1.5 h-1.5 rounded-full flex-shrink-0 bg-orange-400" />On Break</span>;
  if (isAvailable)
    return <span className="inline-flex items-center gap-1 text-xs font-medium" style={{ color: '#4E523B' }}><span className="w-1.5 h-1.5 rounded-full flex-shrink-0" style={{ backgroundColor: '#4E523B' }} />Available</span>;
  return <span className="inline-flex items-center gap-1 text-xs font-medium" style={{ color: '#7A7A72' }}><span className="w-1.5 h-1.5 rounded-full flex-shrink-0" style={{ backgroundColor: '#9A9A90' }} />Unavailable</span>;
}

const ACTIVE_STATUSES = ['pending', 'accepted', 'therapist_assigned', 'rider_assigned', 'on_the_way', 'arrived', 'in_progress'];

function AssignTherapistModal({
  booking,
  onClose,
  onAssigned,
}: {
  booking: Booking;
  onClose: () => void;
  onAssigned: () => void;
}) {
  const [therapists, setTherapists] = useState<TherapistWithStatus[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedId, setSelectedId] = useState<string | null>(booking.therapist_id);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [conflictWarning, setConflictWarning] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      const supabase = createClient();
      const { data } = await supabase
        .from('therapist_profiles')
        .select('id, profile_id, branch_id, bio, rating_avg, total_reviews, is_available, status, profile:profiles(full_name, avatar_url)');
      setTherapists((data as unknown as TherapistWithStatus[]) ?? []);
      setLoading(false);
    })();
  }, []);

  // Check for scheduling conflict whenever selection changes
  useEffect(() => {
    if (!selectedId) { setConflictWarning(null); return; }
    const supabase = createClient();
    const slot = new Date(booking.scheduled_at);
    const gte = new Date(slot.getTime() - 2 * 60 * 60 * 1000).toISOString();
    const lte = new Date(slot.getTime() + 2 * 60 * 60 * 1000).toISOString();
    supabase
      .from('bookings')
      .select('id', { count: 'exact', head: true })
      .eq('therapist_id', selectedId)
      .neq('id', booking.id)
      .in('status', ACTIVE_STATUSES)
      .gte('scheduled_at', gte)
      .lte('scheduled_at', lte)
      .then(({ count }) => {
        setConflictWarning(
          (count ?? 0) > 0
            ? 'This therapist has another booking at this time. You can still assign them.'
            : null
        );
      });
  }, [selectedId]);

  async function handleAssign() {
    if (!selectedId) return;
    setSaving(true);
    setError(null);
    const result = await adminMutate(
      'bookings',
      'update',
      { therapist_id: selectedId, status: 'therapist_assigned' as BookingStatus },
      { id: booking.id }
    );
    setSaving(false);
    if (result.error) { setError(result.error); return; }
    onAssigned();
    onClose();
  }

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl border shadow-xl w-full max-w-lg max-h-[90vh] flex flex-col" style={{ borderColor: '#EBE4D9' }}>
        <div className="flex items-center justify-between px-5 py-4 border-b flex-shrink-0" style={{ borderColor: '#EBE4D9' }}>
          <div>
            <h3 className="font-semibold" style={{ color: '#2C2C2A' }}>Assign Therapist</h3>
            <p className="text-xs mt-0.5" style={{ color: '#7A7A72' }}>
              Booking #{booking.id.slice(0, 8).toUpperCase()}
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded-lg transition-colors"
            style={{ color: '#9A9A90' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="overflow-y-auto flex-1 p-3 space-y-2">
          {loading && (
            <div className="flex justify-center py-10">
              <div className="w-6 h-6 rounded-full border-4 animate-spin" style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }} />
            </div>
          )}
          {!loading && therapists.length === 0 && (
            <p className="text-center py-10 text-sm" style={{ color: '#9A9A90' }}>No therapists found.</p>
          )}
          {!loading && therapists.map((t) => {
            const selected = selectedId === t.profile_id;
            const tName = t.profile?.full_name ?? 'Unknown';
            const tAvatar = t.profile?.avatar_url ?? null;
            return (
              <button
                key={t.id}
                onClick={() => setSelectedId(t.profile_id)}
                className="w-full flex items-center gap-3 px-4 py-3 rounded-xl border-2 text-left transition-all"
                style={
                  selected
                    ? { borderColor: '#4E523B', backgroundColor: '#F0F2E8' }
                    : { borderColor: '#EBE4D9', backgroundColor: 'white' }
                }
                onMouseEnter={(e) => {
                  if (!selected) (e.currentTarget as HTMLButtonElement).style.borderColor = '#C5CAB0';
                }}
                onMouseLeave={(e) => {
                  if (!selected) (e.currentTarget as HTMLButtonElement).style.borderColor = '#EBE4D9';
                }}
              >
                {tAvatar ? (
                  <img src={tAvatar} alt={tName} className="w-10 h-10 rounded-full object-cover flex-shrink-0" />
                ) : (
                  <span className={cn('w-10 h-10 rounded-full flex-shrink-0 flex items-center justify-center text-white text-sm font-semibold', avatarColor(tName))}>
                    {getInitials(tName)}
                  </span>
                )}
                <div className="min-w-0 flex-1">
                  <p className="font-medium text-sm" style={{ color: '#2C2C2A' }}>{tName}</p>
                  <div className="flex items-center gap-2 mt-0.5 flex-wrap">
                    <div className="flex items-center gap-1">
                      <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                      <span className="text-xs" style={{ color: '#7A7A72' }}>
                        {t.rating_avg?.toFixed(1) ?? '—'} · {t.total_reviews ?? 0} reviews
                      </span>
                    </div>
                    <span className="text-xs" style={{ color: '#C5CAB0' }}>·</span>
                    <AvailabilityBadge isAvailable={t.is_available} status={t.status} />
                  </div>
                </div>
                {selected && (
                  <span className="flex-shrink-0 w-5 h-5 rounded-full flex items-center justify-center" style={{ backgroundColor: '#4E523B' }}>
                    <svg className="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                  </span>
                )}
              </button>
            );
          })}
        </div>

        <div className="px-5 py-4 border-t flex-shrink-0 space-y-2" style={{ borderColor: '#EBE4D9' }}>
          {conflictWarning && (
            <div className="flex items-start gap-2 px-3 py-2.5 rounded-lg text-xs" style={{ backgroundColor: '#FFFBEB', color: '#92400E', border: '1px solid #FDE68A' }}>
              <svg className="w-3.5 h-3.5 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v3.5a.75.75 0 01-1.5 0v-3.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z" clipRule="evenodd" />
              </svg>
              <span>{conflictWarning}</span>
            </div>
          )}
          {error && <p className="text-sm text-red-600">{error}</p>}
          <div className="flex justify-end gap-2">
            <button
              onClick={onClose}
              className="px-4 py-2 rounded-lg text-sm font-medium transition-colors"
              style={{ backgroundColor: '#F0ECE5', color: '#3D3D38' }}
              onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#EBE4D9'; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
            >
              Cancel
            </button>
            <button
              onClick={handleAssign}
              disabled={!selectedId || saving}
              className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium text-white disabled:opacity-50 transition-colors"
              style={{ backgroundColor: '#4E523B' }}
              onMouseEnter={(e) => { if (!(!selectedId || saving)) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
            >
              <UserCheck className="w-4 h-4" />
              {saving ? 'Assigning…' : 'Assign Therapist'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ── AssignRiderModal ──────────────────────────────────────────────────────────
function AssignRiderModal({
  booking,
  onClose,
  onAssigned,
}: {
  booking: Booking;
  onClose: () => void;
  onAssigned: () => void;
}) {
  const [riders, setRiders] = useState<RiderProfile[]>([]);
  const [busyRiderIds, setBusyRiderIds] = useState<Set<string>>(new Set());
  const [loading, setLoading] = useState(true);
  const [selectedId, setSelectedId] = useState<string | null>(booking.rider_id);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      const supabase = createClient();
      const [ridersRes, assignmentsRes] = await Promise.all([
        supabase
          .from('rider_profiles')
          .select('id, profile_id, branch_id, vehicle_type, plate_number, is_available, profile:profiles(full_name, avatar_url)'),
        supabase
          .from('rider_assignments')
          .select('rider_id')
          .eq('status', 'on_the_way'),
      ]);
      setRiders((ridersRes.data as unknown as RiderProfile[]) ?? []);
      const busy = new Set<string>((assignmentsRes.data ?? []).map((a) => (a as { rider_id: string }).rider_id));
      setBusyRiderIds(busy);
      setLoading(false);
    })();
  }, []);

  async function handleAssign() {
    if (!selectedId) return;
    setSaving(true);
    setError(null);
    try {
      const res = await fetch('/api/admin/assign-rider', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ riderId: selectedId, bookingId: booking.id }),
      });
      const json = await res.json();
      if (!res.ok || json.error) { setError(json.error ?? `HTTP ${res.status}`); setSaving(false); return; }
      onAssigned();
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl border shadow-xl w-full max-w-lg max-h-[90vh] flex flex-col" style={{ borderColor: '#EBE4D9' }}>
        <div className="flex items-center justify-between px-5 py-4 border-b flex-shrink-0" style={{ borderColor: '#EBE4D9' }}>
          <div>
            <h3 className="font-semibold" style={{ color: '#2C2C2A' }}>Assign Rider</h3>
            <p className="text-xs mt-0.5" style={{ color: '#7A7A72' }}>
              Booking #{booking.id.slice(0, 8).toUpperCase()}
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded-lg transition-colors"
            style={{ color: '#9A9A90' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="overflow-y-auto flex-1 p-3 space-y-2">
          {loading && (
            <div className="flex justify-center py-10">
              <div className="w-6 h-6 rounded-full border-4 animate-spin" style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }} />
            </div>
          )}
          {!loading && riders.length === 0 && (
            <p className="text-center py-10 text-sm" style={{ color: '#9A9A90' }}>No riders found.</p>
          )}
          {!loading && riders.map((r) => {
            const rId = r.profile_id;
            const selected = selectedId === rId;
            const busy = busyRiderIds.has(rId);
            const rName = r.profile?.full_name ?? 'Unknown';
            const rAvatar = r.profile?.avatar_url ?? null;
            return (
              <button
                key={r.id}
                onClick={() => !busy && setSelectedId(rId)}
                disabled={busy}
                className="w-full flex items-center gap-3 px-4 py-3 rounded-xl border-2 text-left transition-all"
                style={
                  busy
                    ? { borderColor: '#EBE4D9', backgroundColor: '#FAF7F2', opacity: 0.5, cursor: 'not-allowed' }
                    : selected
                    ? { borderColor: '#4E523B', backgroundColor: '#F0F2E8' }
                    : { borderColor: '#EBE4D9', backgroundColor: 'white' }
                }
                onMouseEnter={(e) => {
                  if (!busy && !selected) (e.currentTarget as HTMLButtonElement).style.borderColor = '#C5CAB0';
                }}
                onMouseLeave={(e) => {
                  if (!busy && !selected) (e.currentTarget as HTMLButtonElement).style.borderColor = '#EBE4D9';
                }}
              >
                {rAvatar ? (
                  <img src={rAvatar} alt={rName} className="w-10 h-10 rounded-full object-cover flex-shrink-0" />
                ) : (
                  <span className={cn('w-10 h-10 rounded-full flex-shrink-0 flex items-center justify-center text-white text-sm font-semibold', avatarColor(rName))}>
                    {getInitials(rName)}
                  </span>
                )}
                <div className="min-w-0 flex-1">
                  <p className="font-medium text-sm" style={{ color: '#2C2C2A' }}>{rName}</p>
                  <div className="flex items-center gap-2 mt-0.5">
                    <span
                      className="text-xs px-1.5 py-0.5 rounded-full font-medium"
                      style={
                        busy
                          ? { backgroundColor: '#FEF3C7', color: '#B45309' }
                          : r.is_available
                          ? { backgroundColor: '#E8EBE0', color: '#4E523B' }
                          : { backgroundColor: '#F0ECE5', color: '#7A7A72' }
                      }
                    >
                      {busy ? 'On the way' : r.is_available ? 'Available' : 'Unavailable'}
                    </span>
                    {r.vehicle_type && (
                      <span className="text-xs" style={{ color: '#9A9A90' }}>{r.vehicle_type}</span>
                    )}
                  </div>
                </div>
                {selected && !busy && (
                  <span className="flex-shrink-0 w-5 h-5 rounded-full flex items-center justify-center" style={{ backgroundColor: '#4E523B' }}>
                    <svg className="w-3 h-3 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                  </span>
                )}
              </button>
            );
          })}
        </div>

        <div className="px-5 py-4 border-t flex-shrink-0 space-y-2" style={{ borderColor: '#EBE4D9' }}>
          {error && <p className="text-sm text-red-600">{error}</p>}
          <div className="flex justify-end gap-2">
            <button
              onClick={onClose}
              className="px-4 py-2 rounded-lg text-sm font-medium transition-colors"
              style={{ backgroundColor: '#F0ECE5', color: '#3D3D38' }}
              onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#EBE4D9'; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
            >
              Cancel
            </button>
            <button
              onClick={handleAssign}
              disabled={!selectedId || saving}
              className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium text-white disabled:opacity-50 transition-colors"
              style={{ backgroundColor: '#4E523B' }}
              onMouseEnter={(e) => { if (!(!selectedId || saving)) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
            >
              <Bike className="w-4 h-4" />
              {saving ? 'Assigning…' : 'Assign Rider'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ── Stars ─────────────────────────────────────────────────────────────────────
function Stars({ rating }: { rating: number }) {
  return (
    <span className="flex items-center gap-0.5">
      {Array.from({ length: 5 }).map((_, i) => (
        <Star
          key={i}
          className={cn(
            'w-3.5 h-3.5',
            i < Math.round(rating)
              ? 'fill-amber-400 text-amber-400'
              : 'fill-slate-200 text-slate-200'
          )}
        />
      ))}
    </span>
  );
}

// ── BookingDetailRow ──────────────────────────────────────────────────────────
function BookingDetailRow({
  booking,
  detail,
  colSpan,
  onAssignClick,
  onAssignRiderClick,
}: {
  booking: Booking;
  detail: DetailEntry;
  colSpan: number;
  onAssignClick: () => void;
  onAssignRiderClick: () => void;
}) {
  const canAssign = booking.status === 'pending' || booking.status === 'accepted';
  const canAssignRider = booking.status !== 'completed' && booking.status !== 'cancelled';
  const isFreeBooking = booking.payment_method === 'free' || booking.total_amount === 0 || detail.hasFreeReward;
  const address = parseAddress(booking.address_snapshot);

  const clientPhone = detail.client?.phone ?? '';
  const cleanPhone = clientPhone.replace(/[^0-9]/g, '');
  const waPhone = cleanPhone.startsWith('0') ? '62' + cleanPhone.substring(1) : cleanPhone;

  return (
    <tr style={{ backgroundColor: '#FAF7F2' }}>
      <td colSpan={colSpan} className="px-0 pb-4">
        <div className="mx-4 mt-1 rounded-xl border bg-white overflow-hidden" style={{ borderColor: '#EBE4D9' }}>
          {detail.loading ? (
            <div className="flex items-center justify-center py-8">
              <div className="w-5 h-5 rounded-full border-4 animate-spin" style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }} />
            </div>
          ) : (
            <>
              {isFreeBooking && (
                <div className="flex items-center gap-2 px-4 py-2.5 border-b" style={{ backgroundColor: '#FFFBEB', borderColor: '#FDE68A' }}>
                  <Gift className="w-4 h-4 flex-shrink-0" style={{ color: '#92400E' }} />
                  <span className="text-sm font-semibold" style={{ color: '#92400E' }}>Free Reward Applied</span>
                  <span className="text-xs" style={{ color: '#B45309' }}>— this booking was redeemed using a reward</span>
                </div>
              )}
              <div className="grid grid-cols-1 sm:grid-cols-3 divide-y sm:divide-y-0 sm:divide-x divide-stone-200">

                {/* Col 1: Client contact + address + notes */}
                <div className="p-4 space-y-4">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-wide mb-2" style={{ color: '#7A7A72' }}>
                      Contact
                    </p>
                    <ul className="space-y-1.5">
                      <li className="flex items-center gap-2">
                        <Mail className="w-3.5 h-3.5 flex-shrink-0" style={{ color: '#9A9A90' }} />
                        <span className="text-sm break-all" style={{ color: '#2C2C2A' }}>
                          {detail.client?.email ?? '—'}
                        </span>
                      </li>
                      <li className="flex items-start gap-2">
                        <Phone className="w-3.5 h-3.5 flex-shrink-0 mt-0.5" style={{ color: '#9A9A90' }} />
                        <div className="space-y-1.5">
                          <span className="text-sm" style={{ color: '#2C2C2A' }}>
                            {detail.client?.phone ?? '—'}
                          </span>
                          {waPhone && (
                            <div>
                              <a
                                href={`https://wa.me/${waPhone}`}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-flex items-center gap-1.5 px-3 py-1.5 text-white text-xs font-semibold rounded-lg transition-colors"
                                style={{ backgroundColor: '#25D366' }}
                                onMouseEnter={(e) => { (e.currentTarget as HTMLAnchorElement).style.backgroundColor = '#16a34a'; }}
                                onMouseLeave={(e) => { (e.currentTarget as HTMLAnchorElement).style.backgroundColor = '#25D366'; }}
                              >
                                <MessageCircle className="w-3.5 h-3.5" />
                                WhatsApp Client
                              </a>
                            </div>
                          )}
                        </div>
                      </li>
                      <li className="flex items-start gap-2">
                        <MapPin className="w-3.5 h-3.5 flex-shrink-0 mt-0.5" style={{ color: '#9A9A90' }} />
                        <div className="space-y-1.5">
                          <span className="text-sm break-words" style={{ color: '#2C2C2A' }}>{address}</span>
                          {address && address !== 'No address' && (
                            <div>
                              <a
                                href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(address)}`}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-flex items-center gap-1.5 px-3 py-1.5 text-white text-xs font-semibold rounded-lg transition-colors"
                                style={{ backgroundColor: '#4285F4' }}
                                onMouseEnter={(e) => { (e.currentTarget as HTMLAnchorElement).style.backgroundColor = '#1a73e8'; }}
                                onMouseLeave={(e) => { (e.currentTarget as HTMLAnchorElement).style.backgroundColor = '#4285F4'; }}
                              >
                                <MapPin className="w-3.5 h-3.5" />
                                Open in Maps
                              </a>
                            </div>
                          )}
                        </div>
                      </li>
                    </ul>
                  </div>

                  <div>
                    <p className="text-xs font-semibold uppercase tracking-wide mb-2" style={{ color: '#7A7A72' }}>
                      Notes
                    </p>
                    {booking.notes ? (
                      <p className="text-sm rounded-lg px-3 py-2 border" style={{ color: '#2C2C2A', backgroundColor: '#FFFBEB', borderColor: '#FDE68A' }}>
                        {booking.notes}
                      </p>
                    ) : (
                      <p className="text-sm italic" style={{ color: '#9A9A90' }}>No notes</p>
                    )}
                  </div>

                  {booking.status === 'completed' && (
                    <div>
                      <p className="text-xs font-semibold uppercase tracking-wide mb-2" style={{ color: '#7A7A72' }}>
                        Client Rating
                      </p>
                      {detail.review ? (
                        <div className="space-y-1.5">
                          <div className="flex items-center gap-2">
                            <Stars rating={detail.review.rating} />
                            <span className="text-sm font-medium" style={{ color: '#2C2C2A' }}>
                              {detail.review.rating}/5
                            </span>
                          </div>
                          {detail.review.review_text && (
                            <p className="text-sm leading-relaxed" style={{ color: '#2C2C2A' }}>
                              {detail.review.review_text}
                            </p>
                          )}
                          <p className="text-xs" style={{ color: '#9A9A90' }}>
                            {formatWIBDate(detail.review.created_at)}
                          </p>
                        </div>
                      ) : (
                        <p className="text-sm italic" style={{ color: '#9A9A90' }}>No rating yet</p>
                      )}
                    </div>
                  )}
                </div>

                {/* Col 2: Treatments */}
                <div className="p-4">
                  <p className="text-xs font-semibold uppercase tracking-wide mb-3" style={{ color: '#7A7A72' }}>
                    Treatments ({detail.items.length})
                  </p>
                  {detail.items.length === 0 ? (
                    <p className="text-sm italic" style={{ color: '#9A9A90' }}>No treatments</p>
                  ) : (
                    <ul className="space-y-2">
                      {detail.items.map((item, i) => (
                        <li key={i} className="flex items-start justify-between gap-2">
                          <div>
                            <p className="text-sm font-medium" style={{ color: '#2C2C2A' }}>
                              {item.name}{item.quantity > 1 ? ` ×${item.quantity}` : ''}
                            </p>
                            <p className="text-xs" style={{ color: '#9A9A90' }}>{item.duration_minutes} min</p>
                          </div>
                          {item.price === 0 ? (
                            <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded-full text-xs font-bold flex-shrink-0" style={{ backgroundColor: '#FEF3C7', color: '#92400E' }}>
                              <Gift className="w-2.5 h-2.5" />
                              FREE
                            </span>
                          ) : (
                            <span className="text-sm whitespace-nowrap flex-shrink-0" style={{ color: '#5A5A52' }}>
                              {formatRupiah(item.price)}
                            </span>
                          )}
                        </li>
                      ))}
                    </ul>
                  )}
                </div>

                {/* Col 3: Add-ons + Rider + Assign buttons */}
                <div className="p-4 flex flex-col gap-4">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-wide mb-3" style={{ color: '#7A7A72' }}>
                      Add-ons ({detail.addons.length})
                    </p>
                    {detail.addons.length === 0 ? (
                      <p className="text-sm italic" style={{ color: '#9A9A90' }}>No add-ons</p>
                    ) : (
                      <ul className="space-y-2">
                        {detail.addons.map((addon, i) => (
                          <li key={i} className="flex items-center justify-between gap-2">
                            <span className="text-sm" style={{ color: '#2C2C2A' }}>
                              {addon.name}{addon.quantity > 1 ? ` ×${addon.quantity}` : ''}
                            </span>
                            {addon.price === 0 ? (
                              <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded-full text-xs font-bold flex-shrink-0" style={{ backgroundColor: '#FEF3C7', color: '#92400E' }}>
                                <Gift className="w-2.5 h-2.5" />
                                FREE
                              </span>
                            ) : (
                              <span className="text-sm whitespace-nowrap flex-shrink-0" style={{ color: '#5A5A52' }}>
                                {formatRupiah(addon.price)}
                              </span>
                            )}
                          </li>
                        ))}
                      </ul>
                    )}
                  </div>

                  {/* Rider info */}
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-wide mb-2" style={{ color: '#7A7A72' }}>
                      Rider
                    </p>
                    {detail.rider ? (
                      <div className="flex items-center gap-2">
                        <Bike className="w-4 h-4 flex-shrink-0" style={{ color: '#9A9A90' }} />
                        <div>
                          <p className="text-sm font-medium" style={{ color: '#2C2C2A' }}>
                            {detail.rider.name ?? '—'}
                          </p>
                          <span
                            className="text-xs px-1.5 py-0.5 rounded-full font-medium"
                            style={
                              detail.rider.assignmentStatus === 'on_the_way'
                                ? { backgroundColor: '#E0E7FF', color: '#3730A3' }
                                : detail.rider.assignmentStatus === 'assigned'
                                ? { backgroundColor: '#CFFAFE', color: '#0E7490' }
                                : { backgroundColor: '#F0ECE5', color: '#7A7A72' }
                            }
                          >
                            {detail.rider.assignmentStatus.replace(/_/g, ' ')}
                          </span>
                        </div>
                      </div>
                    ) : (
                      <p className="text-sm italic" style={{ color: '#9A9A90' }}>No rider assigned</p>
                    )}
                  </div>

                  <div className="mt-auto space-y-2">
                    {canAssign && (
                      <button
                        onClick={onAssignClick}
                        className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold text-white transition-colors"
                        style={{ backgroundColor: '#4E523B' }}
                        onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
                        onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
                      >
                        <UserCheck className="w-4 h-4" />
                        {booking.therapist_id ? 'Reassign Therapist' : 'Assign Therapist'}
                      </button>
                    )}
                    {canAssignRider && (
                      <button
                        onClick={onAssignRiderClick}
                        className="w-full flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold text-white transition-colors"
                        style={{ backgroundColor: '#0E7490' }}
                        onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#0C6478'; }}
                        onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#0E7490'; }}
                      >
                        <Bike className="w-4 h-4" />
                        {detail.rider ? 'Reassign Rider' : 'Assign Rider'}
                      </button>
                    )}
                  </div>
                </div>
              </div>
            </>
          )}
        </div>
      </td>
    </tr>
  );
}

// ── Main page ─────────────────────────────────────────────────────────────────
export default function BookingsPage() {
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<TabKey>('all');
  const [tabCounts, setTabCounts] = useState<Partial<Record<TabKey, number>>>({});
  const [activeDateRange, setActiveDateRange] = useState<DateRangeKey>('all');
  const [pageSize, setPageSize] = useState(DEFAULT_PAGE_SIZE);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [updatingId, setUpdatingId] = useState<string | null>(null);
  const [therapistMap, setTherapistMap] = useState<Record<string, string>>({});
  const [customerMap, setCustomerMap] = useState<Record<string, Pick<Profile, 'full_name' | 'avatar_url'>>>({});
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [detailCache, setDetailCache] = useState<Record<string, DetailEntry>>({});
  const [assignModal, setAssignModal] = useState<Booking | null>(null);
  const [assignRiderModal, setAssignRiderModal] = useState<Booking | null>(null);

  const COLS = 9;

  useEffect(() => {
    loadBookings();
  }, [activeTab, activeDateRange, pageSize, page]); // eslint-disable-line react-hooks/exhaustive-deps

  useRealtimeTable('bookings-realtime', 'bookings', (payload) => {
    loadBookings();
    if (payload.eventType === 'INSERT') toast.success('New booking received! 🎉');
    if (payload.eventType === 'UPDATE') toast('Booking status updated', { icon: 'ℹ️' });
  });

  async function loadCounts(dr: { gte: string; lt: string } | null) {
    const supabase = createClient();
    let q = supabase.from('bookings').select('status');
    if (dr) q = (q.gte('scheduled_at', dr.gte) as typeof q).lt('scheduled_at', dr.lt);
    const { data } = await q;
    const raw: Record<string, number> = {};
    for (const row of (data ?? []) as { status: string }[]) {
      raw[row.status] = (raw[row.status] ?? 0) + 1;
    }
    const grandTotal = Object.values(raw).reduce((a, b) => a + b, 0);
    const counts: Partial<Record<TabKey, number>> = {};
    for (const tab of TABS) {
      counts[tab.key] = tab.statuses.length === 0
        ? grandTotal
        : tab.statuses.reduce((sum, s) => sum + (raw[s] ?? 0), 0);
    }
    setTabCounts(counts);
  }

  async function loadBookings() {
    setLoading(true);
    const supabase = createClient();

    const tabStatuses = TABS.find((t) => t.key === activeTab)?.statuses ?? [];
    const dr = getDateRange(activeDateRange);

    let q = supabase
      .from('bookings')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range((page - 1) * pageSize, page * pageSize - 1);

    if (tabStatuses.length === 1) {
      q = q.eq('status', tabStatuses[0]);
    } else if (tabStatuses.length > 1) {
      q = q.in('status', tabStatuses);
    }
    if (dr) q = (q.gte('scheduled_at', dr.gte) as typeof q).lt('scheduled_at', dr.lt);

    const { data, count } = await q;
    const rows = (data as Booking[]) ?? [];

    const [{ data: therapists }, profilesRes] = await Promise.all([
      supabase.from('therapist_profiles').select('id, profile_id, profile:profiles(full_name)'),
      fetch('/api/admin/profiles').then(async (r) => {
        if (!r.ok) { console.error('[Bookings] profiles API', r.status); return []; }
        return r.json();
      }).catch((err: unknown) => { console.error('[Bookings] profiles fetch threw:', err); return []; }),
    ]);

    const tMap: Record<string, string> = {};
    for (const t of therapists ?? []) {
      const r = t as unknown as { id: string; profile_id: string; profile: { full_name: string | null } | null };
      tMap[r.profile_id] = r.profile?.full_name ?? 'Unknown';
    }

    const cMap: Record<string, Pick<Profile, 'full_name' | 'avatar_url'>> = {};
    for (const p of (Array.isArray(profilesRes) ? profilesRes : []) as { id: string; full_name: string | null; avatar_url: string | null }[]) {
      cMap[p.id] = { full_name: p.full_name, avatar_url: p.avatar_url };
    }

    setBookings(rows);
    setTotal(count ?? 0);
    setTherapistMap(tMap);
    setCustomerMap(cMap);
    setLoading(false);
    loadCounts(dr);
  }

  async function loadDetail(bookingId: string, clientId: string) {
    setDetailCache((prev) => ({
      ...prev,
      [bookingId]: { loading: true, items: [], addons: [], client: null, review: null, rider: null, hasFreeReward: false },
    }));

    try {
      const res = await fetch('/api/admin/booking-detail', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ bookingId, clientId }),
      });

      if (!res.ok) {
        console.error('[loadDetail] API error:', res.status, await res.text());
        setDetailCache((prev) => ({ ...prev, [bookingId]: { loading: false, items: [], addons: [], client: null, review: null, rider: null, hasFreeReward: false } }));
        return;
      }

      const { items, addons, client, review, rider, hasFreeReward } = await res.json();
      console.log('booking items:', items);

      setDetailCache((prev) => ({
        ...prev,
        [bookingId]: { loading: false, items: items ?? [], addons: addons ?? [], client: client ?? null, review: review ?? null, rider: rider ?? null, hasFreeReward: hasFreeReward ?? false },
      }));
    } catch (err) {
      console.error('[loadDetail] threw:', err);
      setDetailCache((prev) => ({ ...prev, [bookingId]: { loading: false, items: [], addons: [], client: null, review: null, rider: null, hasFreeReward: false } }));
    }
  }

  function toggleExpand(booking: Booking) {
    if (expandedId === booking.id) {
      setExpandedId(null);
    } else {
      setExpandedId(booking.id);
      console.log('booking payment_method:', booking.payment_method, 'total_amount:', booking.total_amount);
      if (!detailCache[booking.id]) loadDetail(booking.id, booking.client_id);
    }
  }

  async function updateStatus(id: string, newStatus: BookingStatus) {
    setUpdatingId(id);
    setBookings((prev) => prev.map((b) => (b.id === id ? { ...b, status: newStatus } : b)));
    const supabase = createClient();
    console.log('Updating booking status:', id, 'to:', newStatus);
    const result = await supabase.from('bookings').update({ status: newStatus }).eq('id', id);
    console.log('Update result:', result);
    console.log('Update error:', result.error);
    if (result.error) await loadBookings();
    setUpdatingId(null);
  }

  const filtered = search
    ? bookings.filter((b) => b.id.toLowerCase().includes(search.toLowerCase()))
    : bookings;

  const totalPages = Math.max(1, Math.ceil(total / pageSize));

  return (
    <div className="space-y-5">
      <h1 className="text-2xl font-bold" style={{ color: '#2C2C2A' }}>Bookings</h1>

      {/* Top bar: search (left) | date tabs + per-page (right) */}
      <div className="flex items-center justify-between gap-3">
        <input
          type="text"
          placeholder="Search by booking ID..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="px-3 py-2 rounded-lg border text-sm w-56 focus:outline-none focus:ring-2 focus:ring-[#4E523B]"
          style={{ borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' }}
        />

        <div className="flex items-center gap-2">
          {/* Date range tabs */}
          <div className="flex items-center gap-1 bg-white border rounded-lg p-1" style={{ borderColor: '#EBE4D9' }}>
            {DATE_RANGES.map((dr) => {
              const isActive = activeDateRange === dr.key;
              return (
                <button
                  key={dr.key}
                  onClick={() => { setActiveDateRange(dr.key); setPage(1); }}
                  className="px-2.5 py-1 rounded-md text-xs font-medium transition-colors whitespace-nowrap"
                  style={isActive ? { backgroundColor: '#4E523B', color: 'white' } : { color: '#7A7A72' }}
                  onMouseEnter={(e) => {
                    if (!isActive) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5';
                  }}
                  onMouseLeave={(e) => {
                    if (!isActive) (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent';
                  }}
                >
                  {dr.label}
                </button>
              );
            })}
          </div>

          {/* Per-page */}
          <select
            value={pageSize}
            onChange={(e) => { setPageSize(Number(e.target.value)); setPage(1); }}
            className="px-2 py-2 rounded-lg border text-xs font-medium focus:outline-none focus:ring-2 focus:ring-[#4E523B]"
            style={{ borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' }}
          >
            {[10, 25, 50, 100].map((n) => (
              <option key={n} value={n}>{n} Data</option>
            ))}
          </select>
        </div>
      </div>

      {/* Status tab bar */}
      <div className="bg-white rounded-xl border shadow-sm flex overflow-x-auto" style={{ borderColor: '#EBE4D9' }}>
        {TABS.map((tab, i) => {
          const isActive = activeTab === tab.key;
          const count = tabCounts[tab.key] ?? 0;
          return (
            <button
              key={tab.key}
              onClick={() => { setActiveTab(tab.key); setPage(1); }}
              className={cn(
                'relative flex items-center gap-2 px-4 py-3 text-sm font-medium whitespace-nowrap transition-colors flex-shrink-0',
                i === 0 ? 'rounded-tl-xl' : ''
              )}
              style={isActive ? { color: '#4E523B' } : { color: '#7A7A72' }}
              onMouseEnter={(e) => {
                if (!isActive) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#FAF7F2';
              }}
              onMouseLeave={(e) => {
                if (!isActive) (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent';
              }}
            >
              {tab.label}
              <span
                className="inline-flex items-center justify-center min-w-[1.25rem] h-5 px-1.5 rounded-full text-xs font-semibold"
                style={
                  isActive
                    ? { backgroundColor: '#4E523B', color: 'white' }
                    : { backgroundColor: '#F0ECE5', color: '#7A7A72' }
                }
              >
                {count}
              </span>
              {isActive && (
                <span className="absolute bottom-0 left-0 right-0 h-0.5 rounded-full" style={{ backgroundColor: '#4E523B' }} />
              )}
            </button>
          );
        })}
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border shadow-sm overflow-hidden" style={{ borderColor: '#EBE4D9' }}>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b" style={{ backgroundColor: '#FAF7F2', borderColor: '#EBE4D9' }}>
                <th className="px-4 py-3 w-8" />
                <th className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>#ID</th>
                <th className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Scheduled</th>
                <th className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Customer</th>
                <th className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Therapist</th>
                <th className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Status</th>
                <th className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Payment</th>
                <th className="text-right px-4 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Total</th>
                <th className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Update</th>
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr>
                  <td colSpan={COLS} className="px-4 py-10 text-center" style={{ color: '#9A9A90' }}>
                    Loading...
                  </td>
                </tr>
              )}
              {!loading && filtered.length === 0 && (
                <tr>
                  <td colSpan={COLS} className="px-4 py-10 text-center" style={{ color: '#9A9A90' }}>
                    No bookings found
                  </td>
                </tr>
              )}
              {!loading && filtered.map((b) => {
                const customer = customerMap[b.client_id] ?? null;
                const isExpanded = expandedId === b.id;

                return [
                  // ── Main row ──
                  <tr
                    key={b.id}
                    className="border-b transition-colors"
                    style={{ borderColor: '#EBE4D9', backgroundColor: isExpanded ? '#FAF7F2' : undefined }}
                    onMouseEnter={(e) => {
                      if (!isExpanded) (e.currentTarget as HTMLTableRowElement).style.backgroundColor = '#FAF7F2';
                    }}
                    onMouseLeave={(e) => {
                      if (!isExpanded) (e.currentTarget as HTMLTableRowElement).style.backgroundColor = 'transparent';
                    }}
                  >
                    <td className="px-4 py-3 w-8">
                      <button
                        onClick={() => toggleExpand(b)}
                        className="p-1 rounded-md transition-colors"
                        style={{ color: '#9A9A90' }}
                        onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
                        onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
                        title={isExpanded ? 'Collapse' : 'View details'}
                      >
                        {isExpanded
                          ? <ChevronUp className="w-4 h-4" />
                          : <ChevronDown className="w-4 h-4" />}
                      </button>
                    </td>
                    <td className="px-4 py-3 font-mono text-xs whitespace-nowrap" style={{ color: '#5A5A52' }}>
                      #{b.id.slice(0, 8).toUpperCase()}
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap" style={{ color: '#2C2C2A' }}>
                      {formatDate(b.scheduled_at, true)}
                    </td>
                    <td className="px-4 py-3 max-w-[180px]">
                      <CustomerAvatar name={customer?.full_name ?? null} avatarUrl={customer?.avatar_url ?? null} clientId={b.client_id} />
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap" style={{ color: '#5A5A52' }}>
                      {b.therapist_id
                        ? (therapistMap[b.therapist_id] ?? '—')
                        : <span className="italic" style={{ color: '#9A9A90' }}>Unassigned</span>}
                    </td>
                    <td className="px-4 py-3">
                      <span className={cn('inline-flex px-2 py-0.5 rounded-full text-xs font-medium whitespace-nowrap', STATUS_COLORS[b.status] ?? '')}>
                        {STATUS_LABELS[b.status] ?? b.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap capitalize" style={{ color: '#2C2C2A' }}>
                      {b.payment_method.replace(/_/g, ' ')}
                    </td>
                    <td className="px-4 py-3 text-right font-medium whitespace-nowrap">
                      {(b.payment_method === 'free' || b.total_amount === 0) ? (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-bold" style={{ backgroundColor: '#FEF3C7', color: '#92400E' }}>
                          <Gift className="w-3 h-3" />
                          FREE
                        </span>
                      ) : (
                        <span style={{ color: '#2C2C2A' }}>{formatRupiah(b.total_amount)}</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      <select
                        value={b.status}
                        disabled={updatingId === b.id}
                        onChange={(e) => updateStatus(b.id, e.target.value as BookingStatus)}
                        className="px-2 py-1 rounded-lg border text-xs disabled:opacity-50 focus:outline-none focus:ring-2 focus:ring-[#4E523B]"
                        style={{ borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' }}
                      >
                        {ALL_STATUSES.map((s) => (
                          <option key={s} value={s}>{STATUS_LABELS[s]}</option>
                        ))}
                      </select>
                    </td>
                  </tr>,

                  // ── Detail panel row (only when expanded) ──
                  ...(isExpanded && detailCache[b.id]
                    ? [
                        <BookingDetailRow
                          key={`${b.id}-detail`}
                          booking={b}
                          detail={detailCache[b.id]}
                          colSpan={COLS}
                          onAssignClick={() => setAssignModal(b)}
                          onAssignRiderClick={() => setAssignRiderModal(b)}
                        />,
                      ]
                    : []),
                ];
              })}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div className="flex items-center justify-between px-4 py-3 border-t" style={{ borderColor: '#EBE4D9' }}>
          <p className="text-sm" style={{ color: '#7A7A72' }}>
            {total === 0
              ? 'No bookings'
              : `Showing ${(page - 1) * pageSize + 1}–${Math.min(page * pageSize, total)} of ${total}`}
          </p>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1}
              className="flex items-center gap-1 px-3 py-1.5 rounded-lg border text-sm disabled:opacity-40 transition-colors"
              style={{ borderColor: '#EBE4D9', color: '#7A7A72', backgroundColor: 'white' }}
              onMouseEnter={(e) => { if (page !== 1) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'white'; }}
            >
              <ChevronLeft className="w-4 h-4" />
              Previous
            </button>
            <span className="text-sm px-1" style={{ color: '#2C2C2A' }}>{page} / {totalPages}</span>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="flex items-center gap-1 px-3 py-1.5 rounded-lg border text-sm disabled:opacity-40 transition-colors"
              style={{ borderColor: '#EBE4D9', color: '#7A7A72', backgroundColor: 'white' }}
              onMouseEnter={(e) => { if (page !== totalPages) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'white'; }}
            >
              Next
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Assign Therapist Modal */}
      {assignModal && (
        <AssignTherapistModal
          booking={assignModal}
          onClose={() => setAssignModal(null)}
          onAssigned={() => {
            loadBookings();
            setDetailCache((prev) => {
              const next = { ...prev };
              delete next[assignModal.id];
              return next;
            });
          }}
        />
      )}

      {/* Assign Rider Modal */}
      {assignRiderModal && (
        <AssignRiderModal
          booking={assignRiderModal}
          onClose={() => setAssignRiderModal(null)}
          onAssigned={() => {
            loadBookings();
            setDetailCache((prev) => {
              const next = { ...prev };
              delete next[assignRiderModal.id];
              return next;
            });
          }}
        />
      )}
    </div>
  );
}
