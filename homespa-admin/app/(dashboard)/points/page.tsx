'use client';

import { useEffect, useState } from 'react';
import { Pencil, Check, X, AlertCircle } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { adminMutate } from '@/lib/adminMutate';
import { formatRupiah } from '@/lib/utils';

interface DurationWithPoints {
  id: string;
  treatment_id: string;
  duration_minutes: number;
  price: number;
  points: number | null;
  is_active: boolean;
  treatments: { name: string } | null;
}

function PointsRow({
  duration,
  onSaved,
}: {
  duration: DurationWithPoints;
  onSaved: () => void;
}) {
  const [editing, setEditing] = useState(false);
  const [points, setPoints] = useState(duration.points != null ? String(duration.points) : '');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function startEdit() {
    setPoints(duration.points != null ? String(duration.points) : '');
    setError(null);
    setEditing(true);
  }

  async function handleSave() {
    setSaving(true);
    setError(null);
    const result = await adminMutate(
      'treatment_durations',
      'update',
      { points: points === '' ? null : Number(points) },
      { id: duration.id }
    );
    setSaving(false);
    if (result.error) { setError(result.error); return; }
    setEditing(false);
    onSaved();
  }

  const CELL = 'px-5 py-3 text-sm';

  return (
    <>
      {error && (
        <tr>
          <td colSpan={5} className="px-5 py-1">
            <div className="flex items-start gap-2 px-3 py-2 rounded-lg border border-red-200 text-red-700 text-xs"
              style={{ backgroundColor: '#FEF2F2' }}>
              <AlertCircle className="w-3.5 h-3.5 mt-0.5 flex-shrink-0" />
              <span>{error}</span>
            </div>
          </td>
        </tr>
      )}
      <tr
        className="border-t transition-colors"
        style={{
          borderColor: '#EBE4D9',
          backgroundColor: editing ? '#F0F2E8' : undefined,
        }}
        onMouseEnter={(e) => {
          if (!editing) (e.currentTarget as HTMLTableRowElement).style.backgroundColor = '#FAF7F2';
        }}
        onMouseLeave={(e) => {
          if (!editing) (e.currentTarget as HTMLTableRowElement).style.backgroundColor = 'transparent';
        }}
      >
        <td className={CELL}>
          <span className="font-medium" style={{ color: '#2C2C2A' }}>
            {duration.treatments?.name ?? '—'}
          </span>
        </td>
        <td className={CELL} style={{ color: '#5A5A52' }}>
          {duration.duration_minutes} min
        </td>
        <td className={CELL} style={{ color: '#5A5A52' }}>
          {formatRupiah(duration.price)}
        </td>
        <td className={CELL}>
          {editing ? (
            <input
              type="number"
              min={0}
              value={points}
              onChange={(e) => setPoints(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') handleSave(); if (e.key === 'Escape') setEditing(false); }}
              autoFocus
              placeholder="0"
              className="w-24 px-2 py-1 rounded-md border text-sm focus:outline-none focus:ring-2 focus:ring-[#4E523B]"
              style={{ borderColor: '#4E523B', color: '#2C2C2A', backgroundColor: 'white' }}
            />
          ) : (
            <span className="font-semibold" style={{ color: duration.points != null ? '#4E523B' : '#9A9A90' }}>
              {duration.points != null ? duration.points.toLocaleString('id-ID') : '—'}
            </span>
          )}
        </td>
        <td className={CELL}>
          <div className="flex justify-end gap-1.5">
            {editing ? (
              <>
                <button
                  onClick={handleSave}
                  disabled={saving}
                  className="flex items-center gap-1 px-2.5 py-1 rounded-md text-xs font-medium text-white disabled:opacity-50 transition-colors"
                  style={{ backgroundColor: '#4E523B' }}
                  onMouseEnter={(e) => { if (!saving) (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#3D4130'; }}
                  onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#4E523B'; }}
                >
                  <Check className="w-3 h-3" />
                  {saving ? '…' : 'Save'}
                </button>
                <button
                  onClick={() => setEditing(false)}
                  className="flex items-center gap-1 px-2.5 py-1 rounded-md text-xs font-medium transition-colors"
                  style={{ backgroundColor: '#F0ECE5', color: '#5A5A52' }}
                  onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#EBE4D9'; }}
                  onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
                >
                  <X className="w-3 h-3" />
                  Cancel
                </button>
              </>
            ) : (
              <button
                onClick={startEdit}
                className="p-1.5 rounded-lg transition-colors"
                style={{ color: '#9A9A90' }}
                onMouseEnter={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = '#F0ECE5'; }}
                onMouseLeave={(e) => { (e.currentTarget as HTMLButtonElement).style.backgroundColor = 'transparent'; }}
                title="Edit points"
              >
                <Pencil className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
        </td>
      </tr>
    </>
  );
}

export default function PointsPage() {
  const [durations, setDurations] = useState<DurationWithPoints[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => { loadDurations(); }, []);

  async function loadDurations() {
    setLoading(true);
    const supabase = createClient();
    const { data } = await supabase
      .from('treatment_durations')
      .select('*, treatments(name)')
      .order('treatment_id');
    setDurations((data as DurationWithPoints[]) ?? []);
    setLoading(false);
  }

  // Group durations by treatment name for display
  const grouped = durations.reduce<Record<string, DurationWithPoints[]>>((acc, d) => {
    const name = d.treatments?.name ?? 'Unknown';
    if (!acc[name]) acc[name] = [];
    acc[name].push(d);
    return acc;
  }, {});

  const totalWithPoints = durations.filter((d) => d.points != null).length;

  return (
    <div className="space-y-5">
      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold" style={{ color: '#2C2C2A' }}>Point Settings</h1>
          <p className="text-sm mt-1" style={{ color: '#7A7A72' }}>
            Set how many points each treatment duration earns for customers.
          </p>
        </div>
        {!loading && (
          <div className="flex items-center gap-2 px-3 py-2 rounded-lg text-sm"
            style={{ backgroundColor: '#F0F2E8', color: '#4E523B' }}>
            <span className="font-semibold">{totalWithPoints}</span>
            <span style={{ color: '#7A7A72' }}>/ {durations.length} durations have points set</span>
          </div>
        )}
      </div>

      {loading ? (
        <div className="flex items-center justify-center h-40">
          <div className="w-7 h-7 rounded-full border-4 border-t-transparent animate-spin"
            style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }} />
        </div>
      ) : durations.length === 0 ? (
        <div className="bg-white rounded-xl border shadow-sm px-5 py-12 text-center text-sm"
          style={{ borderColor: '#EBE4D9', color: '#9A9A90' }}>
          No treatment durations found. Add durations in the Treatments page first.
        </div>
      ) : (
        <div className="bg-white rounded-xl border shadow-sm overflow-hidden" style={{ borderColor: '#EBE4D9' }}>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b" style={{ backgroundColor: '#FAF7F2', borderColor: '#EBE4D9' }}>
                  {['Treatment Name', 'Duration', 'Price', 'Points', ''].map((h) => (
                    <th key={h}
                      className="text-left px-5 py-3 text-xs font-semibold uppercase tracking-wide"
                      style={{ color: '#7A7A72' }}>
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {Object.entries(grouped).map(([treatmentName, rows]) => (
                  rows.map((d, idx) => (
                    <PointsRow
                      key={d.id}
                      duration={idx === 0 ? d : { ...d, treatments: null }}
                      onSaved={loadDurations}
                    />
                  ))
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <p className="text-xs" style={{ color: '#9A9A90' }}>
        Click the pencil icon on any row to edit its point value. Leave blank to award no points.
      </p>
    </div>
  );
}
