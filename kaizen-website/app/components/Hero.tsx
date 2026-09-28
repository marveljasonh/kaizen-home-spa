"use client";

import { motion } from "framer-motion";
import Link from "next/link";

const fade = (delay = 0) => ({
  initial: { opacity: 0, y: 28 },
  animate: { opacity: 1, y: 0 },
  transition: { duration: 0.8, delay, ease: [0.22, 1, 0.36, 1] },
});

type Props = {
  content: Record<string, string>;
};

function splitHeadline(headline: string): [string, string] {
  const idx = headline.indexOf(" ");
  if (idx < 0) return [headline, ""];
  return [headline.slice(0, idx), headline.slice(idx + 1)];
}

function AppleBadge() {
  return (
    <a
      href="#"
      className="flex items-center gap-3 px-5 py-3 rounded-full bg-black/60 border border-white/15 hover:border-white/35 hover:bg-black/80 backdrop-blur-sm transition-all duration-200 group"
      aria-label="Download on the App Store"
    >
      <svg className="w-5 h-5 text-white fill-current shrink-0" viewBox="0 0 814 1000">
        <path d="M788.1 340.9c-5.8 4.5-108.2 62.2-108.2 190.5 0 148.4 130.3 200.9 134.2 202.2-.6 3.2-20.7 71.9-68.7 141.9-42.8 61.6-87.5 123.1-155.5 123.1s-85.5-39.5-164-39.5c-76 0-103.7 40.8-165.9 40.8s-105-57.8-155.5-127.4C46 790.7 0 663 0 541.8c0-207.3 137.4-316.8 272.5-316.8 73.4 0 134.4 47.4 180.1 47.4 43.1 0 110.8-52 194.6-52 31.2 0 108.2 2.6 168.6 71.5zm-174.2-51.7c-12.7-17.3-41.5-47.9-92.8-47.9-51.3 0-93.5 31.1-119.7 31.1s-73.5-33-126.8-33c-95.3 0-190.3 71.5-190.3 215.3 0 98.4 38.9 197.5 89.2 261.4 43.1 55 81.9 93.5 135.8 93.5 53.9 0 82.7-33.8 143.5-33.8 59.2 0 93.7 33.8 155.5 33.8 63.3 0 103.7-47.3 145.6-103 42.8-61.6 60.6-121.7 61.3-124.9-.6-.3-118.7-45.5-118.7-177.5 0-111.7 78.5-162.6 89.9-171.5z" />
      </svg>
      <div className="text-left">
        <div className="text-white/60 text-[9px] leading-none tracking-wide">Download on the</div>
        <div className="text-white text-sm font-semibold leading-tight tracking-wide">App Store</div>
      </div>
    </a>
  );
}

function GooglePlayBadge() {
  return (
    <a
      href="#"
      className="flex items-center gap-3 px-5 py-3 rounded-full bg-black/60 border border-white/15 hover:border-white/35 hover:bg-black/80 backdrop-blur-sm transition-all duration-200 group"
      aria-label="Get it on Google Play"
    >
      {/* Coloured Google Play triangle icon */}
      <svg className="w-5 h-5 shrink-0" viewBox="0 0 24 24">
        <path d="M3.18 23.76c.3.17.64.24.99.2l12.7-11.7L13.45 9l-10.27 14.76z" fill="#EA4335" />
        <path d="M20.96 10.48L17.9 8.72l-3.62 3.33 3.62 3.33 3.1-1.8c.88-.51.88-1.59-.04-2.1z" fill="#FBBC04" />
        <path d="M3.18.24C2.83.2 2.48.28 2.18.45L13.45 12l3.42-3.15L3.18.24z" fill="#4285F4" />
        <path d="M2.18.45C1.64.75 1.28 1.34 1.28 2.09v19.82c0 .75.36 1.34.9 1.64L13.45 12 2.18.45z" fill="#34A853" />
      </svg>
      <div className="text-left">
        <div className="text-white/60 text-[9px] leading-none tracking-wide">Get it on</div>
        <div className="text-white text-sm font-semibold leading-tight tracking-wide">Google Play</div>
      </div>
    </a>
  );
}

export function Hero({ content }: Props) {
  const rawHeadline = content.hero_headline || "Kaizen Home Spa";
  const [headlineMain, headlineAccent] = splitHeadline(rawHeadline);
  const subtext =
    content.hero_subtext ||
    "We provide high-quality body relaxation experiences using expert touch and carefully selected techniques to rejuvenate your body and mind.";
  const ctaText = content.hero_cta || "Book Our Massage";

  return (
    <section className="relative min-h-screen flex flex-col overflow-hidden">
      {/* Background image */}
      <div
        className="absolute inset-0 bg-cover bg-center bg-no-repeat scale-105"
        style={{
          backgroundImage:
            "url('https://images.unsplash.com/photo-1600334089648-b0d9d3028eb2?w=1920&q=80')",
        }}
      />

      {/* Layered overlays */}
      <div className="absolute inset-0 bg-gradient-to-b from-[#1C1C1A]/75 via-[#1C1C1A]/50 to-[#1C1C1A]" />
      <div className="absolute inset-0 bg-gradient-to-r from-[#1C1C1A]/60 via-transparent to-[#1C1C1A]/40" />

      {/* Gold line */}
      <div className="absolute bottom-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-spa-gold/30 to-transparent" />

      {/* Content */}
      <div className="relative z-10 flex-1 flex items-center justify-center px-5 pt-28 pb-16">
        <div className="text-center max-w-4xl mx-auto">

          {/* App store badges */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.6, ease: "easeOut" }}
            className="flex items-center justify-center gap-3 mb-8"
          >
            <AppleBadge />
            <GooglePlayBadge />
          </motion.div>

          {/* Headline */}
          <motion.h1
            {...fade(0.15)}
            className="font-display text-5xl sm:text-7xl md:text-8xl font-bold text-white leading-[1.05] mb-6"
          >
            {headlineMain}{headlineAccent ? " " : ""}
            {headlineAccent && (
              <span className="gold-text italic">{headlineAccent}</span>
            )}
          </motion.h1>

          {/* Description */}
          <motion.p
            {...fade(0.25)}
            className="text-spa-cream/75 text-lg md:text-xl max-w-2xl mx-auto mb-10 leading-relaxed"
          >
            {subtext}
          </motion.p>

          {/* CTA buttons */}
          <motion.div
            {...fade(0.35)}
            className="flex flex-col sm:flex-row items-center justify-center gap-4"
          >
            <Link
              href="/order"
              className="px-9 py-4 rounded-full btn-olive text-sm font-semibold tracking-wide border border-spa-gold/30 min-w-[200px] text-center"
            >
              {ctaText}
            </Link>
            <Link
              href="/services"
              className="px-9 py-4 rounded-full border border-white/25 text-spa-cream/85 text-sm font-medium tracking-wide hover:border-spa-gold/50 hover:text-spa-gold transition-all duration-300 min-w-[200px] text-center"
            >
              {content.hero_cta_secondary || "Explore Treatments"}
            </Link>
          </motion.div>

          {/* Stats */}
          <motion.div
            {...fade(0.45)}
            className="flex flex-wrap items-center justify-center gap-8 mt-14"
          >
            {[
              { valueKey: "stat_clients_value", labelKey: "stat_clients_label", defaultValue: "500+", defaultLabel: "Happy Clients" },
              { valueKey: "stat_treatments_value", labelKey: "stat_treatments_label", defaultValue: "15+", defaultLabel: "Treatments" },
              { valueKey: "stat_rating_value", labelKey: "stat_rating_label", defaultValue: "4.8★", defaultLabel: "Average Rating" },
              { valueKey: "stat_years_value", labelKey: "stat_years_label", defaultValue: "3+", defaultLabel: "Years Experience" },
            ].map((stat) => (
              <div key={stat.labelKey} className="text-center">
                <div className="font-display text-2xl font-bold text-spa-gold">
                  {content[stat.valueKey] || stat.defaultValue}
                </div>
                <div className="text-spa-cream/50 text-xs tracking-wide mt-0.5">
                  {content[stat.labelKey] || stat.defaultLabel}
                </div>
              </div>
            ))}
          </motion.div>
        </div>
      </div>

      {/* Scroll cue */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.4 }}
        className="relative z-10 flex justify-center pb-8"
      >
        <div className="flex flex-col items-center gap-2 text-spa-cream/30">
          <span className="text-[10px] tracking-[0.3em] uppercase">Scroll</span>
          <motion.div
            animate={{ y: [0, 6, 0] }}
            transition={{ repeat: Infinity, duration: 1.8, ease: "easeInOut" }}
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M19 9l-7 7-7-7" />
            </svg>
          </motion.div>
        </div>
      </motion.div>
    </section>
  );
}
