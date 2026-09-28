'use client';

import { useEffect, useRef, useState } from 'react';
import { Pencil, Trash2, X, Plus, Star, MessageSquare, Camera, Check } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { cn } from '@/lib/utils';
import type { TherapistProfile } from '@/types';
import { useRealtimeTable } from '@/lib/hooks/useRealtimeTable';

interface BranchOption { id: string; name: string; }
interface TherapistWithStatus extends TherapistProfile { status: string | null; }

function AvailabilityBadge({ isAvailable, status }: { isAvailable: boolean; status?: string | null }) {
  if (status === 'off')
    return (
      <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-medium" style={{ backgroundColor: '#F0ECE5', color: '#7A7A72' }}>
        <span className="w-1.5 h-1.5 rounded-full flex-shrink-0" style={{ backgroundColor: '#9A9A90' }} />
        Day Off
      </span>
    );
  if (status === 'break')
    return (
      <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-medium" style={{ backgroundColor: '#FEF3C7', color: '#B45309' }}>
        <span className="w-1.5 h-1.5 rounded-full flex-shrink-0 bg-orange-400" />
        On Break
      </span>
    );
  if (isAvailable)
    return (
      <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-medium" style={{ backgroundColor: '#E8EBE0', color: '#4E523B' }}>
        <span className="w-1.5 h-1.5 rounded-full flex-shrink-0" style={{ backgroundColor: '#4E523B' }} />
        Available
      </span>
    );
  return (
    <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-medium" style={{ backgroundColor: '#F0ECE5', color: '#7A7A72' }}>
      <span className="w-1.5 h-1.5 rounded-full flex-shrink-0" style={{ backgroundColor: '#9A9A90' }} />
      Unavailable
    </span>
  );
}

function initialsOf(name: string): string {
  const parts = name.trim().split(' ').filter(Boolean);
  return parts.length >= 2
    ? `${parts[0][0]}${parts[parts.length - 1][0]}`
    : parts[0]?.slice(0, 2) ?? '?';
}

const INPUT = 'w-full px-3 py-2 rounded-lg border text-sm focus:outline-none focus:ring-2 focus:ring-[#4E523B]';
const inputStyle = { borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' };
const labelStyle = { color: '#3D3D38' };

function TherapistModal({
  item,
  branches,
  onClose,
  onSaved,
}: {
  item: TherapistProfile | null;
  branches: BranchOption[];
  onClose: () => void;
  onSaved: () => void;
}) {
  const isEdit = item !== null;

  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [phone, setPhone] = useState('');

  const [bio, setBio] = useState(item?.bio ?? '');
  const [specialties, setSpecialties] = useState((item?.specialties ?? []).join(', '));
  const [branchId, setBranchId] = useState<string>(item?.branch_id ?? '');
  const [isAvailable, setIsAvailable] = useState(item?.is_available ?? true);

  const [avatarUrl, setAvatarUrl] = useState<string | null>(item?.profile?.avatar_url ?? null);
  const [uploadingPhoto, setUploadingPhoto] = useState(false);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [uploadSuccess, setUploadSuccess] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handlePhotoUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = '';
    if (!file || !item) return;

    if (!file.type.startsWith('image/')) {
      setUploadError('Please select an image file.');
      return;
    }

    setUploadError(null);
    setUploadSuccess(false);
    setUploadingPhoto(true);

    const supabase = createClient();
    const fileExt = file.name.split('.').pop();
    const fileName = `therapist-${item.profile_id}-${Date.now()}.${fileExt}`;

    const { error: uploadErr } = await supabase.storage
      .from('avatars')
      .upload(fileName, file, { upsert: true });

    if (uploadErr) {
      setUploadError(uploadErr.message);
      setUploadingPhoto(false);
      return;
    }

    const { data: urlData } = supabase.storage.from('avatars').getPublicUrl(fileName);
    const newAvatarUrl = urlData.publicUrl;

    const { error: profileErr } = await supabase
      .from('profiles')
      .update({ avatar_url: newAvatarUrl })
      .eq('id', item.profile_id);

    setUploadingPhoto(false);
    if (profileErr) {
      setUploadError(profileErr.message);
      return;
    }

    setAvatarUrl(newAvatarUrl);
    setUploadSuccess(true);
    onSaved();
  }

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
    const specs = specialties.split(',').map((s) => s.trim()).filter(Boolean);

    if (isEdit) {
      if (!email.trim()) { setError('Email is required.'); setSaving(false); return; }
      if (password && password.length < 6) { setError('Password must be at least 6 characters.'); setSaving(false); return; }
      if (password && password !== confirmPassword) { setError('Passwords do not match.'); setSaving(false); return; }

      const supabase = createClient();
      const [{ error: err }, { error: profileErr }, authRes] = await Promise.all([
        supabase.from('therapist_profiles').update({
          bio: bio || null,
          specialties: specs,
          branch_id: branchId || null,
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
      const res = await fetch('/api/admin/create-therapist', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: email.trim(),
          password,
          full_name: fullName.trim(),
          phone: phone.trim() || null,
          bio: bio || null,
          specialties: specs,
          branch_id: branchId || null,
          is_available: isAvailable,
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
            {isEdit ? 'Edit Therapist' : 'Add Therapist'}
          </h3>
          <button onClick={onClose} className="p-1 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="p-5 space-y-4">
          {isEdit && item && (
            <div className="flex items-center gap-4 pb-1">
              <div className="relative flex-shrink-0">
                {avatarUrl ? (
                  <img
                    src={avatarUrl}
                    alt={item.profile?.full_name ?? 'Therapist'}
                    className="w-16 h-16 rounded-full object-cover"
                  />
                ) : (
                  <div
                    className="w-16 h-16 rounded-full flex items-center justify-center text-lg font-bold uppercase text-white"
                    style={{ backgroundColor: '#4E523B' }}
                  >
                    {initialsOf(item.profile?.full_name ?? '')}
                  </div>
                )}
                {uploadingPhoto && (
                  <div className="absolute inset-0 rounded-full flex items-center justify-center" style={{ backgroundColor: 'rgba(0,0,0,0.45)' }}>
                    <div className="w-5 h-5 rounded-full border-2 border-white animate-spin" style={{ borderTopColor: 'transparent' }} />
                  </div>
                )}
              </div>
              <div className="flex-1 min-w-0">
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  onChange={handlePhotoUpload}
                  className="hidden"
                />
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={uploadingPhoto}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors disabled:opacity-60"
                  style={{ backgroundColor: '#F0ECE5', color: '#3D3D38' }}
                  onMouseEnter={(e) => { if (!uploadingPhoto) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#EBE4D9'; }}
                  onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
                >
                  <Camera className="w-3.5 h-3.5" />
                  {uploadingPhoto ? 'Uploading…' : 'Upload Photo'}
                </button>
                {uploadSuccess && !uploadingPhoto && (
                  <p className="flex items-center gap-1 text-xs mt-1.5" style={{ color: '#4E523B' }}>
                    <Check className="w-3 h-3" /> Photo updated
                  </p>
                )}
                {uploadError && (
                  <p className="text-xs mt-1.5 text-red-600">{uploadError}</p>
                )}
              </div>
            </div>
          )}

          {!isEdit && (
            <>
              <div>
                <label className="block text-sm font-medium mb-1.5" style={labelStyle}>Full Name</label>
                <input value={fullName} onChange={(e) => setFullName(e.target.value)} placeholder="Jane Doe" className={INPUT} style={inputStyle} />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1.5" style={labelStyle}>📞 Phone</label>
                <input type="tel" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+62 812 3456 7890" className={INPUT} style={inputStyle} />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1.5" style={labelStyle}>Email</label>
                <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="jane@example.com" className={INPUT} style={inputStyle} />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1.5" style={labelStyle}>Password</label>
                <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Min. 6 characters" className={INPUT} style={inputStyle} />
              </div>
            </>
          )}

          {isEdit && (
            <>
              <div>
                <label className="block text-sm font-medium mb-1.5" style={labelStyle}>Email</label>
                <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Loading…" className={INPUT} style={inputStyle} />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1.5" style={labelStyle}>
                  New Password <span className="font-normal" style={{ color: '#9A9A90' }}>(leave empty to keep current)</span>
                </label>
                <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Min. 6 characters" className={INPUT} style={inputStyle} />
              </div>
              {password && (
                <div>
                  <label className="block text-sm font-medium mb-1.5" style={labelStyle}>Confirm Password</label>
                  <input type="password" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} placeholder="Re-enter password" className={INPUT} style={inputStyle} />
                </div>
              )}
              <div>
                <label className="block text-sm font-medium mb-1.5" style={labelStyle}>📞 Phone</label>
                <input type="tel" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+62 812 3456 7890" className={INPUT} style={inputStyle} />
              </div>
            </>
          )}

          <div>
            <label className="block text-sm font-medium mb-1.5" style={labelStyle}>Branch</label>
            <select value={branchId} onChange={(e) => setBranchId(e.target.value)} className={INPUT} style={inputStyle}>
              <option value="">— No branch —</option>
              {branches.map((b) => (
                <option key={b.id} value={b.id}>{b.name}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1.5" style={labelStyle}>Bio</label>
            <textarea value={bio} onChange={(e) => setBio(e.target.value)} rows={3} className={cn(INPUT, 'resize-none')} style={inputStyle} />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1.5" style={labelStyle}>Specialties (comma-separated)</label>
            <input value={specialties} onChange={(e) => setSpecialties(e.target.value)} placeholder="Swedish, Deep Tissue, Aromatherapy" className={INPUT} style={inputStyle} />
          </div>

          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="therapistIsAvailable"
              checked={isAvailable}
              onChange={(e) => setIsAvailable(e.target.checked)}
              className="w-4 h-4 rounded"
              style={{ accentColor: '#4E523B' }}
            />
            <label htmlFor="therapistIsAvailable" className="text-sm" style={{ color: '#3D3D38' }}>
              Available
            </label>
          </div>

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
            {saving ? 'Saving…' : isEdit ? 'Save' : 'Create Therapist'}
          </button>
        </div>
      </div>
    </div>
  );
}

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

interface Review {
  id: string;
  rating: number;
  review_text: string | null;
  client_name: string;
  created_at: string;
}

function ReviewsModal({
  therapist,
  onClose,
}: {
  therapist: TherapistProfile;
  onClose: () => void;
}) {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const displayName = therapist.profile?.full_name ?? 'Unknown';

  useEffect(() => {
    (async () => {
      try {
        const res = await fetch('/api/admin/therapist-reviews', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ therapistProfileId: therapist.profile_id }),
        });
        const json = await res.json();
        if (!res.ok || json.error) { setError(json.error ?? `HTTP ${res.status}`); }
        else { setReviews(json.reviews ?? []); }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load reviews');
      } finally {
        setLoading(false);
      }
    })();
  }, [therapist.profile_id]);

  const avgRating = reviews.length
    ? reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length
    : 0;

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl border shadow-xl w-full max-w-lg max-h-[85vh] flex flex-col" style={{ borderColor: '#EBE4D9' }}>
        <div className="flex items-center justify-between px-5 py-4 border-b flex-shrink-0" style={{ borderColor: '#EBE4D9' }}>
          <div>
            <h3 className="font-semibold" style={{ color: '#2C2C2A' }}>Reviews — {displayName}</h3>
            {!loading && !error && (
              <div className="flex items-center gap-2 mt-0.5">
                <Stars rating={avgRating} />
                <span className="text-sm" style={{ color: '#7A7A72' }}>
                  {avgRating.toFixed(1)} · {reviews.length} {reviews.length === 1 ? 'review' : 'reviews'}
                </span>
              </div>
            )}
          </div>
          <button onClick={onClose} className="p-1 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="overflow-y-auto flex-1 p-4 space-y-3">
          {loading && (
            <div className="flex justify-center py-10">
              <div className="w-6 h-6 rounded-full border-4 border-t-transparent animate-spin" style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }} />
            </div>
          )}
          {!loading && error && (
            <p className="text-sm text-red-600 text-center py-8">{error}</p>
          )}
          {!loading && !error && reviews.length === 0 && (
            <div className="flex flex-col items-center justify-center py-12 gap-2" style={{ color: '#9A9A90' }}>
              <MessageSquare className="w-8 h-8" />
              <p className="text-sm">No reviews yet</p>
            </div>
          )}
          {!loading && !error && reviews.map((r) => (
            <div key={r.id} className="rounded-xl border p-4" style={{ borderColor: '#EBE4D9', backgroundColor: '#FAF7F2' }}>
              <div className="flex items-start justify-between gap-3 mb-2">
                <div>
                  <p className="text-sm font-medium" style={{ color: '#2C2C2A' }}>{r.client_name}</p>
                  <p className="text-xs mt-0.5" style={{ color: '#9A9A90' }}>
                    {new Date(r.created_at).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })}
                  </p>
                </div>
                <div className="flex items-center gap-1 flex-shrink-0">
                  <Stars rating={r.rating} />
                  <span className="text-xs font-medium ml-1" style={{ color: '#5A5A52' }}>{r.rating}</span>
                </div>
              </div>
              {r.review_text && (
                <p className="text-sm leading-relaxed" style={{ color: '#3D3D38' }}>{r.review_text}</p>
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function Initials({ name }: { name: string }) {
  return (
    <div className="w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0" style={{ backgroundColor: '#E8EBE0' }}>
      <span className="text-sm font-bold uppercase" style={{ color: '#4E523B' }}>{initialsOf(name)}</span>
    </div>
  );
}

export default function TherapistsPage() {
  const [therapists, setTherapists] = useState<TherapistWithStatus[]>([]);
  const [branches, setBranches] = useState<BranchOption[]>([]);
  const [branchMap, setBranchMap] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState<TherapistProfile | null | false>(false);
  const [reviewsTherapist, setReviewsTherapist] = useState<TherapistProfile | null>(null);

  useEffect(() => { loadAll(); }, []);

  useRealtimeTable('therapists-realtime', 'therapist_profiles', () => {
    loadAll();
  });

  async function loadAll() {
    setLoading(true);
    const supabase = createClient();

    const [{ data: tData }, { data: bData }, profilesRes] = await Promise.all([
      supabase
        .from('therapist_profiles')
        .select('id, profile_id, branch_id, bio, specialties, rating_avg, total_reviews, is_available, status'),
      supabase.from('branches').select('id, name').order('name'),
      fetch('/api/admin/profiles')
        .then((r) => (r.ok ? r.json() : []))
        .catch(() => []),
    ]);

    const branchList = (bData as BranchOption[] | null) ?? [];
    const map: Record<string, string> = {};
    for (const b of branchList) map[b.id] = b.name;

    const profileMap: Record<string, { full_name: string | null; avatar_url: string | null }> = {};
    for (const p of (profilesRes as { id: string; full_name: string | null; avatar_url: string | null }[])) {
      profileMap[p.id] = { full_name: p.full_name, avatar_url: p.avatar_url };
    }

    const merged: TherapistWithStatus[] = (tData ?? []).map((t: Record<string, unknown>) => ({
      ...(t as Omit<TherapistWithStatus, 'profile'>),
      profile: profileMap[t.profile_id as string] ?? null,
      status: (t.status as string | null) ?? null,
    }));

    setTherapists(merged);
    setBranches(branchList);
    setBranchMap(map);
    setLoading(false);
  }

  async function deleteTherapist(id: string) {
    if (!confirm('Delete this therapist profile?')) return;
    const supabase = createClient();
    await supabase.from('therapist_profiles').delete().eq('id', id);
    await loadAll();
  }

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold" style={{ color: '#2C2C2A' }}>Therapists</h1>
        <button
          onClick={() => setModal(null)}
          className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium text-white transition-colors"
          style={{ backgroundColor: '#4E523B' }}
          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
        >
          <Plus className="w-4 h-4" />
          Add Therapist
        </button>
      </div>

      <div className="bg-white rounded-xl border shadow-sm overflow-hidden" style={{ borderColor: '#EBE4D9' }}>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b" style={{ backgroundColor: '#FAF7F2', borderColor: '#EBE4D9' }}>
                <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Therapist</th>
                <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Branch</th>
                <th className="text-right px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Rating</th>
                <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Specialties</th>
                <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Status</th>
                <th className="px-5 py-3" />
              </tr>
            </thead>
            <tbody>
              {loading && Array.from({ length: 4 }).map((_, i) => (
                <tr key={i} className="border-t animate-pulse" style={{ borderColor: '#EBE4D9' }}>
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-full flex-shrink-0" style={{ backgroundColor: '#EBE4D9' }} />
                      <div className="h-3 w-32 rounded" style={{ backgroundColor: '#EBE4D9' }} />
                    </div>
                  </td>
                  <td className="px-5 py-4"><div className="h-3 w-20 rounded" style={{ backgroundColor: '#EBE4D9' }} /></td>
                  <td className="px-5 py-4 text-right"><div className="h-3 w-12 rounded ml-auto" style={{ backgroundColor: '#EBE4D9' }} /></td>
                  <td className="px-5 py-4"><div className="h-3 w-28 rounded" style={{ backgroundColor: '#EBE4D9' }} /></td>
                  <td className="px-5 py-4"><div className="h-5 w-20 rounded-full" style={{ backgroundColor: '#EBE4D9' }} /></td>
                  <td className="px-5 py-4" />
                </tr>
              ))}
              {!loading && therapists.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-5 py-10 text-center" style={{ color: '#9A9A90' }}>
                    No therapists found
                  </td>
                </tr>
              )}
              {!loading && therapists.map((t) => {
                const displayName = t.profile?.full_name ?? 'Unknown';
                const avatarUrl = t.profile?.avatar_url ?? null;
                const branchName = t.branch_id ? (branchMap[t.branch_id] ?? '—') : <span className="italic" style={{ color: '#9A9A90' }}>None</span>;
                return (
                  <tr key={t.id} className="border-t transition-colors" style={{ borderColor: '#EBE4D9' }}
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
                        <div>
                          <p className="font-medium" style={{ color: '#2C2C2A' }}>{displayName}</p>
                          {t.bio && (
                            <p className="text-xs truncate max-w-[200px]" style={{ color: '#9A9A90' }}>{t.bio}</p>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-3 whitespace-nowrap" style={{ color: '#3D3D38' }}>
                      {branchName}
                    </td>
                    <td className="px-5 py-3 text-right whitespace-nowrap" style={{ color: '#3D3D38' }}>
                      ★ {(t.rating_avg ?? 0).toFixed(1)}{' '}
                      <span className="text-xs" style={{ color: '#9A9A90' }}>({t.total_reviews ?? 0})</span>
                    </td>
                    <td className="px-5 py-3">
                      <div className="flex flex-wrap gap-1">
                        {(t.specialties ?? []).length === 0
                          ? <span className="italic text-xs" style={{ color: '#9A9A90' }}>—</span>
                          : (t.specialties ?? []).map((s) => (
                              <span key={s} className="inline-flex px-2 py-0.5 rounded-full text-xs bg-sky-100 text-sky-700">
                                {s}
                              </span>
                            ))}
                      </div>
                    </td>
                    <td className="px-5 py-3">
                      <AvailabilityBadge isAvailable={t.is_available} status={t.status} />
                    </td>
                    <td className="px-5 py-3">
                      <div className="flex justify-end gap-2">
                        <button
                          onClick={() => setReviewsTherapist(t)}
                          className="p-1.5 rounded-lg text-amber-500 transition-colors"
                          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#FEF3C7'; }}
                          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
                          title="View reviews"
                        >
                          <Star className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => setModal(t)}
                          className="p-1.5 rounded-lg transition-colors"
                          style={{ color: '#9A9A90' }}
                          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
                          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
                          title="Edit"
                        >
                          <Pencil className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => deleteTherapist(t.id)}
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
      </div>

      {modal !== false && (
        <TherapistModal
          item={modal}
          branches={branches}
          onClose={() => setModal(false)}
          onSaved={loadAll}
        />
      )}

      {reviewsTherapist && (
        <ReviewsModal
          therapist={reviewsTherapist}
          onClose={() => setReviewsTherapist(null)}
        />
      )}
    </div>
  );
}
