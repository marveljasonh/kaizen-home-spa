"use client";

import { motion } from "framer-motion";

type Props = {
  content: Record<string, string>;
};

const icons = [
  <svg key="shield" className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
  </svg>,
  <svg key="home" className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
  </svg>,
  <svg key="star" className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z" />
  </svg>,
  <svg key="calendar" className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
  </svg>,
];

const DEFAULTS = [
  {
    title: "Professional Therapists",
    description: "Our certified therapists bring years of expertise to every session, delivering clinical-grade care with a personal touch.",
  },
  {
    title: "Home Service",
    description: "Skip the commute. We bring the full spa experience to your doorstep — you just relax while we handle everything.",
  },
  {
    title: "Premium Products",
    description: "We use only curated therapeutic oils, aromatics, and skincare products chosen for their purity and effectiveness.",
  },
  {
    title: "Flexible Schedule",
    description: "Book at your convenience — mornings, evenings, or weekends. We operate 7 days a week to fit your lifestyle.",
  },
];

export function WhyChooseUs({ content }: Props) {
  const sectionTitle = content.why_us_section_title || "The Kaizen Difference";
  const sectionSubtitle =
    content.why_us_section_subtitle ||
    "We believe premium self-care should be accessible, personal, and genuinely transformative";

  const features = DEFAULTS.map((def, i) => ({
    icon: icons[i],
    title: content[`why_us_${i + 1}_title`] || def.title,
    description: content[`why_us_${i + 1}_desc`] || def.description,
  }));

  return (
    <section className="py-28 px-5 bg-spa-dark">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="text-center mb-16">
          <p className="section-label mb-4">Why Kaizen</p>
          <h2 className="font-display text-4xl md:text-5xl font-bold text-spa-cream mb-5">
            {sectionTitle}
          </h2>
          <p className="text-spa-cream/55 max-w-sm mx-auto text-sm leading-relaxed">
            {sectionSubtitle}
          </p>
        </div>

        {/* Feature grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {features.map((feature, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 32 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-50px" }}
              transition={{ duration: 0.55, delay: i * 0.1, ease: [0.22, 1, 0.36, 1] }}
              className="glass-card rounded-2xl p-7 text-center group hover:border-spa-gold/25 transition-all duration-300"
            >
              <div className="w-14 h-14 rounded-xl bg-spa-olive/25 flex items-center justify-center mx-auto mb-5 text-spa-gold group-hover:bg-spa-gold/12 group-hover:scale-110 transition-all duration-300">
                {feature.icon}
              </div>
              <div className="w-8 h-px bg-spa-gold/30 mx-auto mb-4 group-hover:w-14 transition-all duration-500" />
              <h3 className="font-display text-lg font-semibold text-spa-cream mb-3">
                {feature.title}
              </h3>
              <p className="text-spa-cream/55 text-sm leading-relaxed">
                {feature.description}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
