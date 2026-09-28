import { Navbar } from "../components/Navbar";
import { Footer } from "../components/Footer";
import { ServicesClient } from "../components/ServicesClient";
import type { Category, Treatment } from "../components/ServicesClient";
import { supabase } from "@/lib/supabase";

// ─── Fallback data (shown when Supabase tables are empty/unavailable) ──────────

const fallbackCategories: Category[] = [
  { id: "massage", name: "Massage" },
  { id: "spa", name: "Spa" },
  { id: "wellness", name: "Wellness" },
  { id: "body", name: "Body" },
];

const fallbackTreatments: Treatment[] = [
  {
    id: 1,
    name: "Swedish Massage",
    description:
      "The classic full-body relaxation massage using long, flowing strokes that ease tension, improve circulation, and leave you feeling completely renewed.",
    starting_price: 150000,
    image_url: "https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=600&q=80",
    duration: 60,
    category_id: "massage",
    category_name: "Massage",
  },
  {
    id: 2,
    name: "Deep Tissue Massage",
    description:
      "Targeting the deeper layers of muscle tissue to release chronic tension, knots, and tightness — ideal for active lifestyles and persistent aches.",
    starting_price: 200000,
    image_url: "https://images.unsplash.com/photo-1519823551278-64ac92734fb1?w=600&q=80",
    duration: 90,
    category_id: "massage",
    category_name: "Massage",
  },
  {
    id: 3,
    name: "Aromatherapy Spa",
    description:
      "Pure essential oils selected for your needs, combined with a deeply relaxing massage to restore balance between mind and body.",
    starting_price: 180000,
    image_url: "https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=600&q=80",
    duration: 75,
    category_id: "spa",
    category_name: "Spa",
  },
  {
    id: 4,
    name: "Hot Stone Massage",
    description:
      "Heated volcanic stones melt tension from muscles and tissues while a soothing massage completes the experience of deep, penetrating warmth.",
    starting_price: 250000,
    image_url: "https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=600&q=80",
    duration: 90,
    category_id: "spa",
    category_name: "Spa",
  },
  {
    id: 5,
    name: "Reflexology",
    description:
      "Targeted pressure applied to specific points on the feet and hands to stimulate healing throughout the entire body.",
    starting_price: 120000,
    image_url: "https://images.unsplash.com/photo-1600334089648-b0d9d3028eb2?w=600&q=80",
    duration: 45,
    category_id: "wellness",
    category_name: "Wellness",
  },
  {
    id: 6,
    name: "Body Scrub & Wrap",
    description:
      "Exfoliating treatment that removes dead skin cells, followed by a nourishing wrap to leave your skin silky smooth and deeply hydrated.",
    starting_price: 220000,
    image_url: "https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=600&q=80",
    duration: 80,
    category_id: "body",
    category_name: "Body",
  },
];

// ─── Data fetching ────────────────────────────────────────────────────────────

async function getCategories(): Promise<Category[]> {
  try {
    const { data, error } = await supabase
      .from("categories")
      .select("id, name")
      .order("name");
    if (!error && data && data.length > 0) return data as Category[];
  } catch {}
  return fallbackCategories;
}

async function getTreatments(): Promise<Treatment[]> {
  try {
    const { data, error } = await supabase
      .from("treatments")
      .select("*, categories(name)");
    if (!error && data && data.length > 0) {
      return data.map((row) => ({
        id: row.id,
        name: row.name || row.treatment_name || "Treatment",
        description: row.description || "",
        starting_price: row.starting_price ?? row.price ?? null,
        image_url: row.image_url || row.image || fallbackTreatments[0].image_url,
        duration: row.duration ?? null,
        category_id: row.category_id ?? null,
        category_name: row.categories?.name ?? row.category ?? null,
      }));
    }
  } catch {}
  return fallbackTreatments;
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default async function ServicesPage() {
  const [treatments, categories] = await Promise.all([
    getTreatments(),
    getCategories(),
  ]);

  return (
    <>
      <Navbar />
      <main className="min-h-screen bg-spa-dark">
        {/* Hero banner */}
        <section
          className="relative pt-32 pb-20 px-5 text-center overflow-hidden"
          style={{
            backgroundImage:
              "url('https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=1920&q=80')",
            backgroundSize: "cover",
            backgroundPosition: "center",
          }}
        >
          <div className="absolute inset-0 bg-spa-dark/85" />
          <div className="relative z-10">
            <p className="section-label mb-4">What We Offer</p>
            <h1 className="font-display text-5xl md:text-6xl font-bold text-white mb-5">
              Our <span className="gold-text italic">Treatments</span>
            </h1>
            <p className="text-spa-cream/60 max-w-xl mx-auto text-base leading-relaxed">
              Every treatment is thoughtfully designed with certified therapists,
              premium products, and your total comfort in mind
            </p>
          </div>
        </section>

        {/* Filter + grid (client component) */}
        <ServicesClient treatments={treatments} categories={categories} />
      </main>
      <Footer />
    </>
  );
}
