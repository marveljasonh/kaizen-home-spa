'use client';

import { useEffect, useState } from 'react';
import { Plus, Pencil, Trash2, X, RefreshCw, AlertCircle } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { adminMutate } from '@/lib/adminMutate';
import { formatDate } from '@/lib/utils';
import type { Treatment, Category } from '@/types';

interface Quest {
  id: string;
  title: string;
  description: string | null;
  quest_type: 'order_count' | 'specific_treatment' | 'specific_category';
  target_count: number;
  treatment_id: string | null;
  category_id: string | null;
  reward_type: 'free_treatment' | 'discount';
  reward_treatment_id: string | null;
  discount_type: 'flat' | 'percentage' | null;
  reward_value: number | null;
  reward_voucher_code: string | null;
  start_date: string | null;
  end_date: string | null;
  is_active: boolean;
  created_at: string;
}

const INPUT = 'w-full px-3 py-2 rounded-lg border text-sm focus:outline-none focus:ring-2 focus:ring-[#4E523B]';
const LABEL = 'block text-sm font-medium mb-1.5';
const inputStyle = { borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' };
const labelStyle: React.CSSProperties = { color: '#3D3D38' };
const BTN_PRIMARY = 'px-4 py-2 rounded-lg text-sm font-medium text-white disabled:opacity-60 transition-colors';
const BTN_GHOST = 'px-4 py-2 rounded-lg text-sm font-medium transition-colors';

const QUEST_TYPE_LABELS: Record<string, string> = {
  order_count: 'Any Order',
  specific_treatment: 'Specific Treatment',
  specific_category: 'Specific Category',
};

function generateCode() {
  return Math.random().toString(36).toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 8);
}

function ErrorBanner({ message }: { message: string }) {
  return (
    <div className="flex items-start gap-2 px-4 py-3 rounded-lg border border-red-200 text-red-700 text-sm" style={{ backgroundColor: '#FEF2F2' }}>
      <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
      <span>{message}</span>
    </div>
  );
}

function QuestModal({
  item,
  treatments,
  categories,
  onClose,
  onSaved,
}: {
  item: Partial<Quest> | null;
  treatments: Treatment[];
  categories: Category[];
  onClose: () => void;
  onSaved: () => void;
}) {
  const [title, setTitle] = useState(item?.title ?? '');
  const [description, setDescription] = useState(item?.description ?? '');
  const [questType, setQuestType] = useState(item?.quest_type ?? 'order_count');
  const [targetCount, setTargetCount] = useState(String(item?.target_count ?? 1));
  const [treatmentId, setTreatmentId] = useState(item?.treatment_id ?? '');
  const [categoryId, setCategoryId] = useState(item?.category_id ?? '');
  const [rewardType, setRewardType] = useState(item?.reward_type ?? 'free_treatment');
  const [rewardTreatmentId, setRewardTreatmentId] = useState(item?.reward_treatment_id ?? '');
  const [discountType, setDiscountType] = useState(item?.discount_type ?? 'percentage');
  const [discountValue, setDiscountValue] = useState(String(item?.reward_value ?? ''));
  const [voucherCode, setVoucherCode] = useState(item?.reward_voucher_code ?? '');
  const [startDate, setStartDate] = useState(item?.start_date?.slice(0, 10) ?? '');
  const [endDate, setEndDate] = useState(item?.end_date?.slice(0, 10) ?? '');
  const [isActive, setIsActive] = useState(item?.is_active ?? true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSave() {
    if (!title.trim()) { setError('Title is required'); return; }
    if (Number(targetCount) < 1) { setError('Target count must be at least 1'); return; }
    if (questType === 'specific_treatment' && !treatmentId) { setError('Please select a treatment for this quest type'); return; }
    if (questType === 'specific_category' && !categoryId) { setError('Please select a category for this quest type'); return; }
    if (rewardType === 'free_treatment' && !rewardTreatmentId) { setError('Please select a reward treatment'); return; }
    if (rewardType === 'discount' && !discountValue) { setError('Please enter a discount value'); return; }

    setSaving(true);
    setError(null);

    const payload: Record<string, unknown> = {
      title: title.trim(),
      description: description.trim() || null,
      quest_type: questType,
      target_count: Number(targetCount),
      treatment_id: questType === 'specific_treatment' ? treatmentId : null,
      category_id: questType === 'specific_category' ? categoryId : null,
      reward_type: rewardType,
      reward_treatment_id: rewardType === 'free_treatment' ? rewardTreatmentId : null,
      discount_type: rewardType === 'discount' ? discountType : null,
      reward_value: rewardType === 'discount' ? Number(discountValue) : null,
      reward_voucher_code: rewardType === 'discount' ? (voucherCode.trim() || null) : null,
      start_date: startDate || null,
      end_date: endDate || null,
      is_active: isActive,
    };

    const result = item?.id
      ? await adminMutate('quests', 'update', payload, { id: item.id })
      : await adminMutate('quests', 'insert', payload);

    setSaving(false);
    if (result.error) { setError(result.error); return; }
    onSaved();
    onClose();
  }

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl border shadow-xl w-full max-w-lg max-h-[92vh] flex flex-col" style={{ borderColor: '#EBE4D9' }}>
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b flex-shrink-0" style={{ borderColor: '#EBE4D9' }}>
          <h3 className="font-semibold" style={{ color: '#2C2C2A' }}>{item?.id ? 'Edit Quest' : 'Add Quest'}</h3>
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

          {/* Title */}
          <div>
            <label className={LABEL} style={labelStyle}>Title *</label>
            <input autoFocus value={title} onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Book 5 Sessions" className={INPUT} style={inputStyle} />
          </div>

          {/* Description */}
          <div>
            <label className={LABEL} style={labelStyle}>Description</label>
            <textarea value={description} onChange={(e) => setDescription(e.target.value)} rows={2}
              placeholder="Optional — shown to users in the app"
              className={INPUT} style={{ ...inputStyle, resize: 'vertical' as const }} />
          </div>

          {/* Quest Type + Target Count */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={LABEL} style={labelStyle}>Quest Type</label>
              <select value={questType}
                onChange={(e) => {
                  setQuestType(e.target.value as Quest['quest_type']);
                  setTreatmentId('');
                  setCategoryId('');
                }}
                className={INPUT} style={inputStyle}
              >
                <option value="order_count">Any Order</option>
                <option value="specific_treatment">Specific Treatment</option>
                <option value="specific_category">Specific Category</option>
              </select>
            </div>
            <div>
              <label className={LABEL} style={labelStyle}>Target Count *</label>
              <input type="number" min={1} value={targetCount}
                onChange={(e) => setTargetCount(e.target.value)} className={INPUT} style={inputStyle} />
            </div>
          </div>

          {/* Conditional: Treatment dropdown */}
          {questType === 'specific_treatment' && (
            <div>
              <label className={LABEL} style={labelStyle}>Treatment *</label>
              <select value={treatmentId} onChange={(e) => setTreatmentId(e.target.value)} className={INPUT} style={inputStyle}>
                <option value="">Select treatment…</option>
                {treatments.map((t) => (
                  <option key={t.id} value={t.id}>{t.name}</option>
                ))}
              </select>
            </div>
          )}

          {/* Conditional: Category dropdown */}
          {questType === 'specific_category' && (
            <div>
              <label className={LABEL} style={labelStyle}>Category *</label>
              <select value={categoryId} onChange={(e) => setCategoryId(e.target.value)} className={INPUT} style={inputStyle}>
                <option value="">Select category…</option>
                {categories.map((c) => (
                  <option key={c.id} value={c.id}>{c.name}</option>
                ))}
              </select>
            </div>
          )}

          <div className="border-t" style={{ borderColor: '#EBE4D9' }} />

          {/* Reward Type */}
          <div>
            <label className={LABEL} style={labelStyle}>Reward Type</label>
            <select value={rewardType}
              onChange={(e) => {
                setRewardType(e.target.value as Quest['reward_type']);
                setRewardTreatmentId('');
                setVoucherCode('');
              }}
              className={INPUT} style={inputStyle}
            >
              <option value="free_treatment">Free Treatment</option>
              <option value="discount">Discount</option>
            </select>
          </div>

          {/* Conditional: Free Treatment reward */}
          {rewardType === 'free_treatment' && (
            <div>
              <label className={LABEL} style={labelStyle}>Reward Treatment *</label>
              <select value={rewardTreatmentId} onChange={(e) => setRewardTreatmentId(e.target.value)} className={INPUT} style={inputStyle}>
                <option value="">Select treatment…</option>
                {treatments.map((t) => (
                  <option key={t.id} value={t.id}>{t.name}</option>
                ))}
              </select>
            </div>
          )}

          {/* Conditional: Discount reward */}
          {rewardType === 'discount' && (
            <div className="space-y-3">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className={LABEL} style={labelStyle}>Discount Type</label>
                  <select value={discountType ?? 'percentage'}
                    onChange={(e) => setDiscountType(e.target.value as 'flat' | 'percentage')}
                    className={INPUT} style={inputStyle}
                  >
                    <option value="percentage">Percentage (%)</option>
                    <option value="flat">Flat (IDR)</option>
                  </select>
                </div>
                <div>
                  <label className={LABEL} style={labelStyle}>Discount Value *</label>
                  <input type="number" min={0} value={discountValue}
                    onChange={(e) => setDiscountValue(e.target.value)}
                    placeholder={discountType === 'percentage' ? 'e.g. 20' : 'e.g. 50000'}
                    className={INPUT} style={inputStyle} />
                </div>
              </div>
              <div>
                <label className={LABEL} style={labelStyle}>Voucher Code</label>
                <div className="flex gap-2">
                  <input value={voucherCode}
                    onChange={(e) => setVoucherCode(e.target.value.toUpperCase())}
                    placeholder="Auto-generate or enter manually"
                    className={`${INPUT} font-mono flex-1`} style={inputStyle} />
                  <button type="button" onClick={() => setVoucherCode(generateCode())}
                    className="flex items-center gap-1.5 px-3 py-2 rounded-lg border text-sm transition-colors flex-shrink-0"
                    style={{ borderColor: '#EBE4D9', color: '#4E523B', backgroundColor: '#F0F2E8' }}
                    onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#E8EBE0'; }}
                    onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0F2E8'; }}
                    title="Generate random code"
                  >
                    <RefreshCw className="w-3.5 h-3.5" />
                    Generate
                  </button>
                </div>
              </div>
            </div>
          )}

          <div className="border-t" style={{ borderColor: '#EBE4D9' }} />

          {/* Dates */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={LABEL} style={labelStyle}>Start Date</label>
              <input type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} className={INPUT} style={inputStyle} />
            </div>
            <div>
              <label className={LABEL} style={labelStyle}>End Date</label>
              <input type="date" value={endDate} onChange={(e) => setEndDate(e.target.value)} className={INPUT} style={inputStyle} />
            </div>
          </div>

          {/* Active */}
          <label className="flex items-center gap-2 cursor-pointer">
            <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)}
              className="w-4 h-4 rounded" style={{ accentColor: '#4E523B' }} />
            <span className="text-sm" style={{ color: '#3D3D38' }}>Active</span>
          </label>
        </div>

        {/* Footer */}
        <div className="flex justify-end gap-2 px-5 py-4 border-t flex-shrink-0" style={{ borderColor: '#EBE4D9' }}>
          <button onClick={onClose} className={BTN_GHOST} style={{ backgroundColor: '#F0ECE5', color: '#3D3D38' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#EBE4D9'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
          >Cancel</button>
          <button onClick={handleSave} disabled={saving} className={BTN_PRIMARY} style={{ backgroundColor: '#4E523B' }}
            onMouseEnter={(e) => { if (!saving) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
          >{saving ? 'Saving…' : 'Save'}</button>
        </div>
      </div>
    </div>
  );
}

export default function QuestsPage() {
  const [quests, setQuests] = useState<Quest[]>([]);
  const [treatments, setTreatments] = useState<Treatment[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState<Partial<Quest> | null | false>(false);

  useEffect(() => { loadAll(); }, []);

  async function loadAll() {
    setLoading(true);
    const supabase = createClient();
    const [{ data: q }, { data: t }, { data: c }] = await Promise.all([
      supabase.from('quests').select('*').order('created_at', { ascending: false }),
      supabase.from('treatments').select('id, name').eq('is_active', true).order('name'),
      supabase.from('categories').select('id, name').order('name'),
    ]);
    setQuests((q as Quest[]) ?? []);
    setTreatments((t as Treatment[]) ?? []);
    setCategories((c as Category[]) ?? []);
    setLoading(false);
  }

  async function handleDelete(quest: Quest) {
    if (!confirm(`Delete quest "${quest.title}"?`)) return;
    const result = await adminMutate('quests', 'delete', undefined, { id: quest.id });
    if (result.error) { alert(`Delete failed: ${result.error}`); return; }
    setQuests((prev) => prev.filter((q) => q.id !== quest.id));
  }

  function rewardLabel(q: Quest) {
    if (q.reward_type === 'free_treatment') return 'Free Treatment';
    if (q.discount_type === 'percentage') return `${q.reward_value}% OFF`;
    if (q.discount_type === 'flat') return `IDR ${q.reward_value?.toLocaleString('id-ID')} OFF`;
    return '—';
  }

  const COLS = ['Title', 'Type', 'Target', 'Reward', 'Start Date', 'End Date', 'Status', ''] as const;

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold" style={{ color: '#2C2C2A' }}>Quests</h1>
        <button
          onClick={() => setModal({})}
          className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium text-white transition-colors"
          style={{ backgroundColor: '#4E523B' }}
          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
        >
          <Plus className="w-4 h-4" /> Add Quest
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
                    <th key={h} className={`px-5 py-3 text-xs font-semibold uppercase tracking-wide ${h ? 'text-left' : ''}`} style={{ color: '#7A7A72' }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {quests.length === 0 && (
                  <tr>
                    <td colSpan={COLS.length} className="px-5 py-12 text-center text-sm" style={{ color: '#9A9A90' }}>
                      No quests yet. Click "Add Quest" to create one.
                    </td>
                  </tr>
                )}
                {quests.map((q) => (
                  <tr key={q.id} className="border-t transition-colors" style={{ borderColor: '#EBE4D9' }}
                    onMouseEnter={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = '#FAF7F2'; }}
                    onMouseLeave={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = 'transparent'; }}
                  >
                    <td className="px-5 py-3">
                      <p className="font-medium" style={{ color: '#2C2C2A' }}>{q.title}</p>
                      {q.description && (
                        <p className="text-xs mt-0.5 truncate max-w-[200px]" style={{ color: '#9A9A90' }}>{q.description}</p>
                      )}
                    </td>
                    <td className="px-5 py-3 whitespace-nowrap" style={{ color: '#5A5A52' }}>
                      {QUEST_TYPE_LABELS[q.quest_type] ?? q.quest_type}
                    </td>
                    <td className="px-5 py-3 text-center font-semibold" style={{ color: '#4E523B' }}>
                      {q.target_count}×
                    </td>
                    <td className="px-5 py-3">
                      <span style={{ color: '#5A5A52' }}>{rewardLabel(q)}</span>
                      {q.reward_voucher_code && (
                        <p className="text-xs font-mono mt-0.5" style={{ color: '#9A9A90' }}>{q.reward_voucher_code}</p>
                      )}
                    </td>
                    <td className="px-5 py-3 whitespace-nowrap" style={{ color: '#5A5A52' }}>
                      {q.start_date ? formatDate(q.start_date) : '—'}
                    </td>
                    <td className="px-5 py-3 whitespace-nowrap" style={{ color: '#5A5A52' }}>
                      {q.end_date ? formatDate(q.end_date) : '—'}
                    </td>
                    <td className="px-5 py-3">
                      <span className="inline-flex px-2 py-0.5 rounded-full text-xs font-medium"
                        style={q.is_active
                          ? { backgroundColor: '#E8EBE0', color: '#4E523B' }
                          : { backgroundColor: '#F0ECE5', color: '#7A7A72' }}>
                        {q.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td className="px-5 py-3">
                      <div className="flex justify-end gap-2">
                        <button onClick={() => setModal(q)} className="p-1.5 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
                          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
                          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
                        >
                          <Pencil className="w-4 h-4" />
                        </button>
                        <button onClick={() => handleDelete(q)} className="p-1.5 rounded-lg text-red-400 transition-colors"
                          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#FEF2F2'; }}
                          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
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
        <QuestModal
          item={modal}
          treatments={treatments}
          categories={categories}
          onClose={() => setModal(false)}
          onSaved={loadAll}
        />
      )}
    </div>
  );
}
