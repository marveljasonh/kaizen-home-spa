'use client';

import { useEffect, useState } from 'react';
import {
  Plus,
  X,
  ChevronDown,
  ChevronUp,
  ChevronLeft,
  ChevronRight,
  MessageCircle,
  Pencil,
  Trash2,
  Star,
} from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { cn, formatDate, formatRupiah, STATUS_COLORS, STATUS_LABELS } from '@/lib/utils';
import { useRealtimeTable } from '@/lib/hooks/useRealtimeTable';

// ── Types ─────────────────────────────────────────────────────────────────────
interface CustomerRow {
  id: string;
  full_name: string | null;
  email: string | null;
  phone: string | null;
  gender: string | null;
  avatar_url: string | null;
  created_at: string;
}

interface BookingRow {
  id: string;
  scheduled_at: string;
  status: string;
  total_amount: number;
  payment_method: string;
}

interface SavedAddress {
  id: string;
  client_id: string;
  label: string | null;
  address_line: string | null;
  address: string | null;
  notes: string | null;
  is_default: boolean;
}

interface CustomerDetail {
  loading: boolean;
  bookings: BookingRow[];
  addresses: SavedAddress[];
}

// ── Helpers ───────────────────────────────────────────────────────────────────
function getInitials(name: string): string {
  return name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0].toUpperCase())
    .join('');
}

function Avatar({ name, url }: { name: string | null; url: string | null }) {
  const display = name?.trim() || 'C';
  if (url) {
    return <img src={url} alt={display} className="w-8 h-8 rounded-full object-cover flex-shrink-0" />;
  }
  return (
    <span
      className="w-8 h-8 rounded-full flex-shrink-0 flex items-center justify-center text-xs font-semibold"
      style={{ backgroundColor: '#E8EBE0', color: '#4E523B' }}
    >
      {getInitials(display)}
    </span>
  );
}

function cleanPhone(phone: string): string {
  return phone.replace(/\D/g, '');
}

const ADDRESS_LABEL: Record<string, { emoji: string; bg: string; color: string }> = {
  Home:   { emoji: '🏠', bg: '#E8EBE0', color: '#4E523B' },
  Office: { emoji: '🏢', bg: '#DBEAFE', color: '#1E40AF' },
  Other:  { emoji: '📍', bg: '#FEF3C7', color: '#B45309' },
};

// ── Add Customer Modal ────────────────────────────────────────────────────────
function AddCustomerModal({
  onClose,
  onSaved,
}: {
  onClose: () => void;
  onSaved: () => void;
}) {
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [gender, setGender] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSave() {
    if (!fullName.trim() || !email.trim()) return;
    setSaving(true);
    setError(null);
    try {
      const res = await fetch('/api/admin/customers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: email.trim(),
          full_name: fullName.trim(),
          phone: phone.trim() || null,
          gender: gender || null,
        }),
      });
      const json = await res.json();
      if (!res.ok || json.error) {
        setError(json.error ?? `HTTP ${res.status}`);
        setSaving(false);
        return;
      }
      onSaved();
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
      setSaving(false);
    }
  }

  const inputCls =
    'w-full px-3 py-2 rounded-lg border text-sm focus:outline-none focus:ring-2 focus:ring-[#4E523B]';
  const inputStyle = { borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' };
  const labelStyle = { color: '#3D3D38' };

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl border shadow-xl w-full max-w-md" style={{ borderColor: '#EBE4D9' }}>
        <div className="flex items-center justify-between px-5 py-4 border-b" style={{ borderColor: '#EBE4D9' }}>
          <h3 className="font-semibold" style={{ color: '#2C2C2A' }}>
            Add New Customer
          </h3>
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

        <div className="p-5 space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1.5" style={labelStyle}>
              Full Name *
            </label>
            <input
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              placeholder="Jane Doe"
              className={inputCls}
              style={inputStyle}
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1.5" style={labelStyle}>
              Email *
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="jane@example.com"
              className={inputCls}
              style={inputStyle}
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1.5" style={labelStyle}>
              Phone
            </label>
            <input
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="+62 812 3456 7890"
              className={inputCls}
              style={inputStyle}
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1.5" style={labelStyle}>
              Gender
            </label>
            <select
              value={gender}
              onChange={(e) => setGender(e.target.value)}
              className={inputCls}
              style={inputStyle}
            >
              <option value="">— Select —</option>
              <option value="Male">Male</option>
              <option value="Female">Female</option>
            </select>
          </div>

          {error && (
            <div
              className="p-3 rounded-lg border text-sm text-red-700"
              style={{ backgroundColor: '#FEF2F2', borderColor: '#FECACA' }}
            >
              {error}
            </div>
          )}

          <p className="text-xs" style={{ color: '#9A9A90' }}>
            A temporary password is auto-generated. The customer can reset it via "Forgot Password".
          </p>
        </div>

        <div className="flex justify-end gap-2 px-5 py-4 border-t" style={{ borderColor: '#EBE4D9' }}>
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
            onClick={handleSave}
            disabled={!fullName.trim() || !email.trim() || saving}
            className="px-4 py-2 rounded-lg text-sm font-medium text-white disabled:opacity-50 transition-colors"
            style={{ backgroundColor: '#4E523B' }}
            onMouseEnter={(e) => {
              if (fullName.trim() && email.trim() && !saving)
                (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130';
            }}
            onMouseLeave={(e) => {
              (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B';
            }}
          >
            {saving ? 'Creating…' : 'Create Customer'}
          </button>
        </div>
      </div>
    </div>
  );
}

// ── Edit Customer Modal ───────────────────────────────────────────────────────
function EditCustomerModal({
  customer,
  onClose,
  onSaved,
}: {
  customer: CustomerRow;
  onClose: () => void;
  onSaved: (updated: Pick<CustomerRow, 'id' | 'full_name' | 'phone' | 'gender'>) => void;
}) {
  const [fullName, setFullName] = useState(customer.full_name ?? '');
  const [phone, setPhone] = useState(customer.phone ?? '');
  const [gender, setGender] = useState(customer.gender ?? '');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSave() {
    if (!fullName.trim()) return;
    setSaving(true);
    setError(null);
    const supabase = createClient();
    const { error: dbError } = await supabase
      .from('profiles')
      .update({
        full_name: fullName.trim(),
        phone: phone.trim() || null,
        gender: gender || null,
      })
      .eq('id', customer.id);
    setSaving(false);
    if (dbError) { setError(dbError.message); return; }
    onSaved({ id: customer.id, full_name: fullName.trim(), phone: phone.trim() || null, gender: gender || null });
    onClose();
  }

  const inputCls =
    'w-full px-3 py-2 rounded-lg border text-sm focus:outline-none focus:ring-2 focus:ring-[#4E523B]';
  const inputStyle = { borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' };
  const labelStyle = { color: '#3D3D38' };

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl border shadow-xl w-full max-w-md" style={{ borderColor: '#EBE4D9' }}>
        <div className="flex items-center justify-between px-5 py-4 border-b" style={{ borderColor: '#EBE4D9' }}>
          <div>
            <h3 className="font-semibold" style={{ color: '#2C2C2A' }}>Edit Customer</h3>
            <p className="text-xs mt-0.5" style={{ color: '#7A7A72' }}>{customer.email}</p>
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

        <div className="p-5 space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1.5" style={labelStyle}>Full Name *</label>
            <input
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              placeholder="Jane Doe"
              className={inputCls}
              style={inputStyle}
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1.5" style={labelStyle}>Phone</label>
            <input
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="+62 812 3456 7890"
              className={inputCls}
              style={inputStyle}
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-2" style={labelStyle}>Gender</label>
            <div className="flex gap-2">
              {['Male', 'Female'].map((g) => (
                <button
                  key={g}
                  onClick={() => setGender(gender === g ? '' : g)}
                  className="flex-1 py-2 rounded-lg text-sm font-medium border-2 transition-all"
                  style={
                    gender === g
                      ? { borderColor: '#4E523B', backgroundColor: '#F0F2E8', color: '#4E523B' }
                      : { borderColor: '#EBE4D9', backgroundColor: 'white', color: '#7A7A72' }
                  }
                >
                  {g}
                </button>
              ))}
            </div>
          </div>

          {error && (
            <div className="p-3 rounded-lg border text-sm text-red-700" style={{ backgroundColor: '#FEF2F2', borderColor: '#FECACA' }}>
              {error}
            </div>
          )}
        </div>

        <div className="flex justify-end gap-2 px-5 py-4 border-t" style={{ borderColor: '#EBE4D9' }}>
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
            onClick={handleSave}
            disabled={!fullName.trim() || saving}
            className="px-4 py-2 rounded-lg text-sm font-medium text-white disabled:opacity-50 transition-colors"
            style={{ backgroundColor: '#4E523B' }}
            onMouseEnter={(e) => { if (fullName.trim() && !saving) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
          >
            {saving ? 'Saving…' : 'Save Changes'}
          </button>
        </div>
      </div>
    </div>
  );
}

// ── Manage Points Modal ───────────────────────────────────────────────────────
function GivePointsModal({
  customer,
  currentPoints,
  onClose,
  onSaved,
}: {
  customer: CustomerRow;
  currentPoints: number;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [mode, setMode] = useState<'add' | 'deduct'>('add');
  const [points, setPoints] = useState('');
  const [reason, setReason] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit() {
    const amount = Number(points);
    if (!points || amount < 1 || !Number.isInteger(amount)) {
      setError('Enter a whole number of points (minimum 1).');
      return;
    }
    if (mode === 'deduct' && amount > currentPoints) {
      setError(`Cannot deduct more than available points (${currentPoints.toLocaleString('id-ID')} pts).`);
      return;
    }
    setSaving(true);
    setError(null);
    const supabase = createClient();
    const { error: dbError } = await supabase
      .from('client_points')
      .insert({
        client_id: customer.id,
        points_earned: mode === 'deduct' ? -amount : amount,
        description: reason.trim() || (mode === 'deduct' ? 'Points deducted by admin' : 'Manual points by admin'),
        booking_id: null,
      });
    setSaving(false);
    if (dbError) { setError(dbError.message); return; }
    onSaved();
    onClose();
  }

  const inputCls = 'w-full px-3 py-2 rounded-lg border text-sm focus:outline-none focus:ring-2 focus:ring-[#4E523B]';
  const inputStyle = { borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' };
  const labelStyle = { color: '#3D3D38' };
  const isDeduct = mode === 'deduct';

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl border shadow-xl w-full max-w-sm" style={{ borderColor: '#EBE4D9' }}>
        <div className="flex items-center justify-between px-5 py-4 border-b" style={{ borderColor: '#EBE4D9' }}>
          <div>
            <h3 className="font-semibold" style={{ color: '#2C2C2A' }}>Manage Points</h3>
            <p className="text-xs mt-0.5" style={{ color: '#7A7A72' }}>
              {customer.full_name || customer.email}
              {' · '}
              <span className="font-medium" style={{ color: '#4E523B' }}>
                {currentPoints.toLocaleString('id-ID')} pts current
              </span>
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

        <div className="p-5 space-y-4">
          {/* Mode toggle */}
          <div className="grid grid-cols-2 gap-2 p-1 rounded-xl" style={{ backgroundColor: '#F5F0E8' }}>
            <button
              onClick={() => { setMode('add'); setError(null); }}
              className="flex items-center justify-center gap-1.5 py-2 rounded-lg text-sm font-semibold transition-all"
              style={
                !isDeduct
                  ? { backgroundColor: '#4E523B', color: 'white', boxShadow: '0 1px 3px rgba(0,0,0,0.15)' }
                  : { color: '#7A7A72' }
              }
            >
              ➕ Add Points
            </button>
            <button
              onClick={() => { setMode('deduct'); setError(null); }}
              className="flex items-center justify-center gap-1.5 py-2 rounded-lg text-sm font-semibold transition-all"
              style={
                isDeduct
                  ? { backgroundColor: '#DC2626', color: 'white', boxShadow: '0 1px 3px rgba(0,0,0,0.15)' }
                  : { color: '#7A7A72' }
              }
            >
              ➖ Deduct Points
            </button>
          </div>

          {/* Deduct warning */}
          {isDeduct && (
            <div className="flex items-start gap-2.5 px-3 py-2.5 rounded-lg border text-sm"
              style={{ backgroundColor: '#FEF2F2', borderColor: '#FECACA', color: '#DC2626' }}>
              <span className="flex-shrink-0 mt-0.5">⚠️</span>
              <span>This will reduce the client&apos;s points balance. Max deductible: <strong>{currentPoints.toLocaleString('id-ID')} pts</strong>.</span>
            </div>
          )}

          <div>
            <label className="block text-sm font-medium mb-1.5" style={labelStyle}>
              Points to {isDeduct ? 'Deduct' : 'Add'} *
            </label>
            <input
              type="number"
              min={1}
              max={isDeduct ? currentPoints : undefined}
              step={1}
              value={points}
              onChange={(e) => setPoints(e.target.value)}
              placeholder="e.g. 100"
              autoFocus
              className={inputCls}
              style={isDeduct ? { ...inputStyle, borderColor: '#FECACA' } : inputStyle}
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1.5" style={labelStyle}>
              Reason <span className="font-normal text-xs" style={{ color: '#9A9A90' }}>(optional)</span>
            </label>
            <input
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder={isDeduct ? 'e.g. Incorrect award, Correction' : 'e.g. Manual bonus, Compensation'}
              className={inputCls}
              style={inputStyle}
              onKeyDown={(e) => { if (e.key === 'Enter') handleSubmit(); }}
            />
          </div>

          {error && (
            <div className="flex items-start gap-2 px-3 py-2.5 rounded-lg border text-sm"
              style={{ backgroundColor: '#FEF2F2', borderColor: '#FECACA', color: '#DC2626' }}>
              <span>⚠️</span>
              <span>{error}</span>
            </div>
          )}
        </div>

        <div className="flex justify-end gap-2 px-5 py-4 border-t" style={{ borderColor: '#EBE4D9' }}>
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
            onClick={handleSubmit}
            disabled={saving}
            className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium text-white disabled:opacity-50 transition-colors"
            style={{ backgroundColor: isDeduct ? '#DC2626' : '#4E523B' }}
            onMouseEnter={(e) => {
              if (!saving) (e.currentTarget as HTMLButtonElement).style.backgroundColor = isDeduct ? '#B91C1C' : '#3D4130';
            }}
            onMouseLeave={(e) => {
              (e.currentTarget as HTMLButtonElement).style.backgroundColor = isDeduct ? '#DC2626' : '#4E523B';
            }}
          >
            <Star className="w-4 h-4" />
            {saving ? 'Saving…' : isDeduct ? 'Deduct Points' : 'Give Points'}
          </button>
        </div>
      </div>
    </div>
  );
}

// ── Customer Detail Row ───────────────────────────────────────────────────────
function CustomerDetailRow({
  customer,
  detail,
  colSpan,
}: {
  customer: CustomerRow;
  detail: CustomerDetail;
  colSpan: number;
}) {
  return (
    <tr style={{ backgroundColor: '#FAF7F2' }}>
      <td colSpan={colSpan} className="px-0 pb-4">
        <div
          className="mx-4 mt-1 rounded-xl border bg-white overflow-hidden"
          style={{ borderColor: '#EBE4D9' }}
        >
          {detail.loading ? (
            <div className="flex items-center justify-center py-10">
              <div
                className="w-5 h-5 rounded-full border-4 animate-spin"
                style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }}
              />
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-3 divide-y sm:divide-y-0 sm:divide-x divide-stone-200">

              {/* Profile card */}
              <div className="p-5 space-y-4">
                <div className="flex items-center gap-3">
                  {customer.avatar_url ? (
                    <img
                      src={customer.avatar_url}
                      alt={customer.full_name ?? ''}
                      className="w-12 h-12 rounded-full object-cover flex-shrink-0"
                    />
                  ) : (
                    <span
                      className="w-12 h-12 rounded-full flex-shrink-0 flex items-center justify-center text-base font-bold"
                      style={{ backgroundColor: '#E8EBE0', color: '#4E523B' }}
                    >
                      {getInitials(customer.full_name || 'C')}
                    </span>
                  )}
                  <div className="min-w-0">
                    <p className="font-semibold truncate" style={{ color: '#2C2C2A' }}>
                      {customer.full_name || '—'}
                    </p>
                    <p className="text-xs truncate" style={{ color: '#7A7A72' }}>
                      {customer.email || '—'}
                    </p>
                  </div>
                </div>

                <div className="space-y-2.5">
                  {[
                    { label: 'Phone', value: customer.phone || '—' },
                    { label: 'Gender', value: customer.gender || '—' },
                    { label: 'Joined', value: formatDate(customer.created_at) },
                  ].map(({ label, value }) => (
                    <div key={label} className="flex justify-between gap-4 text-sm">
                      <span style={{ color: '#7A7A72' }}>{label}</span>
                      <span className="text-right" style={{ color: '#2C2C2A' }}>{value}</span>
                    </div>
                  ))}
                </div>

                {customer.phone && (
                  <a
                    href={`https://wa.me/${cleanPhone(customer.phone)}`}
                    target="_blank"
                    rel="noreferrer"
                    className="flex items-center justify-center gap-2 w-full px-3 py-2 rounded-lg text-sm font-medium text-white transition-colors"
                    style={{ backgroundColor: '#25D366' }}
                    onMouseEnter={(e) => { (e.currentTarget as HTMLAnchorElement).style.backgroundColor = '#1EB85A'; }}
                    onMouseLeave={(e) => { (e.currentTarget as HTMLAnchorElement).style.backgroundColor = '#25D366'; }}
                  >
                    <MessageCircle className="w-4 h-4" />
                    Open WhatsApp
                  </a>
                )}
              </div>

              {/* Right side: addresses + booking history stacked */}
              <div className="sm:col-span-2 divide-y divide-stone-200">

                {/* Saved Addresses */}
                <div className="p-5">
                  <p className="text-xs font-semibold uppercase tracking-wide mb-3" style={{ color: '#7A7A72' }}>
                    Saved Addresses ({detail.addresses.length})
                  </p>
                  {detail.addresses.length === 0 ? (
                    <p className="text-sm italic" style={{ color: '#9A9A90' }}>No saved addresses</p>
                  ) : (
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                      {detail.addresses.map((addr) => {
                        const lbl = ADDRESS_LABEL[addr.label ?? ''] ?? ADDRESS_LABEL['Other'];
                        const text = addr.address_line ?? addr.address ?? '—';
                        return (
                          <div
                            key={addr.id}
                            className="flex items-start gap-2.5 p-3 rounded-lg"
                            style={{ backgroundColor: '#F5F0E8' }}
                          >
                            <span className="text-base leading-none mt-0.5 flex-shrink-0">{lbl.emoji}</span>
                            <div className="min-w-0 flex-1">
                              <div className="flex items-center gap-1.5 flex-wrap mb-1">
                                <span
                                  className="inline-flex px-2 py-0.5 rounded-full text-xs font-semibold"
                                  style={{ backgroundColor: lbl.bg, color: lbl.color }}
                                >
                                  {addr.label || 'Other'}
                                </span>
                                {addr.is_default && (
                                  <span
                                    className="inline-flex items-center gap-0.5 px-2 py-0.5 rounded-full text-xs font-semibold"
                                    style={{ backgroundColor: '#FEF3C7', color: '#B45309' }}
                                  >
                                    ⭐ Default
                                  </span>
                                )}
                              </div>
                              <p className="text-sm leading-snug" style={{ color: '#2C2C2A' }}>{text}</p>
                              {addr.notes && (
                                <p className="text-xs mt-1 leading-snug" style={{ color: '#7A7A72' }}>{addr.notes}</p>
                              )}
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>

                {/* Booking History */}
                <div className="p-5">
                  <p className="text-xs font-semibold uppercase tracking-wide mb-4" style={{ color: '#7A7A72' }}>
                    Booking History ({detail.bookings.length})
                  </p>
                  {detail.bookings.length === 0 ? (
                    <p className="text-sm italic" style={{ color: '#9A9A90' }}>No bookings yet</p>
                  ) : (
                    <div className="overflow-x-auto">
                      <table className="w-full text-sm">
                        <thead>
                          <tr className="border-b" style={{ borderColor: '#EBE4D9' }}>
                            <th className="text-left pb-2.5 text-xs font-semibold" style={{ color: '#7A7A72' }}>Scheduled</th>
                            <th className="text-left pb-2.5 text-xs font-semibold" style={{ color: '#7A7A72' }}>Status</th>
                            <th className="text-left pb-2.5 text-xs font-semibold" style={{ color: '#7A7A72' }}>Payment</th>
                            <th className="text-right pb-2.5 text-xs font-semibold" style={{ color: '#7A7A72' }}>Total</th>
                          </tr>
                        </thead>
                        <tbody>
                          {detail.bookings.map((bk) => (
                            <tr key={bk.id} className="border-b last:border-0" style={{ borderColor: '#EBE4D9' }}>
                              <td className="py-2.5 pr-4 whitespace-nowrap text-sm" style={{ color: '#2C2C2A' }}>
                                {formatDate(bk.scheduled_at, true)}
                              </td>
                              <td className="py-2.5 pr-4">
                                <span className={cn('inline-flex px-2 py-0.5 rounded-full text-xs font-medium whitespace-nowrap', STATUS_COLORS[bk.status] ?? 'bg-stone-100 text-stone-600')}>
                                  {STATUS_LABELS[bk.status] ?? bk.status}
                                </span>
                              </td>
                              <td className="py-2.5 pr-4 text-sm capitalize whitespace-nowrap" style={{ color: '#5A5A52' }}>
                                {bk.payment_method.replace(/_/g, ' ')}
                              </td>
                              <td className="py-2.5 text-right font-medium text-sm whitespace-nowrap" style={{ color: '#2C2C2A' }}>
                                {formatRupiah(bk.total_amount)}
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>
      </td>
    </tr>
  );
}

// ── Main Page ─────────────────────────────────────────────────────────────────
export default function CustomersPage() {
  const [allCustomers, setAllCustomers] = useState<CustomerRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [detailCache, setDetailCache] = useState<Record<string, CustomerDetail>>({});
  const [addModal, setAddModal] = useState(false);
  const [editCustomer, setEditCustomer] = useState<CustomerRow | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [givePointsCustomer, setGivePointsCustomer] = useState<CustomerRow | null>(null);
  const [pointsMap, setPointsMap] = useState<Record<string, number>>({});

  const COLS = 6;

  useEffect(() => {
    loadCustomers();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // Reset to page 1 whenever search or pageSize changes
  useEffect(() => {
    setPage(1);
  }, [search, pageSize]);

  useRealtimeTable('customers-realtime', 'profiles', () => {
    loadCustomers();
  });

  async function refreshPoints() {
    const supabase = createClient();
    const { data } = await supabase.from('client_points').select('client_id, points_earned');
    const totals: Record<string, number> = {};
    for (const row of (data ?? []) as { client_id: string; points_earned: number }[]) {
      totals[row.client_id] = (totals[row.client_id] ?? 0) + (row.points_earned ?? 0);
    }
    setPointsMap(totals);
  }

  async function loadCustomers() {
    setLoading(true);
    try {
      const supabase = createClient();
      console.log('Fetching points for customers...');
      const [customersRes, { data: pointsData, error: pointsError }] = await Promise.all([
        fetch('/api/admin/customers'),
        supabase.from('client_points').select('client_id, points_earned'),
      ]);
      console.log('All points data:', pointsData);
      console.log('Points error:', pointsError);
      if (customersRes.ok) {
        const { customers } = await customersRes.json();
        setAllCustomers(customers ?? []);
      }
      const totals: Record<string, number> = {};
      for (const row of (pointsData ?? []) as { client_id: string; points_earned: number }[]) {
        totals[row.client_id] = (totals[row.client_id] ?? 0) + (row.points_earned ?? 0);
      }
      console.log('Points map built:', totals);
      setPointsMap(totals);
    } finally {
      setLoading(false);
    }
  }

  async function loadDetail(id: string) {
    setDetailCache((prev) => ({ ...prev, [id]: { loading: true, bookings: [], addresses: [] } }));
    const supabase = createClient();
    const [bookingsRes, addressesRes] = await Promise.all([
      supabase
        .from('bookings')
        .select('id, scheduled_at, status, total_amount, payment_method')
        .eq('client_id', id)
        .order('scheduled_at', { ascending: false })
        .limit(20),
      supabase
        .from('saved_addresses')
        .select('*')
        .eq('client_id', id)
        .order('is_default', { ascending: false }),
    ]);
    setDetailCache((prev) => ({
      ...prev,
      [id]: {
        loading: false,
        bookings: (bookingsRes.data as BookingRow[]) ?? [],
        addresses: (addressesRes.data as SavedAddress[]) ?? [],
      },
    }));
  }

  function toggleExpand(id: string) {
    if (expandedId === id) {
      setExpandedId(null);
    } else {
      setExpandedId(id);
      if (!detailCache[id]) loadDetail(id);
    }
  }

  async function handleDelete(c: CustomerRow) {
    const confirmed = window.confirm(
      `Are you sure you want to delete this customer?\n\n"${c.full_name || c.email}"\n\nThis will permanently delete their account and all data.`
    );
    if (!confirmed) return;
    setDeletingId(c.id);
    try {
      const res = await fetch('/api/admin/delete-user', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId: c.id }),
      });
      const json = await res.json();
      if (!res.ok || json.error) {
        alert(`Delete failed: ${json.error ?? res.status}`);
        return;
      }
      setAllCustomers((prev) => prev.filter((x) => x.id !== c.id));
      if (expandedId === c.id) setExpandedId(null);
    } finally {
      setDeletingId(null);
    }
  }

  // Client-side search filter
  const q = search.toLowerCase();
  const filtered = q
    ? allCustomers.filter(
        (c) =>
          (c.full_name ?? '').toLowerCase().includes(q) ||
          (c.email ?? '').toLowerCase().includes(q) ||
          (c.phone ?? '').toLowerCase().includes(q)
      )
    : allCustomers;

  const total = filtered.length;
  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  const paginated = filtered.slice((page - 1) * pageSize, page * pageSize);

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold" style={{ color: '#2C2C2A' }}>
          Customers
        </h1>
        <button
          onClick={() => setAddModal(true)}
          className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium text-white transition-colors"
          style={{ backgroundColor: '#4E523B' }}
          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
        >
          <Plus className="w-4 h-4" />
          Add New Customer
        </button>
      </div>

      {/* Search + Per-page */}
      <div className="flex items-center justify-between gap-3 flex-wrap">
        <input
          type="text"
          placeholder="Search by name, email, or phone…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="px-3 py-2 rounded-lg border text-sm w-72 focus:outline-none focus:ring-2 focus:ring-[#4E523B]"
          style={{ borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' }}
        />
        <div className="flex items-center gap-2">
          <span className="text-sm" style={{ color: '#7A7A72' }}>
            {loading ? '…' : `${total} customer${total !== 1 ? 's' : ''}`}
          </span>
          <select
            value={pageSize}
            onChange={(e) => setPageSize(Number(e.target.value))}
            className="px-3 py-2 rounded-lg border text-sm focus:outline-none focus:ring-2 focus:ring-[#4E523B]"
            style={{ borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' }}
          >
            {[10, 25, 50, 100].map((n) => (
              <option key={n} value={n}>
                {n} per page
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Table */}
      <div
        className="bg-white rounded-xl border shadow-sm overflow-hidden"
        style={{ borderColor: '#EBE4D9' }}
      >
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b" style={{ backgroundColor: '#F5F0E8', borderColor: '#EBE4D9' }}>
                <th className="w-8 px-4 py-3" />
                <th
                  className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wide"
                  style={{ color: '#7A7A72' }}
                >
                  Name
                </th>
                <th
                  className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wide"
                  style={{ color: '#7A7A72' }}
                >
                  Email
                </th>
                <th
                  className="text-left px-4 py-3 text-xs font-semibold uppercase tracking-wide"
                  style={{ color: '#7A7A72' }}
                >
                  Phone
                </th>
                <th
                  className="text-right px-4 py-3 text-xs font-semibold uppercase tracking-wide"
                  style={{ color: '#7A7A72' }}
                >
                  Points
                </th>
                <th
                  className="text-right px-4 py-3 text-xs font-semibold uppercase tracking-wide"
                  style={{ color: '#7A7A72' }}
                >
                  Actions
                </th>
              </tr>
            </thead>
            <tbody>
              {loading && (
                <tr>
                  <td colSpan={COLS} className="py-14 text-center">
                    <div className="flex justify-center">
                      <div
                        className="w-6 h-6 rounded-full border-4 animate-spin"
                        style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }}
                      />
                    </div>
                  </td>
                </tr>
              )}
              {!loading && paginated.length === 0 && (
                <tr>
                  <td
                    colSpan={COLS}
                    className="py-14 text-center text-sm"
                    style={{ color: '#9A9A90' }}
                  >
                    {search ? 'No customers match your search' : 'No customers found'}
                  </td>
                </tr>
              )}
              {!loading &&
                paginated.map((c) => {
                  const isExpanded = expandedId === c.id;
                  return [
                    <tr
                      key={c.id}
                      className="border-b transition-colors"
                      style={{
                        borderColor: '#EBE4D9',
                        backgroundColor: isExpanded ? '#FAF7F2' : undefined,
                      }}
                      onMouseEnter={(e) => {
                        if (!isExpanded)
                          (e.currentTarget as HTMLTableRowElement).style.backgroundColor =
                            '#FAF7F2';
                      }}
                      onMouseLeave={(e) => {
                        if (!isExpanded)
                          (e.currentTarget as HTMLTableRowElement).style.backgroundColor =
                            'transparent';
                      }}
                    >
                      {/* Expand toggle */}
                      <td className="px-4 py-3 w-8">
                        <button
                          onClick={() => toggleExpand(c.id)}
                          className="p-1 rounded-md transition-colors"
                          style={{ color: '#9A9A90' }}
                          onMouseEnter={(e) => {
                            (e.currentTarget as HTMLButtonElement).style.backgroundColor =
                              '#F0ECE5';
                          }}
                          onMouseLeave={(e) => {
                            (e.currentTarget as HTMLButtonElement).style.backgroundColor =
                              'transparent';
                          }}
                        >
                          {isExpanded ? (
                            <ChevronUp className="w-4 h-4" />
                          ) : (
                            <ChevronDown className="w-4 h-4" />
                          )}
                        </button>
                      </td>

                      {/* Name + Avatar */}
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2.5">
                          <Avatar name={c.full_name} url={c.avatar_url} />
                          <span className="font-medium" style={{ color: '#2C2C2A' }}>
                            {c.full_name || (
                              <span className="italic" style={{ color: '#9A9A90' }}>
                                No name
                              </span>
                            )}
                          </span>
                        </div>
                      </td>

                      <td className="px-4 py-3 text-sm" style={{ color: '#5A5A52' }}>
                        {c.email || '—'}
                      </td>
                      <td
                        className="px-4 py-3 text-sm whitespace-nowrap"
                        style={{ color: '#5A5A52' }}
                      >
                        {c.phone || '—'}
                      </td>

                      {/* Points */}
                      <td className="px-4 py-3 text-right">
                        <span
                          className="inline-flex items-center gap-1 text-sm font-semibold"
                          style={{ color: pointsMap[c.id] ? '#4E523B' : '#C5CAB0' }}
                        >
                          <Star className="w-3 h-3 flex-shrink-0" />
                          {(pointsMap[c.id] ?? 0).toLocaleString('id-ID')}
                        </span>
                      </td>

                      {/* Actions */}
                      <td className="px-4 py-3">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => setEditCustomer(c)}
                            className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium transition-colors"
                            style={{ backgroundColor: '#F0ECE5', color: '#3D3D38' }}
                            onMouseEnter={(e) => {
                              (e.currentTarget as HTMLButtonElement).style.backgroundColor =
                                '#EBE4D9';
                            }}
                            onMouseLeave={(e) => {
                              (e.currentTarget as HTMLButtonElement).style.backgroundColor =
                                '#F0ECE5';
                            }}
                          >
                            <Pencil className="w-3.5 h-3.5" />
                            Edit
                          </button>
                          <button
                            onClick={() => setGivePointsCustomer(c)}
                            className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium transition-colors"
                            style={{ backgroundColor: '#F0F2E8', color: '#4E523B' }}
                            onMouseEnter={(e) => {
                              (e.currentTarget as HTMLButtonElement).style.backgroundColor =
                                '#E8EBE0';
                            }}
                            onMouseLeave={(e) => {
                              (e.currentTarget as HTMLButtonElement).style.backgroundColor =
                                '#F0F2E8';
                            }}
                            title="Give points"
                          >
                            <Star className="w-3.5 h-3.5" />
                            Points
                          </button>
                          <button
                            onClick={() => handleDelete(c)}
                            disabled={deletingId === c.id}
                            className="flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-medium transition-colors disabled:opacity-40"
                            style={{ backgroundColor: '#FEF2F2', color: '#DC2626' }}
                            onMouseEnter={(e) => {
                              if (deletingId !== c.id)
                                (e.currentTarget as HTMLButtonElement).style.backgroundColor =
                                  '#FEE2E2';
                            }}
                            onMouseLeave={(e) => {
                              (e.currentTarget as HTMLButtonElement).style.backgroundColor =
                                '#FEF2F2';
                            }}
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                            {deletingId === c.id ? '…' : 'Delete'}
                          </button>
                        </div>
                      </td>
                    </tr>,

                    // Detail panel
                    ...(isExpanded && detailCache[c.id]
                      ? [
                          <CustomerDetailRow
                            key={`${c.id}-detail`}
                            customer={c}
                            detail={detailCache[c.id]}
                            colSpan={COLS}
                          />,
                        ]
                      : []),
                  ];
                })}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div
          className="flex items-center justify-between px-4 py-3 border-t"
          style={{ borderColor: '#EBE4D9' }}
        >
          <p className="text-sm" style={{ color: '#7A7A72' }}>
            {total === 0
              ? 'No customers'
              : `Showing ${(page - 1) * pageSize + 1}–${Math.min(page * pageSize, total)} of ${total}`}
          </p>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page === 1}
              className="flex items-center gap-1 px-3 py-1.5 rounded-lg border text-sm disabled:opacity-40 transition-colors"
              style={{ borderColor: '#EBE4D9', color: '#7A7A72', backgroundColor: 'white' }}
              onMouseEnter={(e) => {
                if (page !== 1)
                  (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5';
              }}
              onMouseLeave={(e) => {
                (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'white';
              }}
            >
              <ChevronLeft className="w-4 h-4" />
              Previous
            </button>
            <span className="text-sm px-1" style={{ color: '#2C2C2A' }}>
              {page} / {totalPages}
            </span>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="flex items-center gap-1 px-3 py-1.5 rounded-lg border text-sm disabled:opacity-40 transition-colors"
              style={{ borderColor: '#EBE4D9', color: '#7A7A72', backgroundColor: 'white' }}
              onMouseEnter={(e) => {
                if (page !== totalPages)
                  (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5';
              }}
              onMouseLeave={(e) => {
                (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'white';
              }}
            >
              Next
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Add Customer Modal */}
      {addModal && (
        <AddCustomerModal
          onClose={() => setAddModal(false)}
          onSaved={() => {
            loadCustomers();
            setSearch('');
            setPage(1);
          }}
        />
      )}

      {/* Edit Customer Modal */}
      {editCustomer && (
        <EditCustomerModal
          customer={editCustomer}
          onClose={() => setEditCustomer(null)}
          onSaved={(updated) => {
            setAllCustomers((prev) =>
              prev.map((c) => (c.id === updated.id ? { ...c, ...updated } : c))
            );
            setEditCustomer(null);
          }}
        />
      )}

      {/* Manage Points Modal */}
      {givePointsCustomer && (
        <GivePointsModal
          customer={givePointsCustomer}
          currentPoints={pointsMap[givePointsCustomer.id] ?? 0}
          onClose={() => setGivePointsCustomer(null)}
          onSaved={refreshPoints}
        />
      )}
    </div>
  );
}
