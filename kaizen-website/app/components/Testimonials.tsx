"use client";

import { motion } from "framer-motion";

type Props = {
  content: Record<string, string>;
};

const DEFAULT_TESTIMONIALS = [
  {
    name: "Sari Dewi",
    location: "Bandung, West Java",
    rating: 5,
    text: "Incredible experience! The therapist was professional and the massage was absolutely divine. I felt completely rejuvenated — it's been three days and I still feel amazing.",
    initials: "SD",
    service: "Swedish Massage",
  },
  {
    name: "Budi Santoso",
    location: "Cimahi, West Java",
    rating: 5,
    text: "Booking was seamless and the service exceeded every expectation. Having a luxury spa come to my home is something I never knew I needed. Will definitely book again.",
    initials: "BS",
    service: "Deep Tissue Massage",
  },
  {
    name: "Indah Rahayu",
    location: "Sukabumi, West Java",
    rating: 5,
    text: "The aromatherapy session was life-changing. Beautifully curated oils, an incredibly skilled therapist, and I didn't have to go anywhere. This is true luxury.",
    initials: "IR",
    service: "Aromatherapy Spa",
  },
];

export function Testimonials({ content }: Props) {
  const sectionTitle = content.testimonials_title || "What Our Clients Say";
  const ratingText = content.testimonials_rating_text || "4.8 average from 200+ reviews";

  return (
    <section className="py-28 px-5 bg-spa-darker relative overflow-hidden">
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(201,169,110,0.04)_0%,transparent_70%)]" />

      <div className="relative z-10 max-w-7xl mx-auto">
        {/* Header */}
        <div className="text-center mb-16">
          <p className="section-label mb-4">Testimonials</p>
          <h2 className="font-display text-4xl md:text-5xl font-bold text-spa-cream mb-5">
            {sectionTitle}
          </h2>
          <div className="flex items-center justify-center gap-3">
            <div className="flex gap-1">
              {[...Array(5)].map((_, i) => (
                <svg key={i} className="w-4 h-4 text-spa-gold fill-current" viewBox="0 0 20 20">
                  <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                </svg>
              ))}
            </div>
            <span className="text-spa-cream/50 text-sm">{ratingText}</span>
          </div>
        </div>

        {/* Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {DEFAULT_TESTIMONIALS.map((t, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-50px" }}
              transition={{ duration: 0.55, delay: i * 0.12, ease: [0.22, 1, 0.36, 1] }}
              className="glass-card rounded-2xl p-7 hover:border-spa-gold/20 transition-all duration-300 flex flex-col"
            >
              <div className="text-spa-gold/20 font-display text-6xl leading-none mb-2 -mt-2">
                &ldquo;
              </div>
              <div className="flex gap-0.5 mb-4">
                {[...Array(t.rating)].map((_, i) => (
                  <svg key={i} className="w-3.5 h-3.5 text-spa-gold fill-current" viewBox="0 0 20 20">
                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                  </svg>
                ))}
              </div>
              <p className="text-spa-cream/65 text-sm leading-relaxed flex-1 mb-6">{t.text}</p>
              <div className="mb-5">
                <span className="text-[11px] text-spa-gold/60 border border-spa-gold/20 rounded-full px-3 py-1">
                  {t.service}
                </span>
              </div>
              <div className="h-px bg-white/6 mb-5" />
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-full bg-spa-olive/60 flex items-center justify-center text-spa-cream text-xs font-semibold shrink-0">
                  {t.initials}
                </div>
                <div>
                  <p className="text-spa-cream text-sm font-medium">{t.name}</p>
                  <p className="text-spa-cream/40 text-xs">{t.location}</p>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
