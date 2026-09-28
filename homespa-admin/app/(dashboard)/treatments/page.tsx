'use client';

import { useEffect, useRef, useState } from 'react';
import { Plus, Pencil, Trash2, X, AlertCircle, EyeOff } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { adminMutate } from '@/lib/adminMutate';
import { cn, formatRupiah } from '@/lib/utils';
import type { Category, Treatment, Addon, TreatmentDuration } from '@/types';

type Tab = 'categories' | 'treatments' | 'addons';

const INPUT = 'w-full px-3 py-2 rounded-lg border text-sm focus:outline-none focus:ring-2 focus:ring-[#4E523B]';
const LABEL = 'block text-sm font-medium mb-1.5';
const inputStyle = { borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' };
const labelStyle = { color: '#3D3D38' };

const BTN_PRIMARY = 'px-4 py-2 rounded-lg text-sm font-medium text-white disabled:opacity-60 transition-colors';
const BTN_GHOST = 'px-4 py-2 rounded-lg text-sm font-medium transition-colors';

function btnPrimaryStyle(disabled?: boolean) {
  return { backgroundColor: disabled ? '#4E523B' : '#4E523B' };
}

function ErrorBanner({ message }: { message: string }) {
  return (
    <div className="flex items-start gap-2 px-4 py-3 rounded-lg border border-red-200 text-red-700 text-sm" style={{ backgroundColor: '#FEF2F2' }}>
      <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
      <span>{message}</span>
    </div>
  );
}

function ConflictModal({
  message,
  canDeactivate,
  deactivating,
  onDeactivate,
  onClose,
}: {
  message: string;
  canDeactivate: boolean;
  deactivating: boolean;
  onDeactivate?: () => void;
  onClose: () => void;
}) {
  return (
    <div className="fixed inset-0 z-[60] bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl border shadow-xl w-full max-w-sm" style={{ borderColor: '#EBE4D9' }}>
        <div className="p-5">
          <div className="flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-amber-500 flex-shrink-0 mt-0.5" />
            <p className="text-sm" style={{ color: '#3D3D38' }}>{message}</p>
          </div>
        </div>
        <div className="flex justify-end gap-2 px-5 py-4 border-t" style={{ borderColor: '#EBE4D9' }}>
          <button onClick={onClose} className={BTN_GHOST} style={{ backgroundColor: '#F0ECE5', color: '#3D3D38' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#EBE4D9'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
          >
            {canDeactivate ? 'Cancel' : 'OK'}
          </button>
          {canDeactivate && onDeactivate && (
            <button onClick={onDeactivate} disabled={deactivating} className={BTN_PRIMARY} style={{ backgroundColor: '#4E523B' }}
              onMouseEnter={(e) => { if (!deactivating) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
            >
              {deactivating ? 'Deactivating…' : 'Deactivate Instead'}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

function isFkError(err: string) {
  const s = err.toLowerCase();
  return s.includes('foreign key') || s.includes('violates') || s.includes('referenced');
}

function ManageItemModal({
  label,
  count,
  onDeactivate,
  onDelete,
  onClose,
}: {
  label: string;
  count: number;
  onDeactivate: () => Promise<void>;
  onDelete: () => Promise<void>;
  onClose: () => void;
}) {
  const [loading, setLoading] = useState<'deactivate' | 'delete' | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function run(action: 'deactivate' | 'delete', fn: () => Promise<void>) {
    setLoading(action);
    setError(null);
    try {
      await fn();
      onClose();
    } catch (e) {
      setError((e as Error).message);
      setLoading(null);
    }
  }

  return (
    <div className="fixed inset-0 z-[60] bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl border shadow-xl w-full max-w-md" style={{ borderColor: '#EBE4D9' }}>
        <div className="flex items-center justify-between px-5 py-4 border-b" style={{ borderColor: '#EBE4D9' }}>
          <h3 className="font-semibold" style={{ color: '#2C2C2A' }}>Delete {label}</h3>
          <button onClick={onClose} disabled={!!loading} className="p-1 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="p-5 space-y-4">
          {error && <ErrorBanner message={error} />}

          {count > 0 ? (
            <>
              <div className="flex items-start gap-2 px-4 py-3 rounded-lg border border-amber-200 text-amber-700 text-sm" style={{ backgroundColor: '#FFFBEB' }}>
                <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
                <span>This item has <strong>{count}</strong> related record{count !== 1 ? 's' : ''}.</span>
              </div>

              <div className="space-y-2">
                <button
                  onClick={() => run('deactivate', onDeactivate)}
                  disabled={!!loading}
                  className="w-full flex items-start gap-3 p-4 rounded-lg border-2 text-left transition-colors disabled:opacity-60"
                  style={{ borderColor: '#C5CAB0', backgroundColor: '#FAF7F2' }}
                  onMouseEnter={(e) => { if (!loading) (e.currentTarget as HTMLButtonElement).style.borderColor = '#4E523B'; }}
                  onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.borderColor = '#C5CAB0'; }}
                >
                  <div className="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0" style={{ backgroundColor: '#E8EBE0' }}>
                    {loading === 'deactivate'
                      ? <div className="w-4 h-4 rounded-full border-2 animate-spin" style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }} />
                      : <EyeOff className="w-4 h-4" style={{ color: '#4E523B' }} />
                    }
                  </div>
                  <div>
                    <p className="text-sm font-medium flex items-center gap-2" style={{ color: '#2C2C2A' }}>
                      Deactivate
                      <span className="text-xs font-normal px-1.5 py-0.5 rounded" style={{ backgroundColor: '#E8EBE0', color: '#4E523B' }}>Recommended</span>
                    </p>
                    <p className="text-xs mt-1" style={{ color: '#7A7A72' }}>Hidden from the app. Existing records stay intact.</p>
                  </div>
                </button>

                <button
                  onClick={() => run('delete', onDelete)}
                  disabled={!!loading}
                  className="w-full flex items-start gap-3 p-4 rounded-lg border-2 text-left transition-colors disabled:opacity-60"
                  style={{ borderColor: '#FECACA', backgroundColor: '#FFF5F5' }}
                  onMouseEnter={(e) => { if (!loading) (e.currentTarget as HTMLButtonElement).style.borderColor = '#EF4444'; }}
                  onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.borderColor = '#FECACA'; }}
                >
                  <div className="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0" style={{ backgroundColor: '#FEE2E2' }}>
                    {loading === 'delete'
                      ? <div className="w-4 h-4 rounded-full border-2 animate-spin" style={{ borderColor: '#EF4444', borderTopColor: 'transparent' }} />
                      : <Trash2 className="w-4 h-4 text-red-500" />
                    }
                  </div>
                  <div>
                    <p className="text-sm font-medium text-red-700">Delete Permanently</p>
                    <p className="text-xs mt-1" style={{ color: '#7A7A72' }}>Remove this item entirely. May fail if referenced by active bookings.</p>
                  </div>
                </button>
              </div>
            </>
          ) : (
            <p className="text-sm" style={{ color: '#3D3D38' }}>
              Delete <strong>{label}</strong>? This cannot be undone.
            </p>
          )}
        </div>

        <div className="flex justify-end gap-2 px-5 py-4 border-t" style={{ borderColor: '#EBE4D9' }}>
          <button
            onClick={onClose}
            disabled={!!loading}
            className={BTN_GHOST}
            style={{ backgroundColor: '#F0ECE5', color: '#3D3D38' }}
            onMouseEnter={(e) => { if (!loading) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#EBE4D9'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
          >
            Cancel
          </button>
          {count === 0 && (
            <button
              onClick={() => run('delete', onDelete)}
              disabled={!!loading}
              className={BTN_PRIMARY}
              style={{ backgroundColor: '#DC2626' }}
              onMouseEnter={(e) => { if (!loading) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#B91C1C'; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#DC2626'; }}
            >
              {loading === 'delete' ? 'Deleting…' : 'Delete'}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

function Modal({
  title,
  onClose,
  children,
  footer,
  wide,
}: {
  title: string;
  onClose: () => void;
  children: React.ReactNode;
  footer: React.ReactNode;
  wide?: boolean;
}) {
  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
      <div className={cn('bg-white rounded-xl border shadow-xl w-full max-h-[90vh] flex flex-col', wide ? 'max-w-2xl' : 'max-w-md')} style={{ borderColor: '#EBE4D9' }}>
        <div className="flex items-center justify-between px-5 py-4 border-b flex-shrink-0" style={{ borderColor: '#EBE4D9' }}>
          <h3 className="font-semibold" style={{ color: '#2C2C2A' }}>{title}</h3>
          <button onClick={onClose} className="p-1 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
          >
            <X className="w-4 h-4" />
          </button>
        </div>
        <div className="p-5 space-y-4 overflow-y-auto flex-1">{children}</div>
        <div className="flex justify-end gap-2 px-5 py-4 border-t flex-shrink-0" style={{ borderColor: '#EBE4D9' }}>
          {footer}
        </div>
      </div>
    </div>
  );
}

function CategoryModal({ item, onClose, onSaved }: { item: Partial<Category> | null; onClose: () => void; onSaved: () => void; }) {
  const [name, setName] = useState(item?.name ?? '');
  const [sortOrder, setSortOrder] = useState(String(item?.sort_order ?? 0));
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSave() {
    if (!name.trim()) return;
    setSaving(true);
    setError(null);
    const payload = { name: name.trim(), sort_order: Number(sortOrder) };
    const result = item?.id
      ? await adminMutate('categories', 'update', payload, { id: item.id })
      : await adminMutate('categories', 'insert', payload);
    setSaving(false);
    if (result.error) { setError(result.error); return; }
    onSaved();
    onClose();
  }

  return (
    <Modal title={item?.id ? 'Edit Category' : 'Add Category'} onClose={onClose} footer={
      <>
        <button onClick={onClose} className={BTN_GHOST} style={{ backgroundColor: '#F0ECE5', color: '#3D3D38' }}
          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#EBE4D9'; }}
          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
        >Cancel</button>
        <button onClick={handleSave} disabled={saving} className={BTN_PRIMARY} style={{ backgroundColor: '#4E523B' }}
          onMouseEnter={(e) => { if (!saving) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
        >{saving ? 'Saving…' : 'Save'}</button>
      </>
    }>
      {error && <ErrorBanner message={error} />}
      <div>
        <label className={LABEL} style={labelStyle}>Name</label>
        <input autoFocus value={name} onChange={(e) => setName(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && handleSave()} className={INPUT} style={inputStyle} />
      </div>
      <div>
        <label className={LABEL} style={labelStyle}>Sort Order</label>
        <input type="number" value={sortOrder} onChange={(e) => setSortOrder(e.target.value)} className={INPUT} style={inputStyle} />
      </div>
    </Modal>
  );
}

function TreatmentModal({ item, categories, onClose, onSaved }: { item: Partial<Treatment> | null; categories: Category[]; onClose: () => void; onSaved: () => void; }) {
  const [name, setName] = useState(item?.name ?? '');
  const [description, setDescription] = useState(item?.description ?? '');
  const [categoryId, setCategoryId] = useState(item?.category_id ?? '');
  const [imageUrl, setImageUrl] = useState(item?.image_url ?? '');
  const [sortOrder, setSortOrder] = useState(String(item?.sort_order ?? 0));
  const [isActive, setIsActive] = useState(item?.is_active ?? true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!item?.category_id && !categoryId && categories.length > 0) {
      setCategoryId(categories[0].id);
    }
  }, [categories]); // eslint-disable-line react-hooks/exhaustive-deps

  async function handleSave() {
    if (!name.trim()) { setError('Name is required'); return; }
    if (!categoryId) { setError('Category is required'); return; }
    setSaving(true);
    setError(null);
    const payload: Record<string, unknown> = {
      name: name.trim(),
      description: description.trim() || null,
      category_id: categoryId,
      image_url: imageUrl.trim() || null,
      sort_order: Number(sortOrder) || 0,
      is_active: isActive,
    };
    const result = item?.id
      ? await adminMutate('treatments', 'update', payload, { id: item.id })
      : await adminMutate('treatments', 'insert', payload);
    setSaving(false);
    if (result.error) { setError(result.error); return; }
    onSaved();
    onClose();
  }

  return (
    <Modal title={item?.id ? 'Edit Treatment' : 'Add Treatment'} onClose={onClose} wide footer={
      <>
        <button onClick={onClose} className={BTN_GHOST} style={{ backgroundColor: '#F0ECE5', color: '#3D3D38' }}
          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#EBE4D9'; }}
          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
        >Cancel</button>
        <button onClick={handleSave} disabled={saving} className={BTN_PRIMARY} style={{ backgroundColor: '#4E523B' }}
          onMouseEnter={(e) => { if (!saving) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
        >{saving ? 'Saving…' : 'Save'}</button>
      </>
    }>
      {error && <ErrorBanner message={error} />}
      <div>
        <label className={LABEL} style={labelStyle}>Name *</label>
        <input autoFocus value={name} onChange={(e) => setName(e.target.value)} className={INPUT} style={inputStyle} />
      </div>
      <div>
        <label className={LABEL} style={labelStyle}>Description</label>
        <textarea value={description} onChange={(e) => setDescription(e.target.value)} rows={3} className={cn(INPUT, 'resize-none')} style={inputStyle} />
      </div>
      <div>
        <label className={LABEL} style={labelStyle}>Category *</label>
        <select value={categoryId} onChange={(e) => setCategoryId(e.target.value)} className={cn(INPUT, !categoryId && 'border-red-300')} style={inputStyle}>
          {categories.length === 0 && <option value="">Loading categories…</option>}
          {categories.map((c) => (
            <option key={c.id} value={c.id}>{c.name}</option>
          ))}
        </select>
        {categories.length === 0 && (
          <p className="text-xs text-amber-600 mt-1">No categories found. Add a category first.</p>
        )}
      </div>
      <div>
        <label className={LABEL} style={labelStyle}>Image URL</label>
        <input value={imageUrl} onChange={(e) => setImageUrl(e.target.value)} placeholder="https://…" className={INPUT} style={inputStyle} />
        {imageUrl && (
          <img src={imageUrl} alt="preview" className="mt-2 w-full h-28 object-cover rounded-lg" />
        )}
      </div>
      <div>
        <label className={LABEL} style={labelStyle}>Sort Order</label>
        <input type="number" value={sortOrder} onChange={(e) => setSortOrder(e.target.value)} className={INPUT} style={inputStyle} />
      </div>
      <label className="flex items-center gap-2 cursor-pointer">
        <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} className="w-4 h-4 rounded" style={{ accentColor: '#4E523B' }} />
        <span className="text-sm" style={{ color: '#3D3D38' }}>Active</span>
      </label>
    </Modal>
  );
}

function DurationRow({ duration, onSaved, onDelete }: { duration: TreatmentDuration; onSaved: () => void; onDelete: () => void; }) {
  const [editing, setEditing] = useState(false);
  const [minutes, setMinutes] = useState(String(duration.duration_minutes));
  const [price, setPrice] = useState(String(duration.price));
  const [isActive, setIsActive] = useState(duration.is_active);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const CELL = 'px-4 py-2.5 text-sm';
  const MINI = 'px-2 py-1 rounded-md border text-sm focus:outline-none focus:ring-1 focus:ring-[#4E523B]';
  const miniStyle = { borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' };

  async function handleSave() {
    setSaving(true);
    setError(null);
    const result = await adminMutate('treatment_durations', 'update', { duration_minutes: Number(minutes), price: Number(price), is_active: isActive }, { id: duration.id });
    setSaving(false);
    if (result.error) { setError(result.error); return; }
    setEditing(false);
    onSaved();
  }

  if (editing) {
    return (
      <>
        {error && (
          <tr>
            <td colSpan={4} className="px-4 py-1">
              <ErrorBanner message={error} />
            </td>
          </tr>
        )}
        <tr style={{ backgroundColor: '#F0F2E8' }}>
          <td className={CELL}>
            <div className="flex items-center gap-1">
              <input type="number" value={minutes} onChange={(e) => setMinutes(e.target.value)} className={cn(MINI, 'w-20')} style={miniStyle} />
              <span className="text-xs" style={{ color: '#7A7A72' }}>min</span>
            </div>
          </td>
          <td className={CELL}>
            <input type="number" value={price} onChange={(e) => setPrice(e.target.value)} className={cn(MINI, 'w-32')} style={miniStyle} />
          </td>
          <td className={cn(CELL, 'text-center')}>
            <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} className="w-4 h-4" style={{ accentColor: '#4E523B' }} />
          </td>
          <td className={CELL}>
            <div className="flex gap-1.5 justify-end">
              <button onClick={handleSave} disabled={saving} className="px-2.5 py-1 rounded-md text-xs font-medium text-white disabled:opacity-50" style={{ backgroundColor: '#4E523B' }}>
                {saving ? '…' : 'Save'}
              </button>
              <button onClick={() => setEditing(false)} className="px-2.5 py-1 rounded-md text-xs font-medium" style={{ backgroundColor: '#F0ECE5', color: '#5A5A52' }}>
                Cancel
              </button>
            </div>
          </td>
        </tr>
      </>
    );
  }

  return (
    <tr className="transition-colors" style={{ borderTop: '1px solid #EBE4D9' }}
      onMouseEnter={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = '#FAF7F2'; }}
      onMouseLeave={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = 'transparent'; }}
    >
      <td className={cn(CELL, 'font-medium')} style={{ color: '#2C2C2A' }}>{duration.duration_minutes} min</td>
      <td className={CELL} style={{ color: '#3D3D38' }}>{formatRupiah(duration.price)}</td>
      <td className={cn(CELL, 'text-center')}>
        {duration.is_active ? (
          <span className="inline-flex px-2 py-0.5 rounded-full text-xs font-medium" style={{ backgroundColor: '#E8EBE0', color: '#4E523B' }}>Active</span>
        ) : (
          <span className="inline-flex px-2 py-0.5 rounded-full text-xs font-medium" style={{ backgroundColor: '#F0ECE5', color: '#7A7A72' }}>Inactive</span>
        )}
      </td>
      <td className={CELL}>
        <div className="flex gap-1.5 justify-end">
          <button onClick={() => setEditing(true)} className="p-1.5 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
          >
            <Pencil className="w-3.5 h-3.5" />
          </button>
          <button onClick={onDelete} className="p-1.5 rounded-lg text-red-400 transition-colors"
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#FEF2F2'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
          >
            <Trash2 className="w-3.5 h-3.5" />
          </button>
        </div>
      </td>
    </tr>
  );
}

function DurationsModal({ treatment, onClose, onSaved }: { treatment: Treatment; onClose: () => void; onSaved: () => void; }) {
  const [durations, setDurations] = useState<TreatmentDuration[]>([]);
  const [loading, setLoading] = useState(true);
  const [addMinutes, setAddMinutes] = useState('');
  const [addPrice, setAddPrice] = useState('');
  const [adding, setAdding] = useState(false);
  const [addError, setAddError] = useState<string | null>(null);
  const minutesRef = useRef<HTMLInputElement>(null);
  const [durationConflict, setDurationConflict] = useState<{ id: string; minutes: number } | null>(null);
  const [durDeactivating, setDurDeactivating] = useState(false);

  useEffect(() => { loadDurations(); }, []); // eslint-disable-line react-hooks/exhaustive-deps

  async function loadDurations() {
    setLoading(true);
    const supabase = createClient();
    const { data } = await supabase.from('treatment_durations').select('*').eq('treatment_id', treatment.id).order('duration_minutes');
    setDurations((data as TreatmentDuration[]) ?? []);
    setLoading(false);
  }

  async function handleAdd() {
    if (!addMinutes || !addPrice) return;
    setAdding(true);
    setAddError(null);
    const result = await adminMutate('treatment_durations', 'insert', {
      treatment_id: treatment.id,
      duration_minutes: Number(addMinutes),
      price: Number(addPrice),
      is_active: true,
    });
    setAdding(false);
    if (result.error) { setAddError(result.error); return; }
    setAddMinutes('');
    setAddPrice('');
    minutesRef.current?.focus();
    await loadDurations();
    onSaved();
  }

  async function handleDelete(id: string, minutes: number) {
    if (!confirm(`Delete the ${minutes}-minute duration?`)) return;
    const supabase = createClient();
    const { count } = await supabase.from('booking_items').select('id', { count: 'exact', head: true }).eq('treatment_duration_id', id);
    if ((count ?? 0) > 0) {
      setDurationConflict({ id, minutes });
      return;
    }
    const result = await adminMutate('treatment_durations', 'delete', undefined, { id });
    if (result.error) { setAddError(result.error); return; }
    await loadDurations();
    onSaved();
  }

  async function handleDurationDeactivate() {
    if (!durationConflict) return;
    setDurDeactivating(true);
    await adminMutate('treatment_durations', 'update', { is_active: false }, { id: durationConflict.id });
    setDurDeactivating(false);
    setDurationConflict(null);
    await loadDurations();
    onSaved();
  }

  const MINI = 'px-3 py-2 rounded-lg border text-sm w-full focus:outline-none focus:ring-2 focus:ring-[#4E523B]';

  return (
    <>
      <Modal title={`Durations & Prices — ${treatment.name}`} onClose={onClose} wide footer={
        <button onClick={onClose} className={BTN_GHOST} style={{ backgroundColor: '#F0ECE5', color: '#3D3D38' }}
          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#EBE4D9'; }}
          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
        >Done</button>
      }>
        {loading ? (
          <div className="flex justify-center py-6">
            <div className="w-6 h-6 rounded-full border-4 border-t-transparent animate-spin" style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }} />
          </div>
        ) : durations.length === 0 ? (
          <div className="rounded-lg border border-amber-200 px-4 py-3 text-sm text-amber-700" style={{ backgroundColor: '#FFFBEB' }}>
            No durations yet — add at least one below so customers see a price.
          </div>
        ) : (
          <div className="space-y-1">
            <p className="text-xs font-semibold uppercase tracking-wide mb-2" style={{ color: '#7A7A72' }}>
              {durations.length} duration{durations.length !== 1 ? 's' : ''}
            </p>
            <div className="rounded-lg border overflow-hidden" style={{ borderColor: '#EBE4D9' }}>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b" style={{ backgroundColor: '#FAF7F2', borderColor: '#EBE4D9' }}>
                    <th className="text-left px-4 py-2.5 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Duration</th>
                    <th className="text-left px-4 py-2.5 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Price (IDR)</th>
                    <th className="text-center px-4 py-2.5 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Status</th>
                    <th className="px-4 py-2.5 w-24" />
                  </tr>
                </thead>
                <tbody>
                  {durations.map((d) => (
                    <DurationRow
                      key={d.id}
                      duration={d}
                      onSaved={() => { loadDurations(); onSaved(); }}
                      onDelete={() => handleDelete(d.id, d.duration_minutes)}
                    />
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        <div className="rounded-lg border p-4 space-y-4" style={{ backgroundColor: '#F0F2E8', borderColor: '#C5CAB0' }}>
          <p className="text-sm font-semibold flex items-center gap-2" style={{ color: '#4E523B' }}>
            <Plus className="w-4 h-4" />
            Add New Duration
          </p>
          {addError && <ErrorBanner message={addError} />}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={LABEL} style={labelStyle}>Duration (minutes) *</label>
              <div className="flex items-center gap-2">
                <input ref={minutesRef} type="number" min="1" placeholder="e.g. 60" value={addMinutes} onChange={(e) => setAddMinutes(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && handleAdd()} className={MINI} style={inputStyle} />
                <span className="text-sm whitespace-nowrap" style={{ color: '#7A7A72' }}>min</span>
              </div>
            </div>
            <div>
              <label className={LABEL} style={labelStyle}>Price (Rp) *</label>
              <input type="number" min="0" placeholder="e.g. 150000" value={addPrice} onChange={(e) => setAddPrice(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && handleAdd()} className={MINI} style={inputStyle} />
            </div>
          </div>
          {addMinutes && addPrice && (
            <p className="text-sm font-medium" style={{ color: '#4E523B' }}>
              Preview: {addMinutes} min → {formatRupiah(Number(addPrice))}
            </p>
          )}
          <div className="flex justify-end">
            <button onClick={handleAdd} disabled={adding || !addMinutes || !addPrice} className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium text-white disabled:opacity-50 transition-colors" style={{ backgroundColor: '#4E523B' }}
              onMouseEnter={(e) => { if (!adding) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
            >
              <Plus className="w-4 h-4" />
              {adding ? 'Saving…' : 'Save Duration'}
            </button>
          </div>
        </div>
      </Modal>

      {durationConflict && (
        <ConflictModal
          message={`The ${durationConflict.minutes}-minute duration has been used in existing bookings and cannot be deleted. You can deactivate it so it's hidden from customers but kept for booking records.`}
          canDeactivate
          deactivating={durDeactivating}
          onDeactivate={handleDurationDeactivate}
          onClose={() => setDurationConflict(null)}
        />
      )}
    </>
  );
}

function AddonModal({ item, onClose, onSaved }: { item: Partial<Addon> | null; onClose: () => void; onSaved: () => void; }) {
  const [name, setName] = useState(item?.name ?? '');
  const [description, setDescription] = useState(item?.description ?? '');
  const [price, setPrice] = useState(String(item?.price ?? ''));
  const [isActive, setIsActive] = useState(item?.is_active ?? true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSave() {
    if (!name.trim()) { setError('Name is required'); return; }
    setSaving(true);
    setError(null);
    const payload = { name: name.trim(), description: description.trim() || null, price: Number(price) || 0, is_active: isActive };
    const result = item?.id
      ? await adminMutate('addons', 'update', payload, { id: item.id })
      : await adminMutate('addons', 'insert', payload);
    setSaving(false);
    if (result.error) { setError(result.error); return; }
    onSaved();
    onClose();
  }

  return (
    <Modal title={item?.id ? 'Edit Add-on' : 'Add Add-on'} onClose={onClose} footer={
      <>
        <button onClick={onClose} className={BTN_GHOST} style={{ backgroundColor: '#F0ECE5', color: '#3D3D38' }}
          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#EBE4D9'; }}
          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
        >Cancel</button>
        <button onClick={handleSave} disabled={saving} className={BTN_PRIMARY} style={{ backgroundColor: '#4E523B' }}
          onMouseEnter={(e) => { if (!saving) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
        >{saving ? 'Saving…' : 'Save'}</button>
      </>
    }>
      {error && <ErrorBanner message={error} />}
      <div>
        <label className={LABEL} style={labelStyle}>Name *</label>
        <input autoFocus value={name} onChange={(e) => setName(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && handleSave()} className={INPUT} style={inputStyle} />
      </div>
      <div>
        <label className={LABEL} style={labelStyle}>Description</label>
        <input value={description} onChange={(e) => setDescription(e.target.value)} className={INPUT} style={inputStyle} />
      </div>
      <div>
        <label className={LABEL} style={labelStyle}>Price (IDR)</label>
        <input type="number" value={price} onChange={(e) => setPrice(e.target.value)} className={INPUT} style={inputStyle} />
      </div>
      <label className="flex items-center gap-2 cursor-pointer">
        <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} className="w-4 h-4 rounded" style={{ accentColor: '#4E523B' }} />
        <span className="text-sm" style={{ color: '#3D3D38' }}>Active</span>
      </label>
    </Modal>
  );
}

export default function TreatmentsPage() {
  const [tab, setTab] = useState<Tab>('categories');
  const [categories, setCategories] = useState<Category[]>([]);
  const [treatments, setTreatments] = useState<Treatment[]>([]);
  const [addons, setAddons] = useState<Addon[]>([]);
  const [minPriceMap, setMinPriceMap] = useState<Record<string, number | null>>({});
  const [loading, setLoading] = useState(true);

  const [catModal, setCatModal] = useState<Partial<Category> | null | false>(false);
  const [treatModal, setTreatModal] = useState<Partial<Treatment> | null | false>(false);
  const [addonModal, setAddonModal] = useState<Partial<Addon> | null | false>(false);
  const [durationsTreatment, setDurationsTreatment] = useState<Treatment | null>(null);

  const [manageModal, setManageModal] = useState<{
    label: string;
    count: number;
    onDeactivate: () => Promise<void>;
    onDelete: () => Promise<void>;
  } | null>(null);

  useEffect(() => { loadAll(); }, []);

  async function loadAll() {
    setLoading(true);
    const supabase = createClient();
    const [{ data: cats }, { data: treats }, { data: ados }, { data: durations }] = await Promise.all([
      supabase.from('categories').select('*').order('sort_order', { ascending: true }).order('name'),
      supabase.from('treatments').select('id, name, description, category_id, is_active, sort_order, image_url, created_at').order('sort_order', { ascending: true }),
      supabase.from('addons').select('*').order('name'),
      supabase.from('treatment_durations').select('treatment_id, price'),
    ]);
    setCategories((cats as Category[]) ?? []);
    setTreatments((treats as Treatment[]) ?? []);
    setAddons((ados as Addon[]) ?? []);
    const priceMap: Record<string, number | null> = {};
    for (const d of (durations ?? []) as { treatment_id: string; price: number }[]) {
      const cur = priceMap[d.treatment_id];
      if (cur === undefined || cur === null || d.price < cur) priceMap[d.treatment_id] = d.price;
    }
    setMinPriceMap(priceMap);
    setLoading(false);
  }

  async function deleteCategory(id: string, name: string) {
    const supabase = createClient();
    const { count } = await supabase.from('treatments').select('id', { count: 'exact', head: true }).eq('category_id', id);
    setManageModal({
      label: `category "${name}"`,
      count: count ?? 0,
      onDeactivate: async () => {
        const result = await adminMutate('categories', 'update', { is_active: false }, { id });
        if (result.error) throw new Error(result.error);
        await loadAll();
      },
      onDelete: async () => {
        const supabase = createClient();
        try {
          const { error: deactErr } = await supabase.from('treatments').update({ is_active: false }).eq('category_id', id);
          console.log('category: treatments deactivate error:', deactErr);
          if (deactErr) throw new Error('Could not delete. Please deactivate instead.');
          const { error: catError } = await supabase.from('categories').delete().eq('id', id);
          console.log('category delete error:', catError);
          if (catError) throw new Error('Could not delete. Please deactivate instead.');
        } catch (e) {
          console.log('category catch error:', e);
          throw e;
        }
        await loadAll();
      },
    });
  }

  async function deleteTreatment(id: string, name: string) {
    const supabase = createClient();
    const { data: durationRows } = await supabase.from('treatment_durations').select('id').eq('treatment_id', id);
    const durationIds = (durationRows ?? []).map((d) => (d as { id: string }).id);
    const { count } = durationIds.length > 0
      ? await supabase.from('booking_items').select('id', { count: 'exact', head: true }).in('treatment_duration_id', durationIds)
      : { count: 0 };
    setManageModal({
      label: `treatment "${name}"`,
      count: count ?? 0,
      onDeactivate: async () => {
        const result = await adminMutate('treatments', 'update', { is_active: false }, { id });
        if (result.error) throw new Error(result.error);
        await loadAll();
      },
      onDelete: async () => {
        const supabase2 = createClient();
        try {
          const { error: durError } = await supabase2.from('treatment_durations').delete().eq('treatment_id', id);
          console.log('duration delete error:', durError);
          if (durError) throw new Error('Could not delete. Please deactivate instead.');
          const { error: treatError } = await supabase2.from('treatments').delete().eq('id', id);
          console.log('treatment delete error:', treatError);
          if (treatError) throw new Error('Could not delete. Please deactivate instead.');
        } catch (e) {
          console.log('catch error:', e);
          throw e;
        }
        await loadAll();
      },
    });
  }

  async function deleteAddon(id: string, name: string) {
    const supabase = createClient();
    const { count } = await supabase.from('booking_addons').select('id', { count: 'exact', head: true }).eq('addon_id', id);
    setManageModal({
      label: `add-on "${name}"`,
      count: count ?? 0,
      onDeactivate: async () => {
        const result = await adminMutate('addons', 'update', { is_active: false }, { id });
        if (result.error) throw new Error(result.error);
        await loadAll();
      },
      onDelete: async () => {
        const supabase2 = createClient();
        try {
          const { error: addonError } = await supabase2.from('addons').delete().eq('id', id);
          console.log('addon delete error:', addonError);
          if (addonError) throw new Error('Could not delete. Please deactivate instead.');
        } catch (e) {
          console.log('catch error:', e);
          throw e;
        }
        await loadAll();
      },
    });
  }

  const categoryMap = Object.fromEntries(categories.map((c) => [c.id, c.name]));
  const TH = 'text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide';

  return (
    <div className="space-y-5">
      <h1 className="text-2xl font-bold" style={{ color: '#2C2C2A' }}>Treatments</h1>

      <div className="flex gap-1 border-b" style={{ borderColor: '#EBE4D9' }}>
        {(['categories', 'treatments', 'addons'] as Tab[]).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className="px-4 py-2.5 text-sm font-medium capitalize transition-colors border-b-2 -mb-px"
            style={
              tab === t
                ? { borderColor: '#4E523B', color: '#4E523B' }
                : { borderColor: 'transparent', color: '#7A7A72' }
            }
          >
            {t === 'addons' ? 'Add-ons' : t.charAt(0).toUpperCase() + t.slice(1)}
          </button>
        ))}
      </div>

      {loading && (
        <div className="flex items-center justify-center h-40">
          <div className="w-7 h-7 rounded-full border-4 border-t-transparent animate-spin" style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }} />
        </div>
      )}

      {/* Categories */}
      {!loading && tab === 'categories' && (
        <div className="bg-white rounded-xl border shadow-sm" style={{ borderColor: '#EBE4D9' }}>
          <div className="flex items-center justify-between px-5 py-4 border-b" style={{ borderColor: '#EBE4D9' }}>
            <p className="text-sm font-medium" style={{ color: '#3D3D38' }}>
              {categories.length} {categories.length === 1 ? 'category' : 'categories'}
            </p>
            <button onClick={() => setCatModal({})} className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium text-white transition-colors" style={{ backgroundColor: '#4E523B' }}
              onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
            >
              <Plus className="w-4 h-4" /> Add Category
            </button>
          </div>
          {categories.length === 0 ? (
            <p className="px-5 py-10 text-center text-sm" style={{ color: '#9A9A90' }}>No categories yet.</p>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b" style={{ backgroundColor: '#FAF7F2', borderColor: '#EBE4D9' }}>
                  <th className={TH} style={{ color: '#7A7A72' }}>Name</th>
                  <th className={cn(TH, 'text-right')} style={{ color: '#7A7A72' }}>Sort Order</th>
                  <th className="px-5 py-3" />
                </tr>
              </thead>
              <tbody>
                {categories.map((c) => (
                  <tr key={c.id} className="border-t transition-colors" style={{ borderColor: '#EBE4D9' }}
                    onMouseEnter={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = '#FAF7F2'; }}
                    onMouseLeave={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = 'transparent'; }}
                  >
                    <td className="px-5 py-3 font-medium" style={{ color: '#2C2C2A' }}>{c.name}</td>
                    <td className="px-5 py-3 text-right" style={{ color: '#7A7A72' }}>{c.sort_order ?? '—'}</td>
                    <td className="px-5 py-3">
                      <div className="flex justify-end gap-2">
                        <button onClick={() => setCatModal(c)} className="p-1.5 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
                          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
                          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
                        >
                          <Pencil className="w-4 h-4" />
                        </button>
                        <button onClick={() => deleteCategory(c.id, c.name)} className="p-1.5 rounded-lg text-red-400 transition-colors"
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
          )}
        </div>
      )}

      {/* Treatments */}
      {!loading && tab === 'treatments' && (
        <div className="bg-white rounded-xl border shadow-sm" style={{ borderColor: '#EBE4D9' }}>
          <div className="flex items-center justify-between px-5 py-4 border-b" style={{ borderColor: '#EBE4D9' }}>
            <p className="text-sm font-medium" style={{ color: '#3D3D38' }}>
              {treatments.length} {treatments.length === 1 ? 'treatment' : 'treatments'}
            </p>
            <button onClick={() => setTreatModal({})} className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium text-white transition-colors" style={{ backgroundColor: '#4E523B' }}
              onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
            >
              <Plus className="w-4 h-4" /> Add Treatment
            </button>
          </div>
          {treatments.length === 0 ? (
            <p className="px-5 py-10 text-center text-sm" style={{ color: '#9A9A90' }}>No treatments yet.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b" style={{ backgroundColor: '#FAF7F2', borderColor: '#EBE4D9' }}>
                    <th className={TH} style={{ color: '#7A7A72' }}>Name</th>
                    <th className={TH} style={{ color: '#7A7A72' }}>Category</th>
                    <th className={cn(TH, 'text-right')} style={{ color: '#7A7A72' }}>Starting From</th>
                    <th className={TH} style={{ color: '#7A7A72' }}>Status</th>
                    <th className="px-5 py-3" />
                  </tr>
                </thead>
                <tbody>
                  {treatments.map((t) => (
                    <tr key={t.id} className="border-t transition-colors" style={{ borderColor: '#EBE4D9' }}
                      onMouseEnter={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = '#FAF7F2'; }}
                      onMouseLeave={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = 'transparent'; }}
                    >
                      <td className="px-5 py-3">
                        <div className="flex items-center gap-3">
                          {t.image_url && (
                            <img src={t.image_url} alt={t.name} className="w-9 h-9 rounded-lg object-cover flex-shrink-0" />
                          )}
                          <span className="font-medium" style={{ color: '#2C2C2A' }}>{t.name}</span>
                        </div>
                      </td>
                      <td className="px-5 py-3" style={{ color: '#5A5A52' }}>
                        {t.category_id ? (categoryMap[t.category_id] ?? '—') : '—'}
                      </td>
                      <td className="px-5 py-3 text-right" style={{ color: '#3D3D38' }}>
                        {minPriceMap[t.id] != null
                          ? <span>From {formatRupiah(minPriceMap[t.id]!)}</span>
                          : <span style={{ color: '#9A9A90' }}>—</span>}
                      </td>
                      <td className="px-5 py-3">
                        <span className="inline-flex px-2 py-0.5 rounded-full text-xs font-medium"
                          style={t.is_active ? { backgroundColor: '#E8EBE0', color: '#4E523B' } : { backgroundColor: '#F0ECE5', color: '#7A7A72' }}
                        >
                          {t.is_active ? 'Active' : 'Inactive'}
                        </span>
                      </td>
                      <td className="px-5 py-3">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => setDurationsTreatment(t)}
                            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors border"
                            style={
                              minPriceMap[t.id] != null
                                ? { backgroundColor: '#F0F2E8', color: '#4E523B', borderColor: '#C5CAB0' }
                                : { backgroundColor: '#FFFBEB', color: '#B45309', borderColor: '#FDE68A' }
                            }
                            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.opacity = '0.8'; }}
                            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.opacity = '1'; }}
                          >
                            <Plus className="w-3.5 h-3.5" />
                            Durations & Prices
                          </button>
                          <button onClick={() => setTreatModal(t)} className="p-1.5 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
                            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
                            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
                          >
                            <Pencil className="w-4 h-4" />
                          </button>
                          <button onClick={() => deleteTreatment(t.id, t.name)} className="p-1.5 rounded-lg text-red-400 transition-colors"
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
          )}
        </div>
      )}

      {/* Add-ons */}
      {!loading && tab === 'addons' && (
        <div className="bg-white rounded-xl border shadow-sm" style={{ borderColor: '#EBE4D9' }}>
          <div className="flex items-center justify-between px-5 py-4 border-b" style={{ borderColor: '#EBE4D9' }}>
            <p className="text-sm font-medium" style={{ color: '#3D3D38' }}>
              {addons.length} add-on{addons.length !== 1 ? 's' : ''}
            </p>
            <button onClick={() => setAddonModal({})} className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium text-white transition-colors" style={{ backgroundColor: '#4E523B' }}
              onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
            >
              <Plus className="w-4 h-4" /> Add Add-on
            </button>
          </div>
          {addons.length === 0 ? (
            <p className="px-5 py-10 text-center text-sm" style={{ color: '#9A9A90' }}>No add-ons yet.</p>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b" style={{ backgroundColor: '#FAF7F2', borderColor: '#EBE4D9' }}>
                  <th className={TH} style={{ color: '#7A7A72' }}>Name</th>
                  <th className={cn(TH, 'text-right')} style={{ color: '#7A7A72' }}>Price</th>
                  <th className={TH} style={{ color: '#7A7A72' }}>Status</th>
                  <th className="px-5 py-3" />
                </tr>
              </thead>
              <tbody>
                {addons.map((a) => (
                  <tr key={a.id} className="border-t transition-colors" style={{ borderColor: '#EBE4D9' }}
                    onMouseEnter={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = '#FAF7F2'; }}
                    onMouseLeave={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = 'transparent'; }}
                  >
                    <td className="px-5 py-3">
                      <p className="font-medium" style={{ color: '#2C2C2A' }}>{a.name}</p>
                      {a.description && <p className="text-xs mt-0.5" style={{ color: '#9A9A90' }}>{a.description}</p>}
                    </td>
                    <td className="px-5 py-3 text-right" style={{ color: '#3D3D38' }}>{formatRupiah(a.price)}</td>
                    <td className="px-5 py-3">
                      <span className="inline-flex px-2 py-0.5 rounded-full text-xs font-medium"
                        style={a.is_active ? { backgroundColor: '#E8EBE0', color: '#4E523B' } : { backgroundColor: '#F0ECE5', color: '#7A7A72' }}
                      >
                        {a.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td className="px-5 py-3">
                      <div className="flex justify-end gap-2">
                        <button onClick={() => setAddonModal(a)} className="p-1.5 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
                          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
                          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
                        >
                          <Pencil className="w-4 h-4" />
                        </button>
                        <button onClick={() => deleteAddon(a.id, a.name)} className="p-1.5 rounded-lg text-red-400 transition-colors"
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
          )}
        </div>
      )}

      {catModal !== false && (
        <CategoryModal item={catModal} onClose={() => setCatModal(false)} onSaved={loadAll} />
      )}
      {treatModal !== false && (
        <TreatmentModal item={treatModal} categories={categories} onClose={() => setTreatModal(false)} onSaved={loadAll} />
      )}
      {addonModal !== false && (
        <AddonModal item={addonModal} onClose={() => setAddonModal(false)} onSaved={loadAll} />
      )}
      {durationsTreatment && (
        <DurationsModal treatment={durationsTreatment} onClose={() => setDurationsTreatment(null)} onSaved={loadAll} />
      )}

      {manageModal && (
        <ManageItemModal
          label={manageModal.label}
          count={manageModal.count}
          onDeactivate={manageModal.onDeactivate}
          onDelete={manageModal.onDelete}
          onClose={() => setManageModal(null)}
        />
      )}
    </div>
  );
}
