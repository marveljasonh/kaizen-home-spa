'use client';

import { useEffect, useState } from 'react';
import { Plus, Pencil, Trash2, X } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import type { Branch } from '@/types';

function BranchModal({
  item,
  onClose,
  onSaved,
}: {
  item: Partial<Branch> | null;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [name, setName] = useState(item?.name ?? '');
  const [address, setAddress] = useState(item?.address ?? '');
  const [lat, setLat] = useState(item?.lat?.toString() ?? '');
  const [lng, setLng] = useState(item?.lng?.toString() ?? '');
  const [radiusKm, setRadiusKm] = useState(item?.radius_km?.toString() ?? '');
  const [capacity, setCapacity] = useState(item?.capacity?.toString() ?? '');
  const [isActive, setIsActive] = useState(item?.is_active ?? true);
  const [saving, setSaving] = useState(false);

  async function handleSave() {
    if (!name.trim()) return;
    setSaving(true);
    const supabase = createClient();
    const payload: Record<string, unknown> = {
      name,
      address: address || null,
      lat: lat !== '' ? parseFloat(lat) : null,
      lng: lng !== '' ? parseFloat(lng) : null,
      radius_km: radiusKm !== '' ? parseFloat(radiusKm) : null,
      capacity: capacity !== '' ? parseInt(capacity, 10) : null,
      is_active: isActive,
    };
    if (item?.id) {
      await supabase.from('branches').update(payload).eq('id', item.id);
    } else {
      await supabase.from('branches').insert(payload);
    }
    setSaving(false);
    onSaved();
    onClose();
  }

  const inputCls = 'w-full px-3 py-2 rounded-lg border text-sm focus:outline-none focus:ring-2 focus:ring-[#4E523B]';
  const inputStyle = { borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' };
  const labelStyle = { color: '#3D3D38' };

  return (
    <div className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl border shadow-xl w-full max-w-md" style={{ borderColor: '#EBE4D9' }}>
        <div className="flex items-center justify-between px-5 py-4 border-b" style={{ borderColor: '#EBE4D9' }}>
          <h3 className="font-semibold" style={{ color: '#2C2C2A' }}>
            {item?.id ? 'Edit Branch' : 'Add Branch'}
          </h3>
          <button onClick={onClose} className="p-1 rounded-lg transition-colors" style={{ color: '#9A9A90' }}
            onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
            onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
          >
            <X className="w-4 h-4" />
          </button>
        </div>
        <div className="p-5 space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1.5" style={labelStyle}>Name *</label>
            <input value={name} onChange={(e) => setName(e.target.value)} className={inputCls} style={inputStyle} />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1.5" style={labelStyle}>Address</label>
            <textarea value={address} onChange={(e) => setAddress(e.target.value)} rows={2} className={`${inputCls} resize-none`} style={inputStyle} />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium mb-1.5" style={labelStyle}>Latitude</label>
              <input type="number" step="any" value={lat} onChange={(e) => setLat(e.target.value)} placeholder="-6.2088" className={inputCls} style={inputStyle} />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1.5" style={labelStyle}>Longitude</label>
              <input type="number" step="any" value={lng} onChange={(e) => setLng(e.target.value)} placeholder="106.8456" className={inputCls} style={inputStyle} />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium mb-1.5" style={labelStyle}>Radius (km)</label>
              <input type="number" step="any" min="0" value={radiusKm} onChange={(e) => setRadiusKm(e.target.value)} placeholder="10" className={inputCls} style={inputStyle} />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1.5" style={labelStyle}>Capacity</label>
              <input type="number" min="0" value={capacity} onChange={(e) => setCapacity(e.target.value)} placeholder="20" className={inputCls} style={inputStyle} />
            </div>
          </div>
          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="branchIsActive"
              checked={isActive}
              onChange={(e) => setIsActive(e.target.checked)}
              className="w-4 h-4 rounded"
              style={{ accentColor: '#4E523B' }}
            />
            <label htmlFor="branchIsActive" className="text-sm" style={{ color: '#3D3D38' }}>Active</label>
          </div>
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
            {saving ? 'Saving...' : 'Save'}
          </button>
        </div>
      </div>
    </div>
  );
}

export default function BranchesPage() {
  const [branches, setBranches] = useState<Branch[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState<Partial<Branch> | null | false>(false);

  useEffect(() => { loadBranches(); }, []);

  async function loadBranches() {
    setLoading(true);
    const supabase = createClient();
    const { data } = await supabase.from('branches').select('*').order('name');
    setBranches((data as Branch[]) ?? []);
    setLoading(false);
  }

  async function deleteBranch(id: string) {
    if (!confirm('Delete this branch?')) return;
    const supabase = createClient();
    await supabase.from('branches').delete().eq('id', id);
    await loadBranches();
  }

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold" style={{ color: '#2C2C2A' }}>Branches</h1>
        <button
          onClick={() => setModal({})}
          className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-sm font-medium text-white transition-colors"
          style={{ backgroundColor: '#4E523B' }}
          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
        >
          <Plus className="w-4 h-4" /> Add Branch
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
                  <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Name</th>
                  <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Address</th>
                  <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Coordinates</th>
                  <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Radius / Cap</th>
                  <th className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide" style={{ color: '#7A7A72' }}>Status</th>
                  <th className="px-5 py-3" />
                </tr>
              </thead>
              <tbody>
                {branches.length === 0 && (
                  <tr>
                    <td colSpan={6} className="px-5 py-10 text-center" style={{ color: '#9A9A90' }}>
                      No branches found
                    </td>
                  </tr>
                )}
                {branches.map((b) => (
                  <tr key={b.id} className="border-t transition-colors" style={{ borderColor: '#EBE4D9' }}
                    onMouseEnter={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = '#FAF7F2'; }}
                    onMouseLeave={(e) => { (e.currentTarget as HTMLTableRowElement).style.backgroundColor = 'transparent'; }}
                  >
                    <td className="px-5 py-3 font-medium" style={{ color: '#2C2C2A' }}>{b.name}</td>
                    <td className="px-5 py-3 max-w-xs truncate" style={{ color: '#5A5A52' }}>{b.address ?? '—'}</td>
                    <td className="px-5 py-3 font-mono text-xs whitespace-nowrap" style={{ color: '#5A5A52' }}>
                      {b.lat != null && b.lng != null ? `${b.lat}, ${b.lng}` : '—'}
                    </td>
                    <td className="px-5 py-3 whitespace-nowrap" style={{ color: '#5A5A52' }}>
                      {b.radius_km != null ? `${b.radius_km} km` : '—'} / {b.capacity != null ? b.capacity : '—'}
                    </td>
                    <td className="px-5 py-3">
                      <span
                        className="inline-flex px-2 py-0.5 rounded-full text-xs font-medium"
                        style={
                          b.is_active
                            ? { backgroundColor: '#E8EBE0', color: '#4E523B' }
                            : { backgroundColor: '#F0ECE5', color: '#7A7A72' }
                        }
                      >
                        {b.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td className="px-5 py-3">
                      <div className="flex justify-end gap-2">
                        <button
                          onClick={() => setModal(b)}
                          className="p-1.5 rounded-lg transition-colors"
                          style={{ color: '#9A9A90' }}
                          onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
                          onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
                        >
                          <Pencil className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => deleteBranch(b.id)}
                          className="p-1.5 rounded-lg text-red-400 transition-colors"
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

      {modal !== false && (
        <BranchModal item={modal} onClose={() => setModal(false)} onSaved={loadBranches} />
      )}
    </div>
  );
}
