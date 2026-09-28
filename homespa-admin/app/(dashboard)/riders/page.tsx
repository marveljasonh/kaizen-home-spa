'use client';

import { useEffect, useState } from 'react';
import { Pencil, Trash2, X, Plus } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { cn } from '@/lib/utils';
import type { RiderProfile } from '@/types';

const INPUT = 'w-full px-3 py-2 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#4E523B] border';
const LABEL = 'block text-sm font-medium mb-1.5';

const inputStyle = { borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' };
const labelStyle = { color: '#3D3D38' };

function RiderModal({
  item,
  onClose,
  onSaved,
}: {
  item: RiderProfile | null;
  onClose: () => void;
  onSaved: () => void;
}) {
  const isEdit = item !== null;

  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [phone, setPhone] = useState('');

  const [vehicleType, setVehicleType] = useState(item?.vehicle_type ?? '');
  const [plateNumber, setPlateNumber] = useState(item?.plate_number ?? '');
  const [isAvailable, setIsAvailable] = useState(item?.is_available ?? true);

  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!isEdit) return;
    const supabase = createClient();
    Promise.all([
      supabase.from('profiles').select('phone').eq('id', item.profile_id).single(),
      fetch(`/api/admin/update-user?userId=${item.profile_id}`).then((r) => r.json()),
    ]).then(([profileRes, userRes]) => {
      if (profileRes.data?.phone) setPhone(profileRes.data.phone);
      if (userRes.email) setEmail(userRes.email);
    });
  }, []);

  async function handleSave() {
    setSaving(true);
    setError(null);

    if (isEdit) {
      if (!email.trim()) { setError('Email is required.'); setSaving(false); return; }
      if (password && password.length < 6) { setError('Password must be at least 6 characters.'); setSaving(false); return; }
      if (password && password !== confirmPassword) { setError('Passwords do not match.'); setSaving(false); return; }

      const supabase = createClient();
      const [{ error: err }, { error: profileErr }, authRes] = await Promise.all([
        supabase.from('rider_profiles').update({
          vehicle_type: vehicleType || null,
          plate_number: plateNumber || null,
          is_available: isAvailable,
        }).eq('id', item.id),
        supabase.from('profiles').update({ phone: phone.trim() || null }).eq('id', item.profile_id),
        fetch('/api/admin/update-user', {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ userId: item.profile_id, email: email.trim(), password: password || undefined }),
        }).then((r) => r.json()),
      ]);

      if (err || profileErr) { setError((err ?? profileErr)!.message); setSaving(false); return; }
      if (authRes.error) { setError(`Account update failed: ${authRes.error}`); setSaving(false); return; }
    } else {
      if (!fullName.trim() || !email.trim()) {
        setError('Full name and email are required.');
        setSaving(false);
        return;
      }
      if (password.length < 6) {
        setError('Password must be at least 6 characters.');
        setSaving(false);
        return;
      }

      const res = await fetch('/api/admin/create-rider', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: email.trim(),
          password,
          full_name: fullName.trim(),
          phone: phone.trim() || null,
        }),
      });
      const json = await res.json();
      if (!res.ok || json.error) { setError(json.error ?? `HTTP ${res.status}`); setSaving(false); return; }
    }

    setSaving(false);
    onSaved();
    onClose();
  }

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl border shadow-xl w-full max-w-md" style={{ borderColor: '#EBE4D9' }}>
        <div className="flex items-center justify-between px-5 py-4 border-b" style={{ borderColor: '#EBE4D9' }}>
          <h3 className="font-semibold" style={{ color: '#2C2C2A' }}>
            {isEdit ? 'Edit Rider' : 'Add Rider'}
          </h3>
          <button onClick={onClose} className="p-1 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="p-5 space-y-4">
          {!isEdit && (
            <>
              <div>
                <label className={LABEL} style={labelStyle}>Full Name</label>
                <input value={fullName} onChange={(e) => setFullName(e.target.value)} placeholder="John Doe" className={INPUT} style={inputStyle} />
              </div>
              <div>
                <label className={LABEL} style={labelStyle}>Email</label>
                <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="john@example.com" className={INPUT} style={inputStyle} />
              </div>
              <div>
                <label className={LABEL} style={labelStyle}>Password</label>
                <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Min. 6 characters" className={INPUT} style={inputStyle} />
              </div>
              <div>
                <label className={LABEL} style={labelStyle}>
                  Phone <span className="font-normal" style={{ color: '#9A9A90' }}>(optional)</span>
                </label>
                <input type="tel" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+62 812 3456 7890" className={INPUT} style={inputStyle} />
              </div>
            </>
          )}

          {isEdit && (
            <>
              <div>
                <label className={LABEL} style={labelStyle}>Email</label>
                <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Loading…" className={INPUT} style={inputStyle} />
              </div>
              <div>
                <label className={LABEL} style={labelStyle}>
                  New Password <span className="font-normal" style={{ color: '#9A9A90' }}>(leave empty to keep current)</span>
                </label>
                <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Min. 6 characters" className={INPUT} style={inputStyle} />
              </div>
              {password && (
                <div>
                  <label className={LABEL} style={labelStyle}>Confirm Password</label>
                  <input type="password" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} placeholder="Re-enter password" className={INPUT} style={inputStyle} />
                </div>
              )}
              <div>
                <label className={LABEL} style={labelStyle}>📞 Phone</label>
                <input type="tel" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+62 812 3456 7890" className={INPUT} style={inputStyle} />
              </div>
              <div>
                <label className={LABEL} style={labelStyle}>Vehicle Type</label>
                <input value={vehicleType} onChange={(e) => setVehicleType(e.target.value)} placeholder="Motorcycle, Car…" className={INPUT} style={inputStyle} />
              </div>
              <div>
                <label className={LABEL} style={labelStyle}>Plate Number</label>
                <input value={plateNumber} onChange={(e) => setPlateNumber(e.target.value)} placeholder="B 1234 XYZ" className={INPUT} style={inputStyle} />
              </div>
              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="riderIsAvailable"
                  checked={isAvailable}
                  onChange={(e) => setIsAvailable(e.target.checked)}
                  className="w-4 h-4 rounded"
                  style={{ accentColor: '#4E523B' }}
                />
                <label htmlFor="riderIsAvailable" className="text-sm" style={{ color: '#3D3D38' }}>
                  Available
                </label>
              </div>
            </>
          )}

          {error && <p className="text-sm text-red-600">{error}</p>}
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
            disabled={saving}
            className="px-4 py-2 rounded-lg text-sm font-medium text-white disabled:opacity-60 transition-colors"
            style={{ backgroundColor: '#4E523B' }}
            onMouseEnter={(e) => { if (!saving) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
          >
            {saving ? 'Saving…' : isEdit ? 'Save' : 'Create Rider'}
          </button>
        </div>
      </div>
    </div>
  );
}

function Initials({ name }: { name: string }) {
  const parts = name.trim().split(' ');
  const initials = parts.length >= 2
    ? `${parts[0][0]}${parts[parts.length - 1][0]}`
    : parts[0]?.slice(0, 2) ?? '?';
  return (
    <div className="w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0" style={{ backgroundColor: '#E8EBE0' }}>
      <span className="text-sm font-bold uppercase" style={{ color: '#4E523B' }}>{initials}</span>
    </div>
  );
}

export default function RidersPage() {
  const [riders, setRiders] = useState<RiderProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState<RiderProfile | null | false>(false);

  useEffect(() => { loadRiders(); }, []);

  async function loadRiders() {
    setLoading(true);
    const supabase = createClient();
    const { data } = await supabase
      .from('rider_profiles')
      .select('id, profile_id, branch_id, vehicle_type, plate_number, is_available, profile:profiles(full_name, avatar_url)');
    setRiders((data as unknown as RiderProfile[]) ?? []);
    setLoading(false);
  }

  async function deleteRider(id: string) {
    if (!confirm('Delete this rider?')) return;
    const supabase = createClient();
    await supabase.from('rider_profiles').delete().eq('id', id);
    await loadRiders();
  }

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold" style={{ color: '#2C2C2A' }}>Riders</h1>
        <button
          onClick={() => setModal(null)}
          className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium text-white transition-colors"
          style={{ backgroundColor: '#4E523B' }}
          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
        >
          <Plus className="w-4 h-4" />
          Add Rider
        </button>
      </div>

      <div className="bg-white rounded-xl border shadow-sm overflow-hidden" style={{ borderColor: '#EBE4D9' }}>
        {loading ? (
          <div className="flex items-center justify-center h-40">
            <div className="w-7 h-7 rounded-full border-4 border-t-transparent animate-spin" style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }} />
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b" style={{ backgroundColor: '#FAF7F2', borderColor: '#EBE4D9' }}>
                  <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Rider</th>
                  <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Vehicle</th>
                  <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Plate</th>
                  <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Status</th>
                  <th className="px-5 py-3" />
                </tr>
              </thead>
              <tbody>
                {riders.length === 0 && (
                  <tr>
                    <td colSpan={5} className="px-5 py-10 text-center" style={{ color: '#9A9A90' }}>
                      No riders found
                    </td>
                  </tr>
                )}
                {riders.map((r) => {
                  const displayName = r.profile?.full_name ?? 'Unknown';
                  const avatarUrl = r.profile?.avatar_url ?? null;
                  return (
                    <tr key={r.id} className="border-t transition-colors" style={{ borderColor: '#EBE4D9' }}
                      onMouseEnter={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = '#FAF7F2'; }}
                      onMouseLeave={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = 'transparent'; }}
                    >
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-3">
                          {avatarUrl ? (
                            <img src={avatarUrl} alt={displayName} className="w-9 h-9 rounded-full object-cover flex-shrink-0" />
                          ) : (
                            <Initials name={displayName} />
                          )}
                          <p className="font-medium" style={{ color: '#2C2C2A' }}>{displayName}</p>
                        </div>
                      </td>
                      <td className="px-5 py-3" style={{ color: '#5A5A52' }}>{r.vehicle_type ?? '—'}</td>
                      <td className="px-5 py-3 font-mono text-xs" style={{ color: '#5A5A52' }}>{r.plate_number ?? '—'}</td>
                      <td className="px-5 py-3">
                        <span
                          className="inline-flex px-2 py-0.5 rounded-full text-xs font-medium"
                          style={
                            r.is_available
                              ? { backgroundColor: '#E8EBE0', color: '#4E523B' }
                              : { backgroundColor: '#F0ECE5', color: '#7A7A72' }
                          }
                        >
                          {r.is_available ? 'Available' : 'Unavailable'}
                        </span>
                      </td>
                      <td className="px-5 py-3">
                        <div className="flex justify-end gap-2">
                          <button
                            onClick={() => setModal(r)}
                            className="p-1.5 rounded-lg transition-colors"
                            style={{ color: '#9A9A90' }}
                            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
                            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
                            title="Edit"
                          >
                            <Pencil className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => deleteRider(r.id)}
                            className="p-1.5 rounded-lg text-red-400 transition-colors"
                            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#FEF2F2'; }}
                            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
                            title="Delete"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {modal !== false && (
        <RiderModal item={modal} onClose={() => setModal(false)} onSaved={loadRiders} />
      )}
    </div>
  );
}
