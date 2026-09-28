"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Navbar } from "../components/Navbar";
import { supabase } from "@/lib/supabase";

// ─── Types ────────────────────────────────────────────────────────────────────

type TreatmentDuration = { minutes: number; price: number };
type Treatment = {
  id: string | number;
  name: string;
  description: string;
  image_url: string;
  category_name: string | null;
  durations: TreatmentDuration[];
};
type Addon = { id: string | number; name: string; description?: string | null; price: number };
type Therapist = {
  id: string | number;
  name: string;
  rating?: number | null;
  specialty?: string | null;
  avatar_url?: string | null;
};
type CartItem = {
  treatmentId: string | number;
  treatmentName: string;
  durationMinutes: number;
  price: number;
};
type SelectedAddon = { addonId: string | number; name: string; price: number };
type Cart = {
  items: CartItem[];
  addons: SelectedAddon[];
  therapistId: string | number | null;
  therapistName: string | null;
  scheduledTime: string | null;
  address: string;
  notes: string;
  promoCode: string;
  discountAmount: number;
  discountLabel: string;
};

// ─── Constants ────────────────────────────────────────────────────────────────

const STEP_LABELS = [
  "Treatment", "Add-ons", "Schedule", "Therapist",
  "Location", "Voucher", "Review", "Payment",
];

const TIME_SLOTS: string[] = [];
for (let h = 8; h <= 23; h++) {
  TIME_SLOTS.push(`${String(h).padStart(2, "0")}:00`);
  if (h < 23) TIME_SLOTS.push(`${String(h).padStart(2, "0")}:30`);
}

function fmt(n: number) {
  return `Rp ${n.toLocaleString("id-ID")}`;
}
function todayISO() {
  return new Date().toLocaleDateString("en-CA", { timeZone: "Asia/Jakarta" });
}
function todayLong() {
  return new Date().toLocaleDateString("id-ID", {
    timeZone: "Asia/Jakarta", weekday: "long", day: "numeric", month: "long", year: "numeric",
  });
}

// ─── Fallbacks ────────────────────────────────────────────────────────────────

const FB_TREATMENTS: Treatment[] = [
  { id: 1, name: "Swedish Massage", description: "Classic relaxation with long flowing strokes that ease tension and improve circulation.", image_url: "https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=400&q=80", category_name: "Massage", durations: [{ minutes: 60, price: 150000 }, { minutes: 90, price: 200000 }, { minutes: 120, price: 250000 }] },
  { id: 2, name: "Deep Tissue Massage", description: "Targets deeper muscle layers to release chronic tension and persistent knots.", image_url: "https://images.unsplash.com/photo-1519823551278-64ac92734fb1?w=400&q=80", category_name: "Massage", durations: [{ minutes: 60, price: 180000 }, { minutes: 90, price: 240000 }] },
  { id: 3, name: "Aromatherapy Spa", description: "Premium essential oils combined with a deeply soothing massage experience.", image_url: "https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=400&q=80", category_name: "Spa", durations: [{ minutes: 75, price: 180000 }, { minutes: 90, price: 220000 }] },
  { id: 4, name: "Hot Stone Massage", description: "Volcanic stones penetrate deep muscle tension while soothing warmth melts stress away.", image_url: "https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=400&q=80", category_name: "Spa", durations: [{ minutes: 90, price: 250000 }, { minutes: 120, price: 320000 }] },
  { id: 5, name: "Reflexology", description: "Targeted pressure on feet and hands stimulates healing throughout the whole body.", image_url: "https://images.unsplash.com/photo-1600334089648-b0d9d3028eb2?w=400&q=80", category_name: "Wellness", durations: [{ minutes: 45, price: 120000 }, { minutes: 60, price: 150000 }] },
  { id: 6, name: "Body Scrub & Wrap", description: "Exfoliating treatment followed by a nourishing wrap for silky smooth skin.", image_url: "https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=400&q=80", category_name: "Body", durations: [{ minutes: 80, price: 220000 }] },
];
const FB_ADDONS: Addon[] = [
  { id: 1, name: "Aromatherapy Oil Upgrade", description: "Premium essential oil blend of your choice", price: 50000 },
  { id: 2, name: "Hot Herbal Compress", description: "Warm herbal compress to enhance muscle relief", price: 35000 },
  { id: 3, name: "Scalp Massage", description: "15 min relaxing scalp & head massage add-on", price: 45000 },
  { id: 4, name: "Foot Scrub", description: "Exfoliating foot treatment before your session", price: 40000 },
  { id: 5, name: "Collagen Sheet Mask", description: "Nourishing face mask applied during treatment", price: 55000 },
];
const FB_THERAPISTS: Therapist[] = [
  { id: 1, name: "Sari Dewi", rating: 4.9, specialty: "Swedish & Aromatherapy" },
  { id: 2, name: "Budi Santoso", rating: 4.8, specialty: "Deep Tissue & Reflexology" },
  { id: 3, name: "Rina Putri", rating: 4.9, specialty: "Hot Stone & Body Wrap" },
  { id: 4, name: "Agus Widodo", rating: 4.7, specialty: "Sports & Deep Tissue" },
];

// ─── Reusable sub-components ─────────────────────────────────────────────────

function CheckIcon({ className = "w-3 h-3" }: { className?: string }) {
  return (
    <svg className={className} fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
    </svg>
  );
}

function StarIcon() {
  return (
    <svg className="w-3 h-3 text-spa-gold" fill="currentColor" viewBox="0 0 20 20">
      <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
    </svg>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function OrderPage() {
  const router = useRouter();

  const [userId, setUserId] = useState<string | null>(null);

  const [treatments, setTreatments] = useState<Treatment[]>([]);
  const [addons, setAddons] = useState<Addon[]>([]);
  const [therapists, setTherapists] = useState<Therapist[]>([]);
  const [unavailableSlots, setUnavailableSlots] = useState<string[]>([]);
  const [dataLoading, setDataLoading] = useState(true);

  const [step, setStep] = useState(1);
  const [catFilter, setCatFilter] = useState("all");

  const [cart, setCart] = useState<Cart>({
    items: [], addons: [], therapistId: null, therapistName: null,
    scheduledTime: null, address: "", notes: "",
    promoCode: "", discountAmount: 0, discountLabel: "",
  });

  const [promoStatus, setPromoStatus] = useState<"idle" | "checking" | "ok" | "invalid">("idle");
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  // ── Init: data loads immediately; auth check runs in parallel ────────────

  useEffect(() => {
    // Auth check — doesn't block page render
    supabase.auth.getUser().then(({ data: { user } }) => {
      if (!user) return;
      setUserId(user.id);
      // Restore cart saved before login redirect
      try {
        const pending = sessionStorage.getItem("pendingCart");
        if (pending) {
          setCart(JSON.parse(pending));
          sessionStorage.removeItem("pendingCart");
          setStep(7); // jump to Review
        }
      } catch {}
    });
    // Data loads without waiting for auth
    loadData();
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  async function loadData() {
    setDataLoading(true);
    try {
      // Treatments
      const { data: tData, error: tErr } = await supabase.from("treatments").select("*, categories(name)");
      const { data: durData } = await supabase.from("treatment_durations").select("*");
      if (!tErr && tData?.length) {
        setTreatments(tData.map(t => {
          const durs = (durData || []).filter(d => String(d.treatment_id) === String(t.id));
          return {
            id: t.id,
            name: t.name || "Treatment",
            description: t.description || "",
            image_url: t.image_url || t.image || FB_TREATMENTS[0].image_url,
            category_name: t.categories?.name || t.category || null,
            durations: durs.length
              ? durs.map(d => ({ minutes: d.duration_minutes || 60, price: d.price }))
              : [{ minutes: 60, price: t.starting_price || t.price || 150000 }],
          };
        }));
      } else {
        setTreatments(FB_TREATMENTS);
      }

      // Add-ons
      const { data: aData, error: aErr } = await supabase.from("addons").select("id, name, description, price").order("price");
      setAddons(!aErr && aData?.length ? aData : FB_ADDONS);

      // Therapists
      const { data: thData, error: thErr } = await supabase
        .from("therapist_profiles").select("id, name, full_name, rating, specialty, avatar_url").eq("status", "available");
      const resolvedTherapists = (!thErr && thData?.length)
        ? thData.map(t => ({ id: t.id, name: t.name || t.full_name || "Therapist", rating: t.rating, specialty: t.specialty, avatar_url: t.avatar_url }))
        : FB_THERAPISTS;
      setTherapists(resolvedTherapists);

      // Today's unavailable slots
      const { data: bkData } = await supabase.from("bookings").select("time").eq("date", todayISO()).neq("status", "cancelled");
      if (bkData) {
        const counts: Record<string, number> = {};
        bkData.forEach(b => { if (b.time) counts[b.time] = (counts[b.time] || 0) + 1; });
        setUnavailableSlots(Object.entries(counts).filter(([, c]) => c >= resolvedTherapists.length).map(([t]) => t));
      }
    } catch {
      setTreatments(FB_TREATMENTS);
      setAddons(FB_ADDONS);
      setTherapists(FB_THERAPISTS);
    }
    setDataLoading(false);
  }

  // ── Cart helpers ──────────────────────────────────────────────────────────

  function toggleDuration(t: Treatment, dur: TreatmentDuration) {
    setCart(prev => {
      const existing = prev.items.find(i => String(i.treatmentId) === String(t.id));
      if (existing?.durationMinutes === dur.minutes) {
        return { ...prev, items: prev.items.filter(i => String(i.treatmentId) !== String(t.id)) };
      }
      const rest = prev.items.filter(i => String(i.treatmentId) !== String(t.id));
      return { ...prev, items: [...rest, { treatmentId: t.id, treatmentName: t.name, durationMinutes: dur.minutes, price: dur.price }] };
    });
  }

  function toggleAddon(a: Addon) {
    setCart(prev => {
      const exists = prev.addons.some(x => String(x.addonId) === String(a.id));
      return exists
        ? { ...prev, addons: prev.addons.filter(x => String(x.addonId) !== String(a.id)) }
        : { ...prev, addons: [...prev.addons, { addonId: a.id, name: a.name, price: a.price }] };
    });
  }

  // ── Totals ────────────────────────────────────────────────────────────────

  const treatmentsTotal = cart.items.reduce((s, i) => s + i.price, 0);
  const addonsTotal = cart.addons.reduce((s, a) => s + a.price, 0);
  const subtotal = treatmentsTotal + addonsTotal;
  const total = Math.max(0, subtotal - cart.discountAmount);

  // ── Promo ─────────────────────────────────────────────────────────────────

  async function applyPromo() {
    const code = cart.promoCode.trim().toUpperCase();
    if (!code) return;
    setPromoStatus("checking");
    try {
      const { data } = await supabase.from("vouchers").select("*").eq("code", code).maybeSingle();
      if (!data) { setPromoStatus("invalid"); return; }
      const discount = data.discount_type === "percent"
        ? Math.floor(subtotal * data.discount_value / 100)
        : data.discount_value;
      setCart(prev => ({ ...prev, discountAmount: discount, discountLabel: `${data.code} (${data.discount_type === "percent" ? `${data.discount_value}%` : fmt(data.discount_value)} off)` }));
      setPromoStatus("ok");
    } catch {
      setPromoStatus("invalid");
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  async function confirmOrder() {
    setSubmitting(true);
    try {
      await supabase.from("bookings").insert({
        user_id: userId,
        treatment_id: cart.items[0]?.treatmentId ?? null,
        treatment_name: cart.items.map(i => `${i.treatmentName} (${i.durationMinutes}min)`).join(", "),
        addons: cart.addons.map(a => a.name).join(", ") || null,
        therapist_id: cart.therapistId,
        date: todayISO(),
        time: cart.scheduledTime,
        address: cart.address,
        notes: cart.notes || null,
        price: subtotal,
        discount: cart.discountAmount || null,
        voucher_code: cart.promoCode || null,
        total,
        status: "pending",
        payment_method: "cash",
      });
      setSubmitted(true);
    } catch { /* allow even if Supabase schema differs */ }
    setSubmitting(false);
  }

  // ── Validation ────────────────────────────────────────────────────────────

  function canProceed() {
    if (step === 1) return cart.items.length > 0;
    if (step === 3) return cart.scheduledTime !== null;
    if (step === 4) return cart.therapistId !== null;
    if (step === 5) return cart.address.trim().length > 4;
    return true;
  }

  function handleContinue() {
    if (!canProceed()) return;
    const next = step + 1;
    // Auth wall: require login before reaching Review (step 7)
    if (next >= 7 && !userId) {
      sessionStorage.setItem("pendingCart", JSON.stringify(cart));
      router.push("/login?redirect=/order");
      return;
    }
    setStep(next);
  }

  const categories = ["all", ...Array.from(new Set(treatments.map(t => t.category_name).filter((c): c is string => c !== null)))];
  const filteredTreatments = catFilter === "all" ? treatments : treatments.filter(t => t.category_name === catFilter);

  // ── Render: loading ───────────────────────────────────────────────────────

  if (dataLoading) {
    return (
      <div className="min-h-screen bg-spa-dark flex items-center justify-center">
        <div className="text-center">
          <div className="w-10 h-10 rounded-full border-2 border-spa-gold/30 border-t-spa-gold animate-spin mx-auto mb-4" />
          <p className="text-spa-cream/40 text-sm">Preparing your session…</p>
        </div>
      </div>
    );
  }

  // ── Render: success ───────────────────────────────────────────────────────

  if (submitted) {
    return (
      <div className="min-h-screen bg-spa-dark flex items-center justify-center px-5">
        <div className="text-center max-w-md">
          <div className="w-16 h-16 rounded-full bg-spa-gold/15 flex items-center justify-center mx-auto mb-6">
            <CheckIcon className="w-8 h-8 text-spa-gold" />
          </div>
          <h2 className="font-display text-3xl font-bold text-spa-cream mb-3">Order Confirmed!</h2>
          <p className="text-spa-cream/60 text-sm mb-1">{cart.items.map(i => i.treatmentName).join(" + ")}</p>
          <p className="text-spa-cream/35 text-xs mb-8">
            Today at {cart.scheduledTime} · {cart.therapistName} · {fmt(total)}
          </p>
          <p className="text-spa-cream/40 text-xs mb-8 leading-relaxed">
            Our therapist will contact you via WhatsApp to confirm your appointment details.
          </p>
          <div className="flex gap-3 justify-center">
            <Link href="/dashboard" className="px-7 py-3 rounded-full btn-olive border border-spa-gold/25 text-sm font-medium">
              View Bookings
            </Link>
            <Link href="/" className="px-7 py-3 rounded-full border border-white/15 text-spa-cream/70 text-sm hover:border-white/30 transition-colors">
              Back to Home
            </Link>
          </div>
        </div>
      </div>
    );
  }

  // ── Render: main ──────────────────────────────────────────────────────────

  const inputCls = "w-full px-4 py-3 rounded-xl bg-white/5 border border-white/10 text-spa-cream placeholder-spa-cream/25 text-sm focus:outline-none focus:border-spa-gold/40 transition-all";

  return (
    <>
      <Navbar />
      <main className="min-h-screen bg-spa-dark pt-24 pb-20 px-5">
        <div className="max-w-3xl mx-auto">

          {/* Header */}
          <div className="text-center mb-8">
            <p className="section-label mb-2">Book a Session</p>
            <h1 className="font-display text-3xl md:text-4xl font-bold text-spa-cream">
              Reserve Your <span className="gold-text italic">Treatment</span>
            </h1>
          </div>

          {/* Progress — mobile bar */}
          <div className="sm:hidden mb-8">
            <div className="flex items-center justify-between mb-2">
              <span className="text-spa-cream/40 text-xs">Step {step} of {STEP_LABELS.length}</span>
              <span className="text-spa-gold text-xs font-medium">{STEP_LABELS[step - 1]}</span>
            </div>
            <div className="h-1 bg-white/8 rounded-full overflow-hidden">
              <div className="h-full bg-spa-gold rounded-full transition-all duration-500" style={{ width: `${(step / STEP_LABELS.length) * 100}%` }} />
            </div>
          </div>

          {/* Progress — desktop circles */}
          <div className="hidden sm:flex items-center mb-10">
            {STEP_LABELS.map((label, idx) => {
              const s = idx + 1;
              const done = step > s;
              const active = step === s;
              return (
                <div key={s} className={`flex items-center ${idx < STEP_LABELS.length - 1 ? "flex-1" : ""}`}>
                  <div className="flex flex-col items-center gap-1 shrink-0">
                    <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-semibold transition-all duration-300 ${done ? "bg-spa-gold text-spa-dark" : active ? "bg-spa-gold text-spa-dark ring-2 ring-spa-gold/30 ring-offset-2 ring-offset-spa-dark" : "bg-white/10 text-spa-cream/35"}`}>
                      {done ? <CheckIcon className="w-3.5 h-3.5" /> : s}
                    </div>
                    <span className={`text-[9px] font-medium tracking-wide uppercase whitespace-nowrap transition-colors ${active ? "text-spa-gold" : done ? "text-spa-cream/40" : "text-spa-cream/20"}`}>
                      {label}
                    </span>
                  </div>
                  {idx < STEP_LABELS.length - 1 && (
                    <div className={`flex-1 h-px mx-2 mb-4 transition-all duration-300 ${done ? "bg-spa-gold/40" : "bg-white/8"}`} />
                  )}
                </div>
              );
            })}
          </div>

          {/* ── Step panels ───────────────────────────────────────────────── */}
          <div className="glass-card rounded-2xl p-6 md:p-8 mb-6">

            {/* ── Step 1: Treatments ──────────────────────────────────────── */}
            {step === 1 && (
              <div>
                <h2 className="font-display text-2xl font-bold text-spa-cream mb-1">Select Treatment</h2>
                <p className="text-spa-cream/40 text-sm mb-5">Pick one or more treatments and your preferred duration</p>

                {/* Category filter */}
                <div className="flex flex-wrap gap-2 mb-6">
                  {categories.map(cat => (
                    <button key={cat} onClick={() => setCatFilter(cat)}
                      className={`px-4 py-1.5 rounded-full text-xs font-medium transition-all duration-200 ${catFilter === cat ? "bg-spa-gold text-spa-dark" : "bg-white/8 text-spa-cream/60 hover:bg-white/15"}`}>
                      {cat === "all" ? "All" : cat}
                    </button>
                  ))}
                </div>

                {/* Treatment cards */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {filteredTreatments.map(t => {
                    const sel = cart.items.find(i => String(i.treatmentId) === String(t.id));
                    return (
                      <div key={t.id} className={`rounded-xl border overflow-hidden transition-all duration-200 ${sel ? "border-spa-gold/50" : "border-white/8 hover:border-white/18"}`}>
                        <div className="relative h-36 overflow-hidden">
                          <img src={t.image_url} alt={t.name} className="w-full h-full object-cover" />
                          <div className="absolute inset-0 bg-gradient-to-t from-[#1C1C1A] via-[#1C1C1A]/20 to-transparent" />
                          {t.category_name && (
                            <span className="absolute top-3 left-3 px-2 py-0.5 rounded-full bg-spa-dark/70 border border-white/10 text-spa-gold/80 text-[10px]">
                              {t.category_name}
                            </span>
                          )}
                          {sel && (
                            <div className="absolute top-3 right-3 w-5 h-5 rounded-full bg-spa-gold flex items-center justify-center">
                              <CheckIcon className="w-3 h-3 text-spa-dark" />
                            </div>
                          )}
                        </div>
                        <div className="p-4">
                          <p className="text-spa-cream text-sm font-semibold mb-1">{t.name}</p>
                          <p className="text-spa-cream/40 text-xs leading-relaxed mb-3">{t.description}</p>
                          <div className="flex flex-wrap gap-2">
                            {t.durations.map(dur => {
                              const active = sel?.durationMinutes === dur.minutes;
                              return (
                                <button key={dur.minutes} onClick={() => toggleDuration(t, dur)}
                                  className={`px-3 py-1.5 rounded-lg text-xs font-medium border transition-all duration-200 ${active ? "bg-spa-gold border-spa-gold text-spa-dark" : "bg-white/5 border-white/10 text-spa-cream/55 hover:border-spa-gold/40 hover:text-spa-cream"}`}>
                                  {dur.minutes} min · {fmt(dur.price)}
                                </button>
                              );
                            })}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>

                {cart.items.length > 0 && (
                  <div className="mt-5 p-4 rounded-xl bg-spa-gold/8 border border-spa-gold/20 flex items-center justify-between">
                    <div>
                      <p className="text-spa-gold text-xs font-medium mb-0.5">Cart · {cart.items.length} item{cart.items.length > 1 ? "s" : ""}</p>
                      <p className="text-spa-cream/50 text-xs">{cart.items.map(i => `${i.treatmentName} ${i.durationMinutes}min`).join(", ")}</p>
                    </div>
                    <p className="text-spa-gold font-semibold text-sm shrink-0 ml-4">{fmt(treatmentsTotal)}</p>
                  </div>
                )}
              </div>
            )}

            {/* ── Step 2: Add-ons ─────────────────────────────────────────── */}
            {step === 2 && (
              <div>
                <h2 className="font-display text-2xl font-bold text-spa-cream mb-1">Add-ons</h2>
                <p className="text-spa-cream/40 text-sm mb-6">Enhance your experience with optional extras</p>
                <div className="space-y-3">
                  {addons.map(a => {
                    const sel = cart.addons.some(x => String(x.addonId) === String(a.id));
                    return (
                      <button key={a.id} onClick={() => toggleAddon(a)}
                        className={`w-full flex items-center gap-4 p-4 rounded-xl border text-left transition-all duration-200 ${sel ? "border-spa-gold/50 bg-spa-gold/5" : "border-white/8 hover:border-white/20"}`}>
                        <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center shrink-0 transition-all ${sel ? "border-spa-gold bg-spa-gold" : "border-white/30"}`}>
                          {sel && <CheckIcon className="w-3 h-3 text-spa-dark" />}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-spa-cream text-sm font-medium">{a.name}</p>
                          {a.description && <p className="text-spa-cream/40 text-xs mt-0.5">{a.description}</p>}
                        </div>
                        <p className={`text-sm font-semibold shrink-0 ${sel ? "text-spa-gold" : "text-spa-cream/50"}`}>+{fmt(a.price)}</p>
                      </button>
                    );
                  })}
                </div>
                {cart.addons.length > 0 && (
                  <div className="mt-5 p-4 rounded-xl bg-spa-gold/8 border border-spa-gold/20 flex justify-between">
                    <p className="text-spa-cream/50 text-xs">{cart.addons.length} add-on{cart.addons.length > 1 ? "s" : ""} selected</p>
                    <p className="text-spa-gold text-sm font-semibold">+{fmt(addonsTotal)}</p>
                  </div>
                )}
              </div>
            )}

            {/* ── Step 3: Schedule ────────────────────────────────────────── */}
            {step === 3 && (
              <div>
                <h2 className="font-display text-2xl font-bold text-spa-cream mb-1">Select Time</h2>
                <div className="flex items-center gap-2 mb-6">
                  <div className="w-2 h-2 rounded-full bg-spa-gold animate-pulse" />
                  <p className="text-spa-gold/80 text-sm">Today · {todayLong()}</p>
                </div>
                <div className="grid grid-cols-4 sm:grid-cols-6 gap-2">
                  {TIME_SLOTS.map(slot => {
                    const full = unavailableSlots.includes(slot);
                    const sel = cart.scheduledTime === slot;
                    return (
                      <button key={slot} disabled={full}
                        onClick={() => setCart(prev => ({ ...prev, scheduledTime: slot }))}
                        className={`py-2.5 rounded-xl text-xs font-medium border transition-all duration-200 ${
                          full ? "border-white/5 text-spa-cream/15 cursor-not-allowed line-through"
                          : sel ? "border-spa-gold bg-spa-gold/10 text-spa-gold"
                          : "border-white/10 text-spa-cream/55 hover:border-white/25 hover:text-spa-cream"
                        }`}>
                        {slot}
                      </button>
                    );
                  })}
                </div>
                {unavailableSlots.length > 0 && (
                  <p className="text-spa-cream/25 text-xs mt-4">Crossed-out slots are fully booked for today.</p>
                )}
              </div>
            )}

            {/* ── Step 4: Therapist ───────────────────────────────────────── */}
            {step === 4 && (
              <div>
                <h2 className="font-display text-2xl font-bold text-spa-cream mb-1">Choose Therapist</h2>
                <p className="text-spa-cream/40 text-sm mb-6">All therapists below are certified and available at {cart.scheduledTime}</p>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {therapists.map(t => {
                    const sel = String(cart.therapistId) === String(t.id);
                    return (
                      <button key={t.id}
                        onClick={() => setCart(prev => ({ ...prev, therapistId: t.id, therapistName: t.name }))}
                        className={`flex items-center gap-4 p-4 rounded-xl border text-left transition-all duration-200 ${sel ? "border-spa-gold/50 bg-spa-gold/5" : "border-white/8 hover:border-white/20"}`}>
                        <div className={`w-12 h-12 rounded-full overflow-hidden shrink-0 flex items-center justify-center font-display font-bold text-lg border-2 transition-all bg-spa-olive/30 ${sel ? "border-spa-gold" : "border-white/10"}`}>
                          {t.avatar_url
                            ? <img src={t.avatar_url} alt={t.name} className="w-full h-full object-cover" />
                            : <span className="text-spa-gold/70">{t.name.charAt(0)}</span>}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-spa-cream text-sm font-semibold">{t.name}</p>
                          {t.specialty && <p className="text-spa-cream/40 text-xs mt-0.5 truncate">{t.specialty}</p>}
                          {t.rating && (
                            <div className="flex items-center gap-1 mt-1">
                              <StarIcon /><span className="text-spa-cream/50 text-xs">{t.rating.toFixed(1)}</span>
                            </div>
                          )}
                        </div>
                        {sel && <div className="w-5 h-5 rounded-full bg-spa-gold flex items-center justify-center shrink-0"><CheckIcon className="w-3 h-3 text-spa-dark" /></div>}
                      </button>
                    );
                  })}
                </div>
              </div>
            )}

            {/* ── Step 5: Location ────────────────────────────────────────── */}
            {step === 5 && (
              <div>
                <h2 className="font-display text-2xl font-bold text-spa-cream mb-1">Your Location</h2>
                <p className="text-spa-cream/40 text-sm mb-5">Enter your address for the home service</p>
                <div className="rounded-xl overflow-hidden mb-5 border border-white/8">
                  <iframe
                    src="https://maps.google.com/maps?q=Bandung,+West+Java,+Indonesia&output=embed&z=12"
                    className="w-full h-44" loading="lazy" title="Service area"
                  />
                </div>
                <div className="space-y-4">
                  <div>
                    <label className="block text-spa-cream/50 text-xs uppercase tracking-wider mb-2">Full Address <span className="text-spa-gold">*</span></label>
                    <textarea value={cart.address} rows={3} placeholder="Street name, house number, district, city…"
                      onChange={e => setCart(prev => ({ ...prev, address: e.target.value }))}
                      className={`${inputCls} resize-none`} />
                  </div>
                  <div>
                    <label className="block text-spa-cream/50 text-xs uppercase tracking-wider mb-2">Additional Notes</label>
                    <input type="text" value={cart.notes} placeholder="Gate code, landmark, floor number…"
                      onChange={e => setCart(prev => ({ ...prev, notes: e.target.value }))}
                      className={inputCls} />
                  </div>
                </div>
              </div>
            )}

            {/* ── Step 6: Voucher ─────────────────────────────────────────── */}
            {step === 6 && (
              <div>
                <h2 className="font-display text-2xl font-bold text-spa-cream mb-1">Voucher &amp; Discounts</h2>
                <p className="text-spa-cream/40 text-sm mb-6">Apply a promo code to save on your order</p>

                <div className="mb-7">
                  <label className="block text-spa-cream/50 text-xs uppercase tracking-wider mb-2">Promo Code</label>
                  <div className="flex gap-3">
                    <input type="text" value={cart.promoCode} placeholder="e.g. KAIZEN10"
                      onChange={e => { setCart(prev => ({ ...prev, promoCode: e.target.value, discountAmount: 0, discountLabel: "" })); setPromoStatus("idle"); }}
                      className={`${inputCls} flex-1 uppercase`} />
                    <button onClick={applyPromo} disabled={!cart.promoCode || promoStatus === "checking"}
                      className="px-5 rounded-xl bg-spa-olive/60 border border-spa-gold/20 text-spa-cream text-sm font-medium hover:bg-spa-olive transition-all disabled:opacity-40">
                      {promoStatus === "checking" ? "…" : "Apply"}
                    </button>
                  </div>
                  {promoStatus === "ok" && <p className="text-green-400 text-xs mt-2">✓ {cart.discountLabel}</p>}
                  {promoStatus === "invalid" && <p className="text-red-400/80 text-xs mt-2">Invalid or expired promo code.</p>}
                </div>

                {/* Running total */}
                <div className="p-5 rounded-xl bg-white/3 border border-white/6 space-y-2">
                  <p className="text-spa-cream/35 text-xs uppercase tracking-wider mb-3">Order Total</p>
                  {cart.items.map(i => (
                    <div key={`${i.treatmentId}-${i.durationMinutes}`} className="flex justify-between text-sm">
                      <span className="text-spa-cream/55">{i.treatmentName} · {i.durationMinutes}min</span>
                      <span className="text-spa-cream/70">{fmt(i.price)}</span>
                    </div>
                  ))}
                  {cart.addons.map(a => (
                    <div key={String(a.addonId)} className="flex justify-between text-sm">
                      <span className="text-spa-cream/55">{a.name}</span>
                      <span className="text-spa-cream/70">+{fmt(a.price)}</span>
                    </div>
                  ))}
                  {cart.discountAmount > 0 && (
                    <div className="flex justify-between text-sm pt-1">
                      <span className="text-green-400/80">Discount</span>
                      <span className="text-green-400">−{fmt(cart.discountAmount)}</span>
                    </div>
                  )}
                  <div className="border-t border-white/8 pt-2 flex justify-between">
                    <span className="text-spa-cream/60 text-sm font-medium">Total</span>
                    <span className="text-spa-gold font-bold">{fmt(total)}</span>
                  </div>
                </div>
              </div>
            )}

            {/* ── Step 7 / 8 login wall (fallback if userId lost) ─────────── */}
            {(step === 7 || step === 8) && !userId && (
              <div className="text-center py-16">
                <div className="w-14 h-14 rounded-full bg-spa-gold/15 flex items-center justify-center mx-auto mb-5">
                  <svg className="w-6 h-6 text-spa-gold" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                  </svg>
                </div>
                <h3 className="font-display text-xl font-semibold text-spa-cream mb-2">
                  Login to Complete Your Booking
                </h3>
                <p className="text-spa-cream/45 text-sm mb-7 max-w-xs mx-auto leading-relaxed">
                  Your cart is saved. Sign in or create an account to review and confirm your order.
                </p>
                <button
                  onClick={() => { sessionStorage.setItem("pendingCart", JSON.stringify(cart)); router.push("/login?redirect=/order"); }}
                  className="px-8 py-3 rounded-full btn-gold text-sm font-semibold"
                >
                  Sign In
                </button>
                <div className="mt-4">
                  <button onClick={() => setStep(6)} className="text-spa-cream/35 text-xs hover:text-spa-cream/60 transition-colors underline underline-offset-4">
                    Go back
                  </button>
                </div>
              </div>
            )}

            {/* ── Step 7: Review ──────────────────────────────────────────── */}
            {step === 7 && userId && (
              <div>
                <h2 className="font-display text-2xl font-bold text-spa-cream mb-6">Review Order</h2>
                <div className="space-y-4">

                  <div className="p-4 rounded-xl bg-white/3 border border-white/6">
                    <p className="text-spa-cream/35 text-xs uppercase tracking-wider mb-3">Treatments</p>
                    {cart.items.map(i => (
                      <div key={`${i.treatmentId}-${i.durationMinutes}`} className="flex justify-between items-center py-1.5">
                        <div><p className="text-spa-cream text-sm">{i.treatmentName}</p><p className="text-spa-cream/35 text-xs">{i.durationMinutes} minutes</p></div>
                        <p className="text-spa-cream/70 text-sm">{fmt(i.price)}</p>
                      </div>
                    ))}
                  </div>

                  {cart.addons.length > 0 && (
                    <div className="p-4 rounded-xl bg-white/3 border border-white/6">
                      <p className="text-spa-cream/35 text-xs uppercase tracking-wider mb-3">Add-ons</p>
                      {cart.addons.map(a => (
                        <div key={String(a.addonId)} className="flex justify-between text-sm py-1">
                          <span className="text-spa-cream/70">{a.name}</span>
                          <span className="text-spa-cream/60">+{fmt(a.price)}</span>
                        </div>
                      ))}
                    </div>
                  )}

                  <div className="p-4 rounded-xl bg-white/3 border border-white/6 space-y-3">
                    {[
                      { label: "Date", value: todayLong() },
                      { label: "Time", value: cart.scheduledTime || "—" },
                      { label: "Therapist", value: cart.therapistName || "—" },
                      { label: "Location", value: cart.address || "—" },
                      ...(cart.notes ? [{ label: "Notes", value: cart.notes }] : []),
                    ].map(row => (
                      <div key={row.label} className="flex justify-between items-start gap-4">
                        <span className="text-spa-cream/40 text-sm shrink-0 w-20">{row.label}</span>
                        <span className="text-spa-cream text-sm text-right">{row.value}</span>
                      </div>
                    ))}
                  </div>

                  <div className="p-4 rounded-xl bg-spa-gold/8 border border-spa-gold/20">
                    {cart.discountAmount > 0 && <>
                      <div className="flex justify-between text-sm mb-1"><span className="text-spa-cream/40">Subtotal</span><span className="text-spa-cream/60">{fmt(subtotal)}</span></div>
                      <div className="flex justify-between text-sm mb-2"><span className="text-green-400/80">{cart.discountLabel}</span><span className="text-green-400">−{fmt(cart.discountAmount)}</span></div>
                    </>}
                    <div className="flex justify-between items-center">
                      <span className="text-spa-cream text-sm font-medium">Total</span>
                      <span className="text-spa-gold font-display text-2xl font-bold">{fmt(total)}</span>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* ── Step 8: Payment ─────────────────────────────────────────── */}
            {step === 8 && userId && (
              <div>
                <h2 className="font-display text-2xl font-bold text-spa-cream mb-1">Payment</h2>
                <p className="text-spa-cream/40 text-sm mb-6">Select your preferred payment method</p>

                <div className="space-y-3 mb-7">
                  {/* Active: Cash */}
                  <div className="flex items-center gap-4 p-4 rounded-xl border border-spa-gold/40 bg-spa-gold/5">
                    <div className="w-10 h-10 rounded-xl bg-spa-gold/15 flex items-center justify-center shrink-0">
                      <svg className="w-5 h-5 text-spa-gold" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
                      </svg>
                    </div>
                    <div className="flex-1">
                      <p className="text-spa-cream text-sm font-medium">Cash on Delivery</p>
                      <p className="text-spa-cream/40 text-xs mt-0.5">Pay directly to your therapist on arrival</p>
                    </div>
                    <div className="w-5 h-5 rounded-full border-2 border-spa-gold bg-spa-gold flex items-center justify-center shrink-0">
                      <div className="w-2 h-2 rounded-full bg-spa-dark" />
                    </div>
                  </div>
                  {/* Coming soon */}
                  {["Bank Transfer", "QRIS / E-Wallet"].map(m => (
                    <div key={m} className="flex items-center gap-4 p-4 rounded-xl border border-white/6 opacity-35 cursor-not-allowed">
                      <div className="w-10 h-10 rounded-xl bg-white/5 flex items-center justify-center shrink-0">
                        <svg className="w-5 h-5 text-spa-cream/30" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
                        </svg>
                      </div>
                      <div className="flex-1"><p className="text-spa-cream/40 text-sm">{m}</p><p className="text-spa-cream/25 text-xs mt-0.5">Coming soon</p></div>
                    </div>
                  ))}
                </div>

                {/* Mini order summary */}
                <div className="p-5 rounded-xl bg-white/3 border border-white/6">
                  <p className="text-spa-cream/35 text-xs uppercase tracking-wider mb-3">Order Summary</p>
                  {cart.items.map(i => (
                    <div key={`${i.treatmentId}-${i.durationMinutes}`} className="flex justify-between text-sm mb-1">
                      <span className="text-spa-cream/55">{i.treatmentName} · {i.durationMinutes}min</span>
                      <span className="text-spa-cream/65">{fmt(i.price)}</span>
                    </div>
                  ))}
                  {cart.addons.map(a => (
                    <div key={String(a.addonId)} className="flex justify-between text-sm mb-1">
                      <span className="text-spa-cream/55">{a.name}</span>
                      <span className="text-spa-cream/65">+{fmt(a.price)}</span>
                    </div>
                  ))}
                  {cart.discountAmount > 0 && (
                    <div className="flex justify-between text-sm mb-1">
                      <span className="text-green-400/70">Discount</span>
                      <span className="text-green-400/80">−{fmt(cart.discountAmount)}</span>
                    </div>
                  )}
                  <div className="border-t border-white/8 mt-2 pt-3 flex justify-between items-center">
                    <span className="text-spa-cream text-sm font-medium">Total Due (Cash)</span>
                    <span className="text-spa-gold font-bold text-lg">{fmt(total)}</span>
                  </div>
                  <p className="text-spa-cream/25 text-xs mt-3">Today at {cart.scheduledTime} · {cart.therapistName}</p>
                </div>
              </div>
            )}
          </div>

          {/* ── Nav buttons ──────────────────────────────────────────────── */}
          <div className="flex items-center justify-between">
            {step > 1 ? (
              <button onClick={() => setStep(s => s - 1)}
                className="flex items-center gap-2 px-5 py-2.5 rounded-full border border-white/15 text-spa-cream/60 text-sm hover:border-white/30 hover:text-spa-cream transition-all">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                </svg>
                Back
              </button>
            ) : <div />}

            {step < STEP_LABELS.length ? (
              <button onClick={handleContinue} disabled={!canProceed()}
                className="flex items-center gap-2 px-7 py-2.5 rounded-full btn-olive border border-spa-gold/25 text-sm font-medium disabled:opacity-35 disabled:cursor-not-allowed">
                Continue
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </button>
            ) : (
              <button onClick={confirmOrder} disabled={submitting}
                className="flex items-center gap-2 px-7 py-2.5 rounded-full btn-gold text-sm font-semibold disabled:opacity-50 disabled:cursor-not-allowed">
                {submitting ? (
                  <><svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" /><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" /></svg>Placing Order…</>
                ) : "Confirm Order"}
              </button>
            )}
          </div>
        </div>
      </main>
    </>
  );
}
