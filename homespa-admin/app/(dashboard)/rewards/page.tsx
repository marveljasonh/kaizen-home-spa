'use client';

import { useEffect, useState } from 'react';
import { Plus, Pencil, Trash2, X, AlertCircle } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { adminMutate } from '@/lib/adminMutate';
import { formatRupiah } from '@/lib/utils';
import type { Treatment } from '@/types';

interface TreatmentDuration {
  id: string;
  duration_minutes: number;
  price: number;
}

interface Reward {
  id: string;
  title: string;
  description: string | null;
  points_required: number;
  reward_type: 'free_treatment' | 'discount_flat' | 'discount_percentage';
  reward_treatment_id: string | null;
  reward_treatment_duration_id: string | null;
  reward_value: number | null;
  max_redemptions: number | null;
  total_redeemed: number;
  is_active: boolean;
  created_at: string;
}

const INPUT = 'w-full px-3 py-2 rounded-lg border text-sm focus:outline-none focus:ring-2 focus:ring-[#4E523B]';
const LABEL = 'block text-sm font-medium mb-1.5';
const inputStyle = { borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' };
const labelStyle: React.CSSProperties = { color: '#3D3D38' };
const BTN_PRIMARY = 'px-4 py-2 rounded-lg text-sm font-medium text-white disabled:opacity-60 transition-colors';
const BTN_GHOST = 'px-4 py-2 rounded-lg text-sm font-medium transition-colors';

const REWARD_TYPE_LABELS: Record<string, string> = {
  free_treatment: 'Free Treatment',
  discount_flat: 'Flat Discount',
  discount_percentage: '% Discount',
};

function ErrorBanner({ message }: { message: string }) {
  return (
    <div className="flex items-start gap-2 px-4 py-3 rounded-lg border border-red-200 text-red-700 text-sm"
      style={{ backgroundColor: '#FEF2F2' }}>
      <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
      <span>{message}</span>
    </div>
  );
}

function RewardModal({
  item,
  treatments,
  onClose,
  onSaved,
}: {
  item: Partial<Reward> | null;
  treatments: Treatment[];
  onClose: () => void;
  onSaved: () => void;
}) {
  const isEdit = !!item?.id;

  const [title, setTitle] = useState(item?.title ?? '');
  const [description, setDescription] = useState(item?.description ?? '');
  const [pointsRequired, setPointsRequired] = useState(String(item?.points_required ?? ''));
  const [rewardType, setRewardType] = useState<Reward['reward_type']>(item?.reward_type ?? 'free_treatment');
  const [treatmentId, setTreatmentId] = useState(item?.reward_treatment_id ?? '');
  const [durationId, setDurationId] = useState(item?.reward_treatment_duration_id ?? '');
  const [durations, setDurations] = useState<TreatmentDuration[]>([]);
  const [discountValue, setDiscountValue] = useState(String(item?.reward_value ?? ''));
  const [maxRedemptions, setMaxRedemptions] = useState(item?.max_redemptions != null ? String(item.max_redemptions) : '');
  const [isActive, setIsActive] = useState(item?.is_active ?? true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!treatmentId) { setDurations([]); return; }
    const supabase = createClient();
    supabase
      .from('treatment_durations')
      .select('id, duration_minutes, price')
      .eq('treatment_id', treatmentId)
      .order('duration_minutes')
      .then(({ data }) => setDurations((data as TreatmentDuration[]) ?? []));
  }, [treatmentId]);

  async function handleSave() {
    if (!title.trim()) { setError('Title is required'); return; }
    if (!pointsRequired || Number(pointsRequired) < 0) { setError('Points required must be 0 or more'); return; }
    if (rewardType === 'free_treatment' && !treatmentId) { setError('Please select a treatment'); return; }
    if (rewardType === 'free_treatment' && treatmentId && !durationId) { setError('Please select a duration'); return; }
    if ((rewardType === 'discount_flat' || rewardType === 'discount_percentage') && !discountValue) {
      setError('Please enter a discount value'); return;
    }

    setSaving(true);
    setError(null);

    const payload: Record<string, unknown> = {
      title: title.trim(),
      description: description.trim() || null,
      points_required: Number(pointsRequired),
      reward_type: rewardType,
      reward_treatment_id: rewardType === 'free_treatment' ? treatmentId : null,
      reward_treatment_duration_id: rewardType === 'free_treatment' ? (durationId || null) : null,
      reward_value: (rewardType === 'discount_flat' || rewardType === 'discount_percentage')
        ? Number(discountValue) : null,
      max_redemptions: maxRedemptions !== '' ? Number(maxRedemptions) : null,
      is_active: isActive,
    };

    const result = isEdit
      ? await adminMutate('rewards', 'update', payload, { id: item!.id })
      : await adminMutate('rewards', 'insert', payload);

    setSaving(false);
    if (result.error) { setError(result.error); return; }
    onSaved();
    onClose();
  }

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl border shadow-xl w-full max-w-lg max-h-[92vh] flex flex-col"
        style={{ borderColor: '#EBE4D9' }}>
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b flex-shrink-0"
          style={{ borderColor: '#EBE4D9' }}>
          <h3 className="font-semibold" style={{ color: '#2C2C2A' }}>
            {isEdit ? 'Edit Reward' : 'Add Reward'}
          </h3>
          <button onClick={onClose} className="p-1 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Body */}
        <div className="p-5 space-y-4 overflow-y-auto flex-1">
          {error && <ErrorBanner message={error} />}

          <div>
            <label className={LABEL} style={labelStyle}>Title *</label>
            <input autoFocus value={title} onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Free 60-min Massage" className={INPUT} style={inputStyle} />
          </div>

          <div>
            <label className={LABEL} style={labelStyle}>Description</label>
            <textarea value={description} onChange={(e) => setDescription(e.target.value)} rows={2}
              placeholder="Optional — shown to users in the app"
              className={INPUT} style={{ ...inputStyle, resize: 'vertical' as const }} />
          </div>

          <div>
            <label className={LABEL} style={labelStyle}>Points Required *</label>
            <input type="number" min={0} value={pointsRequired}
              onChange={(e) => setPointsRequired(e.target.value)}
              placeholder="e.g. 500" className={INPUT} style={inputStyle} />
          </div>

          <div className="border-t" style={{ borderColor: '#EBE4D9' }} />

          <div>
            <label className={LABEL} style={labelStyle}>Reward Type</label>
            <select value={rewardType}
              onChange={(e) => {
                setRewardType(e.target.value as Reward['reward_type']);
                setTreatmentId('');
                setDiscountValue('');
              }}
              className={INPUT} style={inputStyle}
            >
              <option value="free_treatment">Free Treatment</option>
              <option value="discount_flat">Flat Discount (IDR)</option>
              <option value="discount_percentage">Percentage Discount (%)</option>
            </select>
          </div>

          {rewardType === 'free_treatment' && (
            <div>
              <label className={LABEL} style={labelStyle}>Treatment *</label>
              <select
                value={treatmentId}
                onChange={(e) => { setTreatmentId(e.target.value); setDurationId(''); }}
                className={INPUT}
                style={inputStyle}
              >
                <option value="">Select treatment…</option>
                {treatments.map((t) => (
                  <option key={t.id} value={t.id}>{t.name}</option>
                ))}
              </select>
            </div>
          )}

          {rewardType === 'free_treatment' && treatmentId && (
            <div>
              <label className={LABEL} style={labelStyle}>Duration *</label>
              {durations.length === 0 ? (
                <p className="text-sm italic" style={{ color: '#9A9A90' }}>No durations found for this treatment.</p>
              ) : (
                <select value={durationId} onChange={(e) => setDurationId(e.target.value)}
                  className={INPUT} style={inputStyle}>
                  <option value="">Select duration…</option>
                  {durations.map((d) => (
                    <option key={d.id} value={d.id}>
                      {d.duration_minutes} min — {formatRupiah(d.price)}
                    </option>
                  ))}
                </select>
              )}
            </div>
          )}

          {rewardType === 'discount_flat' && (
            <div>
              <label className={LABEL} style={labelStyle}>Discount Amount (IDR) *</label>
              <input type="number" min={0} value={discountValue}
                onChange={(e) => setDiscountValue(e.target.value)}
                placeholder="e.g. 50000" className={INPUT} style={inputStyle} />
            </div>
          )}

          {rewardType === 'discount_percentage' && (
            <div>
              <label className={LABEL} style={labelStyle}>Discount Percentage (%) *</label>
              <input type="number" min={0} max={100} value={discountValue}
                onChange={(e) => setDiscountValue(e.target.value)}
                placeholder="e.g. 20" className={INPUT} style={inputStyle} />
            </div>
          )}

          <div className="border-t" style={{ borderColor: '#EBE4D9' }} />

          <div>
            <label className={LABEL} style={labelStyle}>
              Max Redemptions{' '}
              <span className="font-normal text-xs" style={{ color: '#9A9A90' }}>(leave empty = unlimited)</span>
            </label>
            <input type="number" min={1} value={maxRedemptions}
              onChange={(e) => setMaxRedemptions(e.target.value)}
              placeholder="Unlimited" className={INPUT} style={inputStyle} />
          </div>

          <label className="flex items-center gap-2 cursor-pointer">
            <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)}
              className="w-4 h-4 rounded" style={{ accentColor: '#4E523B' }} />
            <span className="text-sm" style={{ color: '#3D3D38' }}>Active</span>
          </label>
        </div>

        {/* Footer */}
        <div className="flex justify-end gap-2 px-5 py-4 border-t flex-shrink-0"
          style={{ borderColor: '#EBE4D9' }}>
          <button onClick={onClose} className={BTN_GHOST}
            style={{ backgroundColor: '#F0ECE5', color: '#3D3D38' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#EBE4D9'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
          >Cancel</button>
          <button onClick={handleSave} disabled={saving} className={BTN_PRIMARY}
            style={{ backgroundColor: '#4E523B' }}
            onMouseEnter={(e) => { if (!saving) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
          >{saving ? 'Saving…' : 'Save'}</button>
        </div>
      </div>
    </div>
  );
}

function ManageRewardModal({
  reward,
  onClose,
  onDeactivated,
  onDeleted,
}: {
  reward: Reward;
  onClose: () => void;
  onDeactivated: () => void;
  onDeleted: () => void;
}) {
  const [redemptionCount, setRedemptionCount] = useState<number | null>(null);
  const [working, setWorking] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const supabase = createClient();
    supabase
      .from('reward_redemptions')
      .select('id', { count: 'exact', head: true })
      .eq('reward_id', reward.id)
      .then(({ count }) => setRedemptionCount(count ?? 0));
  }, [reward.id]);

  async function handleDeactivate() {
    setWorking(true);
    setError(null);
    const result = await adminMutate('rewards', 'update', { is_active: false }, { id: reward.id });
    setWorking(false);
    if (result.error) { setError(result.error); return; }
    onDeactivated();
    onClose();
  }

  async function handleDeletePermanently() {
    setWorking(true);
    setError(null);
    if ((redemptionCount ?? 0) > 0) {
      const r1 = await adminMutate('reward_redemptions', 'delete', undefined, { reward_id: reward.id });
      if (r1.error) { setError(r1.error); setWorking(false); return; }
    }
    const r2 = await adminMutate('rewards', 'delete', undefined, { id: reward.id });
    setWorking(false);
    if (r2.error) { setError(r2.error); return; }
    onDeleted();
    onClose();
  }

  const loading = redemptionCount === null;
  const hasRedemptions = (redemptionCount ?? 0) > 0;

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl border shadow-xl w-full max-w-md" style={{ borderColor: '#EBE4D9' }}>
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b" style={{ borderColor: '#EBE4D9' }}>
          <h3 className="font-semibold" style={{ color: '#2C2C2A' }}>Manage Reward</h3>
          <button onClick={onClose} className="p-1 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Body */}
        <div className="px-5 py-5 space-y-4">
          {/* Reward summary */}
          <div className="rounded-lg px-4 py-3" style={{ backgroundColor: '#FAF7F2', border: '1px solid #EBE4D9' }}>
            <p className="font-medium text-sm" style={{ color: '#2C2C2A' }}>{reward.title}</p>
            <p className="text-xs mt-0.5" style={{ color: '#7A7A72' }}>
              {reward.points_required.toLocaleString('id-ID')} pts · {REWARD_TYPE_LABELS[reward.reward_type]}
            </p>
          </div>

          {loading ? (
            <div className="flex items-center gap-2 text-sm" style={{ color: '#7A7A72' }}>
              <div className="w-4 h-4 rounded-full border-2 animate-spin flex-shrink-0"
                style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }} />
              Checking redemption history…
            </div>
          ) : hasRedemptions ? (
            <>
              {/* Redemption warning */}
              <div className="flex items-start gap-3 px-4 py-3 rounded-lg border"
                style={{ backgroundColor: '#FFFBEB', borderColor: '#FDE68A' }}>
                <AlertCircle className="w-4 h-4 flex-shrink-0 mt-0.5" style={{ color: '#92400E' }} />
                <p className="text-sm" style={{ color: '#92400E' }}>
                  This reward has been redeemed by{' '}
                  <span className="font-bold">{redemptionCount} client{redemptionCount !== 1 ? 's' : ''}</span>.
                  {' '}Deleting will remove all redemption history.
                </p>
              </div>

              {/* Deactivate option */}
              <div className="rounded-lg border p-4 space-y-2.5" style={{ borderColor: '#EBE4D9' }}>
                <div>
                  <p className="text-sm font-semibold" style={{ color: '#2C2C2A' }}>
                    Deactivate
                    <span className="ml-2 text-xs font-normal px-1.5 py-0.5 rounded-full"
                      style={{ backgroundColor: '#E8EBE0', color: '#4E523B' }}>
                      Recommended
                    </span>
                  </p>
                  <p className="text-xs mt-1" style={{ color: '#7A7A72' }}>
                    Safe option — clients keep their redeemed rewards. Reward won&apos;t appear to new clients.
                  </p>
                </div>
                <button
                  onClick={handleDeactivate}
                  disabled={working}
                  className="w-full px-4 py-2 rounded-lg text-sm font-medium text-white disabled:opacity-60 transition-colors"
                  style={{ backgroundColor: '#4E523B' }}
                  onMouseEnter={(e) => { if (!working) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
                  onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
                >
                  {working ? 'Working…' : 'Deactivate Reward'}
                </button>
              </div>

              {/* Delete permanently option */}
              <div className="rounded-lg border p-4 space-y-2.5" style={{ borderColor: '#FCA5A5' }}>
                <div>
                  <p className="text-sm font-semibold" style={{ color: '#DC2626' }}>Delete Permanently</p>
                  <p className="text-xs mt-1" style={{ color: '#7A7A72' }}>
                    Removes the reward and all {redemptionCount} redemption record{redemptionCount !== 1 ? 's' : ''}.
                    {' '}This cannot be undone.
                  </p>
                </div>
                <button
                  onClick={handleDeletePermanently}
                  disabled={working}
                  className="w-full px-4 py-2 rounded-lg text-sm font-medium text-white disabled:opacity-60 transition-colors"
                  style={{ backgroundColor: '#DC2626' }}
                  onMouseEnter={(e) => { if (!working) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#B91C1C'; }}
                  onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#DC2626'; }}
                >
                  {working ? 'Deleting…' : 'Delete Permanently'}
                </button>
              </div>
            </>
          ) : (
            <>
              <p className="text-sm" style={{ color: '#5A5A52' }}>
                Are you sure you want to delete{' '}
                <span className="font-semibold">&ldquo;{reward.title}&rdquo;</span>?
                This reward has no redemptions, so no history will be lost.
              </p>
              <button
                onClick={handleDeletePermanently}
                disabled={working}
                className="w-full px-4 py-2 rounded-lg text-sm font-medium text-white disabled:opacity-60 transition-colors"
                style={{ backgroundColor: '#DC2626' }}
                onMouseEnter={(e) => { if (!working) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#B91C1C'; }}
                onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#DC2626'; }}
              >
                {working ? 'Deleting…' : 'Delete Reward'}
              </button>
            </>
          )}

          {error && <ErrorBanner message={error} />}
        </div>

        {/* Footer */}
        <div className="flex justify-end px-5 py-4 border-t" style={{ borderColor: '#EBE4D9' }}>
          <button
            onClick={onClose}
            className="px-4 py-2 rounded-lg text-sm font-medium transition-colors"
            style={{ backgroundColor: '#F0ECE5', color: '#3D3D38' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#EBE4D9'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
}

export default function RewardsPage() {
  const [rewards, setRewards] = useState<Reward[]>([]);
  const [treatments, setTreatments] = useState<Treatment[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState<Partial<Reward> | null | false>(false);
  const [manageModal, setManageModal] = useState<Reward | null>(null);

  useEffect(() => { loadAll(); }, []);

  async function loadAll() {
    setLoading(true);
    const supabase = createClient();
    const [{ data: r }, { data: t }] = await Promise.all([
      supabase.from('rewards').select('*').order('points_required'),
      supabase.from('treatments').select('id, name').eq('is_active', true).order('name'),
    ]);
    setRewards((r as Reward[]) ?? []);
    setTreatments((t as Treatment[]) ?? []);
    setLoading(false);
  }

  const treatmentMap = Object.fromEntries(treatments.map((t) => [t.id, t.name]));

  function valueLabel(r: Reward) {
    if (r.reward_type === 'free_treatment') return treatmentMap[r.reward_treatment_id ?? ''] ?? '—';
    if (r.reward_type === 'discount_flat') return formatRupiah(r.reward_value ?? 0) + ' OFF';
    if (r.reward_type === 'discount_percentage') return `${r.reward_value ?? 0}% OFF`;
    return '—';
  }

  const COLS = ['Title', 'Points Required', 'Reward Type', 'Value', 'Max Redemptions', 'Total Redeemed', 'Status', ''] as const;

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold" style={{ color: '#2C2C2A' }}>Rewards</h1>
        <button
          onClick={() => setModal({})}
          className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium text-white transition-colors"
          style={{ backgroundColor: '#4E523B' }}
          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
        >
          <Plus className="w-4 h-4" /> Add Reward
        </button>
      </div>

      {loading ? (
        <div className="flex items-center justify-center h-40">
          <div className="w-7 h-7 rounded-full border-4 border-t-transparent animate-spin"
            style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }} />
        </div>
      ) : (
        <div className="bg-white rounded-xl border shadow-sm overflow-hidden" style={{ borderColor: '#EBE4D9' }}>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b" style={{ backgroundColor: '#FAF7F2', borderColor: '#EBE4D9' }}>
                  {COLS.map((h) => (
                    <th key={h}
                      className={`px-5 py-3 text-xs font-semibold uppercase tracking-wide ${h ? 'text-left' : ''}`}
                      style={{ color: '#7A7A72' }}>
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rewards.length === 0 && (
                  <tr>
                    <td colSpan={COLS.length} className="px-5 py-12 text-center text-sm"
                      style={{ color: '#9A9A90' }}>
                      No rewards yet. Click "Add Reward" to create one.
                    </td>
                  </tr>
                )}
                {rewards.map((r) => (
                  <tr key={r.id} className="border-t transition-colors" style={{ borderColor: '#EBE4D9' }}
                    onMouseEnter={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = '#FAF7F2'; }}
                    onMouseLeave={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = 'transparent'; }}
                  >
                    <td className="px-5 py-3">
                      <p className="font-medium" style={{ color: '#2C2C2A' }}>{r.title}</p>
                      {r.description && (
                        <p className="text-xs mt-0.5 truncate max-w-[200px]" style={{ color: '#9A9A90' }}>
                          {r.description}
                        </p>
                      )}
                    </td>
                    <td className="px-5 py-3">
                      <span className="inline-flex items-center gap-1 font-semibold" style={{ color: '#4E523B' }}>
                        {r.points_required.toLocaleString('id-ID')}
                        <span className="text-xs font-normal" style={{ color: '#7A7A72' }}>pts</span>
                      </span>
                    </td>
                    <td className="px-5 py-3 whitespace-nowrap" style={{ color: '#5A5A52' }}>
                      {REWARD_TYPE_LABELS[r.reward_type] ?? r.reward_type}
                    </td>
                    <td className="px-5 py-3 whitespace-nowrap" style={{ color: '#5A5A52' }}>
                      {valueLabel(r)}
                    </td>
                    <td className="px-5 py-3 text-center" style={{ color: '#5A5A52' }}>
                      {r.max_redemptions != null ? r.max_redemptions.toLocaleString('id-ID') : (
                        <span style={{ color: '#9A9A90' }}>∞</span>
                      )}
                    </td>
                    <td className="px-5 py-3 text-center font-medium" style={{ color: '#2C2C2A' }}>
                      {r.total_redeemed.toLocaleString('id-ID')}
                    </td>
                    <td className="px-5 py-3">
                      <span className="inline-flex px-2 py-0.5 rounded-full text-xs font-medium"
                        style={r.is_active
                          ? { backgroundColor: '#E8EBE0', color: '#4E523B' }
                          : { backgroundColor: '#F0ECE5', color: '#7A7A72' }}>
                        {r.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td className="px-5 py-3">
                      <div className="flex justify-end gap-2">
                        <button onClick={() => setModal(r)}
                          className="p-1.5 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
                          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
                          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
                        >
                          <Pencil className="w-4 h-4" />
                        </button>
                        <button onClick={() => setManageModal(r)}
                          className="p-1.5 rounded-lg text-red-400 transition-colors"
                          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#FEF2F2'; }}
                          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
                          title="Manage / Delete"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {modal !== false && (
        <RewardModal
          item={modal}
          treatments={treatments}
          onClose={() => setModal(false)}
          onSaved={loadAll}
        />
      )}

      {manageModal && (
        <ManageRewardModal
          reward={manageModal}
          onClose={() => setManageModal(null)}
          onDeactivated={() => {
            setRewards((prev) => prev.map((r) => r.id === manageModal.id ? { ...r, is_active: false } : r));
          }}
          onDeleted={() => {
            setRewards((prev) => prev.filter((r) => r.id !== manageModal.id));
          }}
        />
      )}
    </div>
  );
}
