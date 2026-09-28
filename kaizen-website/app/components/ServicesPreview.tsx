import Link from "next/link";
import { supabase } from "@/lib/supabase";

type Treatment = {
  id: number | string;
  name: string;
  description: string;
  starting_price: number | null;
  image_url: string;
  duration?: number;
};

const fallbackServices: Treatment[] = [
  {
    id: 1,
    name: "Swedish Massage",
    description: "Classic full-body relaxation massage that melts away tension with long, flowing strokes",
    starting_price: 150000,
    image_url: "https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=600&q=80",
    duration: 60,
  },
  {
    id: 2,
    name: "Deep Tissue Massage",
    description: "Targets chronic muscle knots and deep tension for lasting relief and recovery",
    starting_price: 200000,
    image_url: "https://images.unsplash.com/photo-1519823551278-64ac92734fb1?w=600&q=80",
    duration: 90,
  },
  {
    id: 3,
    name: "Aromatherapy Spa",
    description: "Therapeutic essential oils paired with gentle massage for full mind-body harmony",
    starting_price: 180000,
    image_url: "https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=600&q=80",
    duration: 75,
  },
];

async function getServices(): Promise<Treatment[]> {
  try {
    const { data, error } = await supabase
      .from("treatments")
      .select("*")
      .limit(3);
    if (!error && data && data.length > 0) {
      const mapped = data.map((row) => ({
        id: row.id,
        name: row.name || row.treatment_name || "Treatment",
        description: row.description || "",
        starting_price: row.starting_price ?? row.price ?? null,
        image_url: row.image_url || row.image || fallbackServices[0].image_url,
        duration: row.duration,
      }));
      return mapped;
    }
  } catch {}
  return fallbackServices;
}

function formatPrice(price: number | null | undefined) {
  if (!price) return "Hubungi kami";
  return `Rp ${price.toLocaleString("id-ID")}`;
}

export async function ServicesPreview() {
  const services = await getServices();

  return (
    <section className="py-28 px-5 bg-spa-darker">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="text-center mb-16">
          <p className="section-label mb-4">Our Treatments</p>
          <h2 className="font-display text-4xl md:text-5xl font-bold text-spa-cream mb-5">
            Signature Spa Services
          </h2>
          <p className="text-spa-cream/55 max-w-sm mx-auto text-sm leading-relaxed">
            Each treatment is crafted with care, using only the finest products
            and techniques for your ultimate wellbeing
          </p>
        </div>

        {/* Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {services.map((service) => (
            <div
              key={service.id}
              className="glass-card glass-card-hover rounded-2xl overflow-hidden group"
            >
              {/* Image */}
              <div className="relative h-56 overflow-hidden">
                <img
                  src={service.image_url}
                  alt={service.name}
                  className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-[#1C1C1A] via-[#1C1C1A]/20 to-transparent" />
                {service.duration && (
                  <div className="absolute top-4 right-4 px-3 py-1 rounded-full bg-spa-dark/80 backdrop-blur-sm border border-white/10 text-spa-cream/70 text-xs font-medium">
                    {service.duration} min
                  </div>
                )}
              </div>

              {/* Content */}
              <div className="p-6">
                <h3 className="font-display text-xl font-semibold text-spa-cream mb-2 group-hover:text-spa-gold transition-colors">
                  {service.name}
                </h3>
                <p className="text-spa-cream/55 text-sm leading-relaxed mb-5">
                  {service.description}
                </p>
                <div className="flex items-center justify-between">
                  <div>
                    <span className="text-spa-cream/35 text-[11px] uppercase tracking-wide">
                      Starting from
                    </span>
                    <p className="text-spa-gold font-semibold text-lg leading-tight">
                      {formatPrice(service.starting_price)}
                    </p>
                  </div>
                  <Link
                    href="/order"
                    className="px-5 py-2 rounded-full border border-spa-gold/35 text-spa-gold text-sm font-medium hover:bg-spa-gold hover:text-spa-dark transition-all duration-300"
                  >
                    Book
                  </Link>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* CTA */}
        <div className="text-center mt-12">
          <Link
            href="/services"
            className="inline-flex items-center gap-2.5 px-8 py-3.5 rounded-full border border-spa-olive/60 text-spa-cream/70 text-sm font-medium hover:border-spa-gold hover:text-spa-gold transition-all duration-300"
          >
            View All Services
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 5l7 7-7 7" />
            </svg>
          </Link>
        </div>
      </div>
    </section>
  );
}
