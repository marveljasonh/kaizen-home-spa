'use client';

import { useEffect, useState } from 'react';
import { CheckCircle, AlertCircle, Globe } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';

// ── Section / field definitions ───────────────────────────────────────────────
interface FieldDef {
  key: string;
  label: string;
  type: 'input' | 'textarea';
  placeholder?: string;
}

interface SectionDef {
  id: string;
  title: string;
  fields: FieldDef[];
}

const SECTIONS: SectionDef[] = [
  {
    id: 'hero',
    title: 'Hero Section',
    fields: [
      { key: 'hero_headline', label: 'Hero Headline',        type: 'input',    placeholder: 'e.g. Relax. Recharge. Renew.' },
      { key: 'hero_subtext',  label: 'Hero Subtext',         type: 'textarea', placeholder: 'Subtitle shown below the headline' },
      { key: 'hero_cta',      label: 'Hero Button Text',     type: 'input',    placeholder: 'e.g. Book Now' },
      { key: 'ticker_text',   label: 'Announcement Ticker',  type: 'input',    placeholder: 'e.g. Free delivery on orders above Rp 500.000' },
    ],
  },
  {
    id: 'why',
    title: 'Why Choose Us',
    fields: [
      { key: 'why_card1_title', label: 'Card 1 — Title',       type: 'input' },
      { key: 'why_card1_desc',  label: 'Card 1 — Description', type: 'textarea' },
      { key: 'why_card2_title', label: 'Card 2 — Title',       type: 'input' },
      { key: 'why_card2_desc',  label: 'Card 2 — Description', type: 'textarea' },
      { key: 'why_card3_title', label: 'Card 3 — Title',       type: 'input' },
      { key: 'why_card3_desc',  label: 'Card 3 — Description', type: 'textarea' },
      { key: 'why_card4_title', label: 'Card 4 — Title',       type: 'input' },
      { key: 'why_card4_desc',  label: 'Card 4 — Description', type: 'textarea' },
    ],
  },
  {
    id: 'footer',
    title: 'Footer',
    fields: [
      { key: 'footer_address', label: 'Address', type: 'textarea', placeholder: 'Full address' },
      { key: 'footer_phone',   label: 'Phone',   type: 'input',    placeholder: 'e.g. +62 812 3456 7890' },
      { key: 'footer_email',   label: 'Email',   type: 'input',    placeholder: 'e.g. hello@kaizenhomespa.com' },
    ],
  },
];

// ── Per-field save status ─────────────────────────────────────────────────────
type FieldStatus = 'idle' | 'saving' | 'saved' | 'error';

// ── ContentField component ────────────────────────────────────────────────────
function ContentField({
  field,
  value,
  onChange,
  onSave,
  status,
  errorMsg,
}: {
  field: FieldDef;
  value: string;
  onChange: (val: string) => void;
  onSave: () => void;
  status: FieldStatus;
  errorMsg?: string;
}) {
  const inputBase =
    'w-full px-3 py-2 rounded-lg border text-sm focus:outline-none focus:ring-2 focus:ring-[#4E523B] transition-colors';
  const inputStyle = { borderColor: '#EBE4D9', color: '#2C2C2A', backgroundColor: 'white' };

  return (
    <div className="grid grid-cols-1 sm:grid-cols-[200px_1fr] gap-3 items-start py-3.5 border-b last:border-0"
      style={{ borderColor: '#EBE4D9' }}>
      {/* Label */}
      <div className="pt-1.5">
        <p className="text-sm font-medium" style={{ color: '#3D3D38' }}>{field.label}</p>
        <p className="text-xs mt-0.5 font-mono" style={{ color: '#C5CAB0' }}>{field.key}</p>
      </div>

      {/* Input + status */}
      <div className="space-y-1.5">
        {field.type === 'textarea' ? (
          <textarea
            value={value}
            onChange={(e) => onChange(e.target.value)}
            onBlur={onSave}
            placeholder={field.placeholder}
            rows={3}
            className={inputBase}
            style={{ ...inputStyle, resize: 'vertical' as const }}
          />
        ) : (
          <input
            type="text"
            value={value}
            onChange={(e) => onChange(e.target.value)}
            onBlur={onSave}
            placeholder={field.placeholder}
            className={inputBase}
            style={inputStyle}
          />
        )}

        {/* Status indicator */}
        {status === 'saving' && (
          <div className="flex items-center gap-1.5 text-xs" style={{ color: '#7A7A72' }}>
            <div className="w-3 h-3 rounded-full border-2 animate-spin flex-shrink-0"
              style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }} />
            Saving…
          </div>
        )}
        {status === 'saved' && (
          <div className="flex items-center gap-1.5 text-xs" style={{ color: '#4E523B' }}>
            <CheckCircle className="w-3.5 h-3.5 flex-shrink-0" />
            Saved
          </div>
        )}
        {status === 'error' && (
          <div className="flex items-center gap-1.5 text-xs text-red-600">
            <AlertCircle className="w-3.5 h-3.5 flex-shrink-0" />
            {errorMsg ?? 'Save failed'}
          </div>
        )}
      </div>
    </div>
  );
}

// ── Main page ─────────────────────────────────────────────────────────────────
export default function WebsitePage() {
  const [values, setValues]     = useState<Record<string, string>>({});
  const [statuses, setStatuses] = useState<Record<string, FieldStatus>>({});
  const [errors, setErrors]     = useState<Record<string, string>>({});
  const [loading, setLoading]   = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);

  useEffect(() => { loadContent(); }, []);

  async function loadContent() {
    setLoading(true);
    setLoadError(null);
    const supabase = createClient();
    const { data, error } = await supabase.from('website_content').select('key, value');
    if (error) { setLoadError(error.message); setLoading(false); return; }
    const map: Record<string, string> = {};
    for (const row of (data ?? []) as { key: string; value: string | null }[]) {
      map[row.key] = row.value ?? '';
    }
    setValues(map);
    setLoading(false);
  }

  function setValue(key: string, val: string) {
    setValues((prev) => ({ ...prev, [key]: val }));
  }

  async function saveField(key: string) {
    const val = values[key] ?? '';
    setStatuses((prev) => ({ ...prev, [key]: 'saving' }));
    setErrors((prev) => { const n = { ...prev }; delete n[key]; return n; });

    const supabase = createClient();
    const { error } = await supabase
      .from('website_content')
      .upsert(
        { key, value: val, updated_at: new Date().toISOString() },
        { onConflict: 'key' }
      );

    if (error) {
      setStatuses((prev) => ({ ...prev, [key]: 'error' }));
      setErrors((prev) => ({ ...prev, [key]: error.message }));
      return;
    }

    setStatuses((prev) => ({ ...prev, [key]: 'saved' }));
    setTimeout(() => {
      setStatuses((prev) => (prev[key] === 'saved' ? { ...prev, [key]: 'idle' } : prev));
    }, 2000);
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <div className="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0"
          style={{ backgroundColor: '#E8EBE0' }}>
          <Globe className="w-5 h-5" style={{ color: '#4E523B' }} />
        </div>
        <div>
          <h1 className="text-2xl font-bold" style={{ color: '#2C2C2A' }}>Website Content</h1>
          <p className="text-sm" style={{ color: '#7A7A72' }}>
            Edit text that appears on the public-facing website. Changes save automatically on blur.
          </p>
        </div>
      </div>

      {/* Load error */}
      {loadError && (
        <div className="flex items-start gap-2 px-4 py-3 rounded-lg border border-red-200 text-red-700 text-sm"
          style={{ backgroundColor: '#FEF2F2' }}>
          <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
          <span>Failed to load content: {loadError}</span>
        </div>
      )}

      {/* Loading */}
      {loading && !loadError && (
        <div className="flex items-center justify-center h-48">
          <div className="w-7 h-7 rounded-full border-4 animate-spin"
            style={{ borderColor: '#4E523B', borderTopColor: 'transparent' }} />
        </div>
      )}

      {/* Sections */}
      {!loading && !loadError && SECTIONS.map((section) => (
        <div key={section.id} className="bg-white rounded-xl border shadow-sm overflow-hidden"
          style={{ borderColor: '#EBE4D9' }}>
          {/* Section header */}
          <div className="px-5 py-3 border-b" style={{ backgroundColor: '#FAF7F2', borderColor: '#EBE4D9' }}>
            <h2 className="text-xs font-semibold uppercase tracking-wider" style={{ color: '#4E523B' }}>
              {section.title}
            </h2>
          </div>

          {/* Fields */}
          <div className="px-5">
            {section.fields.map((field) => (
              <ContentField
                key={field.key}
                field={field}
                value={values[field.key] ?? ''}
                onChange={(val) => setValue(field.key, val)}
                onSave={() => saveField(field.key)}
                status={statuses[field.key] ?? 'idle'}
                errorMsg={errors[field.key]}
              />
            ))}
          </div>
        </div>
      ))}

      <p className="text-xs pb-4" style={{ color: '#9A9A90' }}>
        Fields save automatically when you click away. The key names match the <code>website_content</code> table.
      </p>
    </div>
  );
}
