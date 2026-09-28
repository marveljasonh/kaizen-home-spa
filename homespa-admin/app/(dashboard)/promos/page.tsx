'use client';

import { useEffect, useRef, useState } from 'react';
import { Plus, Pencil, Trash2, X, Upload, AlertCircle } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { adminMutate } from '@/lib/adminMutate';
import { cn, formatRupiah, formatDate } from '@/lib/utils';
import type { Banner, Voucher } from '@/types';

type Tab = 'banners' | 'vouchers';

const INPUT = 'w-full px-3 py-2 rounded-lg border text-sm focus:outline-none focus:ring-2 focus:ring-[#4E523B]';
const LABEL = 'block text-sm font-medium mb-1.5';
const inputStyle = { borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' };
const labelStyle = { color: '#3D3D38' };

const BTN_PRIMARY = 'px-4 py-2 rounded-lg text-sm font-medium text-white disabled:opacity-60 transition-colors';
const BTN_GHOST = 'px-4 py-2 rounded-lg text-sm font-medium transition-colors';

function ErrorBanner({ message }: { message: string }) {
  return (
    <div className="flex items-start gap-2 px-4 py-3 rounded-lg border border-red-200 text-red-700 text-sm" style={{ backgroundColor: '#FEF2F2' }}>
      <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
      <span>{message}</span>
    </div>
  );
}

function ConflictModal({ message, canDeactivate, deactivating, onDeactivate, onClose }: {
  message: string; canDeactivate: boolean; deactivating: boolean; onDeactivate?: () => void; onClose: () => void;
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

function BannerModal({ item, onClose, onSaved }: { item: Partial<Banner> | null; onClose: () => void; onSaved: () => void; }) {
  const [title, setTitle] = useState(item?.title ?? '');
  const [subtitle, setSubtitle] = useState(item?.subtitle ?? '');
  const [imageUrl, setImageUrl] = useState(item?.image_url ?? '');
  const [isActive, setIsActive] = useState(item?.is_active ?? true);
  const [sortOrder, setSortOrder] = useState(String(item?.sort_order ?? 0));
  const [validFrom, setValidFrom] = useState(item?.valid_from ? item.valid_from.slice(0, 10) : '');
  const [validUntil, setValidUntil] = useState(item?.valid_until ? item.valid_until.slice(0, 10) : '');
  const [actionType, setActionType] = useState(item?.action_type ?? '');
  const [actionValue, setActionValue] = useState(item?.action_value ?? '');
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  async function handleImageUpload(file: File) {
    setUploading(true);
    const supabase = createClient();
    const ext = file.name.split('.').pop() ?? 'jpg';
    const path = `${Date.now()}.${ext}`;
    const { error: uploadError } = await supabase.storage.from('banners').upload(path, file, { upsert: true, contentType: file.type });
    if (!uploadError) {
      const { data: { publicUrl } } = supabase.storage.from('banners').getPublicUrl(path);
      setImageUrl(publicUrl);
    } else {
      setError(`Image upload failed: ${uploadError.message}`);
    }
    setUploading(false);
  }

  async function handleSave() {
    if (!title.trim()) { setError('Title is required'); return; }
    setSaving(true);
    setError(null);
    const payload: Record<string, unknown> = {
      title: title.trim(),
      subtitle: subtitle.trim() || null,
      image_url: imageUrl.trim() || null,
      is_active: isActive,
      sort_order: Number(sortOrder) || 0,
      valid_from: validFrom || null,
      valid_until: validUntil || null,
      action_type: actionType.trim() || null,
      action_value: actionValue.trim() || null,
    };
    console.log('[BannerModal] saving payload:', payload);
    const result = item?.id
      ? await adminMutate('banners', 'update', payload, { id: item.id })
      : await adminMutate('banners', 'insert', payload);
    console.log('[BannerModal] result:', result);
    setSaving(false);
    if (result.error) { setError(result.error); return; }
    onSaved();
    onClose();
  }

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl border shadow-xl w-full max-w-lg max-h-[90vh] flex flex-col" style={{ borderColor: '#EBE4D9' }}>
        <div className="flex items-center justify-between px-5 py-4 border-b flex-shrink-0" style={{ borderColor: '#EBE4D9' }}>
          <h3 className="font-semibold" style={{ color: '#2C2C2A' }}>{item?.id ? 'Edit Banner' : 'Add Banner'}</h3>
          <button onClick={onClose} className="p-1 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
          >
            <X className="w-4 h-4" />
          </button>
        </div>
        <div className="p-5 space-y-4 overflow-y-auto flex-1">
          {error && <ErrorBanner message={error} />}
          <div>
            <label className={LABEL} style={labelStyle}>Title *</label>
            <input autoFocus value={title} onChange={(e) => setTitle(e.target.value)} className={INPUT} style={inputStyle} />
          </div>
          <div>
            <label className={LABEL} style={labelStyle}>Subtitle</label>
            <input value={subtitle} onChange={(e) => setSubtitle(e.target.value)} className={INPUT} style={inputStyle} />
          </div>
          <div>
            <label className={LABEL} style={labelStyle}>Image</label>
            {imageUrl && (
              <div className="relative mb-2 rounded-lg overflow-hidden">
                <img src={imageUrl} alt="Preview" className="w-full h-36 object-cover" />
                <button type="button" onClick={() => setImageUrl('')} className="absolute top-1.5 right-1.5 p-1 bg-black/50 rounded-full text-white hover:bg-black/70">
                  <X className="w-3 h-3" />
                </button>
              </div>
            )}
            <input ref={fileInputRef} type="file" accept="image/*" className="hidden" onChange={(e) => { const f = e.target.files?.[0]; if (f) handleImageUpload(f); }} />
            <button type="button" onClick={() => fileInputRef.current?.click()} disabled={uploading}
              className="flex items-center gap-2 w-full px-3 py-2 rounded-lg border border-dashed text-sm disabled:opacity-50 transition-colors"
              style={{ borderColor: '#EBE4D9', color: '#7A7A72' }}
              onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.borderColor = '#4E523B'; (e.currentTarget as HTMLButtonElement).style.color = '#4E523B'; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.borderColor = '#EBE4D9'; (e.currentTarget as HTMLButtonElement).style.color = '#7A7A72'; }}
            >
              <Upload className="w-4 h-4" />
              {uploading ? 'Uploading…' : 'Upload image'}
            </button>
            <p className="text-xs mt-1.5" style={{ color: '#9A9A90' }}>Or paste a URL:</p>
            <input value={imageUrl} onChange={(e) => setImageUrl(e.target.value)} placeholder="https://…" className={cn(INPUT, 'mt-1')} style={inputStyle} />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={LABEL} style={labelStyle}>Valid From</label>
              <input type="date" value={validFrom} onChange={(e) => setValidFrom(e.target.value)} className={INPUT} style={inputStyle} />
            </div>
            <div>
              <label className={LABEL} style={labelStyle}>Valid Until</label>
              <input type="date" value={validUntil} onChange={(e) => setValidUntil(e.target.value)} className={INPUT} style={inputStyle} />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={LABEL} style={labelStyle}>Action Type</label>
              <input value={actionType} onChange={(e) => setActionType(e.target.value)} placeholder="e.g. treatment, url" className={INPUT} style={inputStyle} />
            </div>
            <div>
              <label className={LABEL} style={labelStyle}>Action Value</label>
              <input value={actionValue} onChange={(e) => setActionValue(e.target.value)} placeholder="ID or URL" className={INPUT} style={inputStyle} />
            </div>
          </div>
          <div>
            <label className={LABEL} style={labelStyle}>Sort Order</label>
            <input type="number" value={sortOrder} onChange={(e) => setSortOrder(e.target.value)} className={INPUT} style={inputStyle} />
          </div>
          <label className="flex items-center gap-2 cursor-pointer">
            <input type="checkbox" id="bannerIsActive" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} className="w-4 h-4 rounded" style={{ accentColor: '#4E523B' }} />
            <span className="text-sm" style={{ color: '#3D3D38' }}>Active</span>
          </label>
        </div>
        <div className="flex justify-end gap-2 px-5 py-4 border-t flex-shrink-0" style={{ borderColor: '#EBE4D9' }}>
          <button onClick={onClose} className={BTN_GHOST} style={{ backgroundColor: '#F0ECE5', color: '#3D3D38' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#EBE4D9'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
          >Cancel</button>
          <button onClick={handleSave} disabled={saving || uploading} className={BTN_PRIMARY} style={{ backgroundColor: '#4E523B' }}
            onMouseEnter={(e) => { if (!saving) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
          >{saving ? 'Saving…' : 'Save'}</button>
        </div>
      </div>
    </div>
  );
}

function VoucherModal({ item, onClose, onSaved }: { item: Partial<Voucher> | null; onClose: () => void; onSaved: () => void; }) {
  const [code, setCode] = useState(item?.code ?? '');
  const [description, setDescription] = useState(item?.description ?? '');
  const [discountType, setDiscountType] = useState<'percentage' | 'fixed'>(item?.discount_type ?? 'percentage');
  const [discountValue, setDiscountValue] = useState(String(item?.discount_value ?? ''));
  const [minPurchase, setMinPurchase] = useState(String(item?.min_purchase ?? 0));
  const [validUntil, setValidUntil] = useState(item?.valid_until ? item.valid_until.slice(0, 10) : '');
  const [isActive, setIsActive] = useState(item?.is_active ?? true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSave() {
    if (!code.trim()) { setError('Code is required'); return; }
    setSaving(true);
    setError(null);
    const payload: Record<string, unknown> = {
      code: code.toUpperCase().trim(),
      description: description.trim() || null,
      discount_type: discountType,
      discount_value: Number(discountValue) || 0,
      min_purchase: Number(minPurchase) || 0,
      valid_until: validUntil || null,
      is_active: isActive,
    };
    console.log('[VoucherModal] saving payload:', payload);
    const result = item?.id
      ? await adminMutate('vouchers', 'update', payload, { id: item.id })
      : await adminMutate('vouchers', 'insert', payload);
    console.log('[VoucherModal] result:', result);
    setSaving(false);
    if (result.error) { setError(result.error); return; }
    onSaved();
    onClose();
  }

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl border shadow-xl w-full max-w-md max-h-[90vh] flex flex-col" style={{ borderColor: '#EBE4D9' }}>
        <div className="flex items-center justify-between px-5 py-4 border-b flex-shrink-0" style={{ borderColor: '#EBE4D9' }}>
          <h3 className="font-semibold" style={{ color: '#2C2C2A' }}>{item?.id ? 'Edit Voucher' : 'Add Voucher'}</h3>
          <button onClick={onClose} className="p-1 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
          >
            <X className="w-4 h-4" />
          </button>
        </div>
        <div className="p-5 space-y-4 overflow-y-auto flex-1">
          {error && <ErrorBanner message={error} />}
          <div>
            <label className={LABEL} style={labelStyle}>Code *</label>
            <input autoFocus value={code} onChange={(e) => setCode(e.target.value.toUpperCase())} placeholder="PROMO20" className={cn(INPUT, 'font-mono')} style={inputStyle} />
          </div>
          <div>
            <label className={LABEL} style={labelStyle}>Description</label>
            <input value={description} onChange={(e) => setDescription(e.target.value)} className={INPUT} style={inputStyle} />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={LABEL} style={labelStyle}>Discount Type</label>
              <select value={discountType} onChange={(e) => setDiscountType(e.target.value as 'percentage' | 'fixed')} className={INPUT} style={inputStyle}>
                <option value="percentage">Percentage (%)</option>
                <option value="fixed">Fixed (IDR)</option>
              </select>
            </div>
            <div>
              <label className={LABEL} style={labelStyle}>Discount Value</label>
              <input type="number" value={discountValue} onChange={(e) => setDiscountValue(e.target.value)} className={INPUT} style={inputStyle} />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={LABEL} style={labelStyle}>Min. Purchase (IDR)</label>
              <input type="number" value={minPurchase} onChange={(e) => setMinPurchase(e.target.value)} className={INPUT} style={inputStyle} />
            </div>
            <div>
              <label className={LABEL} style={labelStyle}>Valid Until</label>
              <input type="date" value={validUntil} onChange={(e) => setValidUntil(e.target.value)} className={INPUT} style={inputStyle} />
            </div>
          </div>
          <label className="flex items-center gap-2 cursor-pointer">
            <input type="checkbox" id="voucherIsActive" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} className="w-4 h-4 rounded" style={{ accentColor: '#4E523B' }} />
            <span className="text-sm" style={{ color: '#3D3D38' }}>Active</span>
          </label>
        </div>
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

function ManageVoucherModal({
  voucher,
  onClose,
  onDeactivated,
  onDeleted,
}: {
  voucher: Voucher;
  onClose: () => void;
  onDeactivated: () => void;
  onDeleted: () => void;
}) {
  const [usageCount, setUsageCount] = useState<number | null>(null);
  const [working, setWorking] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const supabase = createClient();
    supabase
      .from('client_vouchers')
      .select('id', { count: 'exact', head: true })
      .eq('voucher_id', voucher.id)
      .then(({ count }) => setUsageCount(count ?? 0));
  }, [voucher.id]);

  async function handleDeactivate() {
    setWorking(true);
    setError(null);
    const result = await adminMutate('vouchers', 'update', { is_active: false }, { id: voucher.id });
    setWorking(false);
    if (result.error) { setError(result.error); return; }
    onDeactivated();
    onClose();
  }

  async function handleDeletePermanently() {
    setWorking(true);
    setError(null);
    if ((usageCount ?? 0) > 0) {
      const r1 = await adminMutate('client_vouchers', 'delete', undefined, { voucher_id: voucher.id });
      if (r1.error) { setError(r1.error); setWorking(false); return; }
    }
    const r2 = await adminMutate('vouchers', 'delete', undefined, { id: voucher.id });
    setWorking(false);
    if (r2.error) { setError(r2.error); return; }
    onDeleted();
    onClose();
  }

  const loading = usageCount === null;
  const hasUsage = (usageCount ?? 0) > 0;

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl border shadow-xl w-full max-w-md" style={{ borderColor: '#EBE4D9' }}>
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b" style={{ borderColor: '#EBE4D9' }}>
          <h3 className="font-semibold" style={{ color: '#2C2C2A' }}>Manage Voucher</h3>
          <button onClick={onClose} className="p-1 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Body */}
        <div className="px-5 py-5 space-y-4">
          {/* Voucher summary */}
          <div className="rounded-lg px-4 py-3" style={{ backgroundColor: '#FAF7F2', border: '1px solid #EBE4D9' }}>
            <p className="font-mono font-semibold" style={{ color: '#2C2C2A' }}>{voucher.code}</p>
            {voucher.description && (
              <p className="text-xs mt-0.5" style={{ color: '#7A7A72' }}>{voucher.description}</p>
            )}
          </div>

          {loading ? (
            <div className="flex items-center gap-2 text-sm" style={{ color: '#7A7A72' }}>
              <div className="w-4 h-4 rounded-full border-2 animate-spin flex-shrink-0"
                style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }} />
              Checking usage history…
            </div>
          ) : hasUsage ? (
            <>
              {/* Usage warning */}
              <div className="flex items-start gap-3 px-4 py-3 rounded-lg border"
                style={{ backgroundColor: '#FFFBEB', borderColor: '#FDE68A' }}>
                <AlertCircle className="w-4 h-4 flex-shrink-0 mt-0.5" style={{ color: '#92400E' }} />
                <p className="text-sm" style={{ color: '#92400E' }}>
                  This voucher has been used by{' '}
                  <span className="font-bold">{usageCount} client{usageCount !== 1 ? 's' : ''}</span>.
                  {' '}Deleting will remove all usage history.
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
                    Safe option — clients keep their used vouchers. Voucher won&apos;t be accepted for new bookings.
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
                  {working ? 'Working…' : 'Deactivate Voucher'}
                </button>
              </div>

              {/* Delete permanently option */}
              <div className="rounded-lg border p-4 space-y-2.5" style={{ borderColor: '#FCA5A5' }}>
                <div>
                  <p className="text-sm font-semibold" style={{ color: '#DC2626' }}>Delete Permanently</p>
                  <p className="text-xs mt-1" style={{ color: '#7A7A72' }}>
                    Removes the voucher and all {usageCount} usage record{usageCount !== 1 ? 's' : ''}.
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
                <span className="font-mono font-semibold">{voucher.code}</span>?
                This voucher has no usage history, so nothing else will be lost.
              </p>
              <button
                onClick={handleDeletePermanently}
                disabled={working}
                className="w-full px-4 py-2 rounded-lg text-sm font-medium text-white disabled:opacity-60 transition-colors"
                style={{ backgroundColor: '#DC2626' }}
                onMouseEnter={(e) => { if (!working) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#B91C1C'; }}
                onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#DC2626'; }}
              >
                {working ? 'Deleting…' : 'Delete Voucher'}
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

export default function PromosPage() {
  const [tab, setTab] = useState<Tab>('banners');
  const [banners, setBanners] = useState<Banner[]>([]);
  const [vouchers, setVouchers] = useState<Voucher[]>([]);
  const [loading, setLoading] = useState(true);
  const [bannerModal, setBannerModal] = useState<Partial<Banner> | null | false>(false);
  const [voucherModal, setVoucherModal] = useState<Partial<Voucher> | null | false>(false);
  const [manageVoucher, setManageVoucher] = useState<Voucher | null>(null);
  const [conflict, setConflict] = useState<{
    message: string;
    canDeactivate: boolean;
    onDeactivate?: () => Promise<void>;
  } | null>(null);
  const [deactivating, setDeactivating] = useState(false);

  useEffect(() => { loadAll(); }, []);

  async function loadAll() {
    setLoading(true);
    const supabase = createClient();
    const [{ data: b }, { data: v }] = await Promise.all([
      supabase.from('banners').select('*').order('sort_order', { ascending: true }),
      supabase.from('vouchers').select('*').order('created_at', { ascending: false }),
    ]);
    setBanners((b as Banner[]) ?? []);
    setVouchers((v as Voucher[]) ?? []);
    setLoading(false);
  }

  async function deleteBanner(id: string) {
    if (!confirm('Delete this banner?')) return;
    const result = await adminMutate('banners', 'delete', undefined, { id });
    if (result.error) { setConflict({ message: `Delete failed: ${result.error}`, canDeactivate: false }); return; }
    await loadAll();
  }


  function discountLabel(v: Voucher) {
    return v.discount_type === 'percentage'
      ? `${v.discount_value}% OFF`
      : `${formatRupiah(v.discount_value)} OFF`;
  }

  return (
    <div className="space-y-5">
      <h1 className="text-2xl font-bold" style={{ color: '#2C2C2A' }}>Promos</h1>

      <div className="flex gap-1 border-b" style={{ borderColor: '#EBE4D9' }}>
        {(['banners', 'vouchers'] as Tab[]).map((t) => (
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
            {t.charAt(0).toUpperCase() + t.slice(1)}
          </button>
        ))}
      </div>

      {loading && (
        <div className="flex items-center justify-center h-40">
          <div className="w-7 h-7 rounded-full border-4 border-t-transparent animate-spin" style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }} />
        </div>
      )}

      {/* Banners */}
      {!loading && tab === 'banners' && (
        <>
          <div className="flex justify-end">
            <button onClick={() => setBannerModal({})} className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium text-white transition-colors" style={{ backgroundColor: '#4E523B' }}
              onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
            >
              <Plus className="w-4 h-4" /> Add Banner
            </button>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
            {banners.length === 0 && (
              <p className="col-span-full text-center py-10 text-sm" style={{ color: '#9A9A90' }}>No banners yet.</p>
            )}
            {banners.map((b) => (
              <div key={b.id} className="bg-white rounded-xl border shadow-sm overflow-hidden" style={{ borderColor: '#EBE4D9' }}>
                {b.image_url ? (
                  <img src={b.image_url} alt={b.title} className="w-full h-36 object-cover" />
                ) : (
                  <div className="w-full h-36 flex items-center justify-center" style={{ backgroundColor: '#F0F2E8' }}>
                    <span className="text-sm font-medium" style={{ color: '#6B7057' }}>No Image</span>
                  </div>
                )}
                <div className="p-4">
                  <div className="flex items-start justify-between gap-2 mb-1">
                    <p className="font-semibold leading-snug" style={{ color: '#2C2C2A' }}>{b.title}</p>
                    <span
                      className="flex-shrink-0 inline-flex px-2 py-0.5 rounded-full text-xs font-medium"
                      style={b.is_active ? { backgroundColor: '#E8EBE0', color: '#4E523B' } : { backgroundColor: '#F0ECE5', color: '#7A7A72' }}
                    >
                      {b.is_active ? 'Active' : 'Inactive'}
                    </span>
                  </div>
                  {b.subtitle && (
                    <p className="text-sm mb-2" style={{ color: '#7A7A72' }}>{b.subtitle}</p>
                  )}
                  <p className="text-xs" style={{ color: '#9A9A90' }}>
                    {b.valid_from && b.valid_until
                      ? `${formatDate(b.valid_from)} – ${formatDate(b.valid_until)}`
                      : b.valid_from
                      ? `From ${formatDate(b.valid_from)}`
                      : b.valid_until
                      ? `Until ${formatDate(b.valid_until)}`
                      : 'No date set'}
                  </p>
                  {b.action_type && (
                    <p className="text-xs mt-0.5" style={{ color: '#9A9A90' }}>
                      Action: <span className="font-mono">{b.action_type}</span>
                      {b.action_value && ` → ${b.action_value}`}
                    </p>
                  )}
                  <div className="flex justify-end gap-2 mt-3 pt-3 border-t" style={{ borderColor: '#EBE4D9' }}>
                    <button onClick={() => setBannerModal(b)} className="p-1.5 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
                      onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
                      onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
                    >
                      <Pencil className="w-4 h-4" />
                    </button>
                    <button onClick={() => deleteBanner(b.id)} className="p-1.5 rounded-lg text-red-400 transition-colors"
                      onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#FEF2F2'; }}
                      onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </>
      )}

      {/* Vouchers */}
      {!loading && tab === 'vouchers' && (
        <>
          <div className="flex justify-end">
            <button onClick={() => setVoucherModal({})} className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium text-white transition-colors" style={{ backgroundColor: '#4E523B' }}
              onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
              onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
            >
              <Plus className="w-4 h-4" /> Add Voucher
            </button>
          </div>
          <div className="bg-white rounded-xl border shadow-sm overflow-hidden" style={{ borderColor: '#EBE4D9' }}>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b" style={{ backgroundColor: '#FAF7F2', borderColor: '#EBE4D9' }}>
                    <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Code</th>
                    <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Discount</th>
                    <th className="text-right px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Min. Purchase</th>
                    <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Valid Until</th>
                    <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Status</th>
                    <th className="px-5 py-3" />
                  </tr>
                </thead>
                <tbody>
                  {vouchers.length === 0 && (
                    <tr>
                      <td colSpan={6} className="px-5 py-10 text-center text-sm" style={{ color: '#9A9A90' }}>No vouchers yet.</td>
                    </tr>
                  )}
                  {vouchers.map((v) => (
                    <tr key={v.id} className="border-t transition-colors" style={{ borderColor: '#EBE4D9' }}
                      onMouseEnter={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = '#FAF7F2'; }}
                      onMouseLeave={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = 'transparent'; }}
                    >
                      <td className="px-5 py-3">
                        <span className="font-mono font-semibold" style={{ color: '#2C2C2A' }}>{v.code}</span>
                        {v.description && (
                          <p className="text-xs mt-0.5" style={{ color: '#9A9A90' }}>{v.description}</p>
                        )}
                      </td>
                      <td className="px-5 py-3">
                        <span className="font-medium text-orange-600">{discountLabel(v)}</span>
                      </td>
                      <td className="px-5 py-3 text-right" style={{ color: '#5A5A52' }}>{formatRupiah(v.min_purchase)}</td>
                      <td className="px-5 py-3" style={{ color: '#5A5A52' }}>{v.valid_until ? formatDate(v.valid_until) : '—'}</td>
                      <td className="px-5 py-3">
                        <span
                          className="inline-flex px-2 py-0.5 rounded-full text-xs font-medium"
                          style={v.is_active ? { backgroundColor: '#E8EBE0', color: '#4E523B' } : { backgroundColor: '#F0ECE5', color: '#7A7A72' }}
                        >
                          {v.is_active ? 'Active' : 'Inactive'}
                        </span>
                      </td>
                      <td className="px-5 py-3">
                        <div className="flex justify-end gap-2">
                          <button onClick={() => setVoucherModal(v)} className="p-1.5 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
                            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
                            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
                          >
                            <Pencil className="w-4 h-4" />
                          </button>
                          <button onClick={() => setManageVoucher(v)} className="p-1.5 rounded-lg text-red-400 transition-colors"
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
        </>
      )}

      {bannerModal !== false && (
        <BannerModal item={bannerModal} onClose={() => setBannerModal(false)} onSaved={loadAll} />
      )}
      {voucherModal !== false && (
        <VoucherModal item={voucherModal} onClose={() => setVoucherModal(false)} onSaved={loadAll} />
      )}
      {manageVoucher && (
        <ManageVoucherModal
          voucher={manageVoucher}
          onClose={() => setManageVoucher(null)}
          onDeactivated={() => {
            setVouchers((prev) => prev.map((v) => v.id === manageVoucher.id ? { ...v, is_active: false } : v));
          }}
          onDeleted={() => {
            setVouchers((prev) => prev.filter((v) => v.id !== manageVoucher.id));
          }}
        />
      )}
      {conflict && (
        <ConflictModal
          message={conflict.message}
          canDeactivate={conflict.canDeactivate}
          deactivating={deactivating}
          onDeactivate={conflict.onDeactivate}
          onClose={() => setConflict(null)}
        />
      )}
    </div>
  );
}
