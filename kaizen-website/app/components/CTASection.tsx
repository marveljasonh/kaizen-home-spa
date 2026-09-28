"use client";

import { motion } from "framer-motion";
import Link from "next/link";

type Props = {
  content?: Record<string, string>;
};

export function CTASection({ content = {} }: Props) {
  const headline = content.cta_headline || "Ready to Relax?";
  const subtext =
    content.cta_subtext ||
    "Transform your home into a sanctuary of peace. Book your session today and experience the Kaizen difference.";
  const buttonText = content.cta_button_text || "Book Now";
  const secondaryText = content.cta_secondary_text || "See Treatments";

  return (
    <section className="relative py-32 px-5 overflow-hidden">
      {/* Background */}
      <div
        className="absolute inset-0 bg-cover bg-center bg-no-repeat"
        style={{
          backgroundImage:
            "url('https://images.unsplash.com/photo-1519823551278-64ac92734fb1?w=1920&q=80')",
        }}
      />
      <div className="absolute inset-0 bg-gradient-to-b from-[#1C1C1A]/90 via-[#1C1C1A]/75 to-[#1C1C1A]/95" />
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,rgba(201,169,110,0.08)_0%,transparent_65%)]" />
      <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-spa-gold/30 to-transparent" />
      <div className="absolute bottom-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-spa-gold/30 to-transparent" />

      <div className="relative z-10 max-w-3xl mx-auto text-center">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
        >
          <p className="section-label mb-5">Book Today</p>
          <h2 className="font-display text-5xl md:text-6xl lg:text-7xl font-bold text-white mb-6 leading-tight">
            {headline.includes("Relax") ? (
              <>
                {headline.replace("Relax?", "").replace("Relax", "")}{" "}
                <span className="gold-text italic">
                  {headline.includes("Relax?") ? "Relax?" : "Relax"}
                </span>
              </>
            ) : (
              headline
            )}
          </h2>
          <p className="text-spa-cream/65 text-lg mb-10 max-w-lg mx-auto leading-relaxed">
            {subtext}
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link
              href="/order"
              className="px-10 py-4 rounded-full btn-gold text-sm font-semibold tracking-wide min-w-[200px] text-center"
            >
              {buttonText}
            </Link>
            <Link
              href="/services"
              className="px-10 py-4 rounded-full border border-white/25 text-spa-cream/85 text-sm font-medium tracking-wide hover:border-spa-gold/50 hover:text-spa-gold transition-all duration-300 min-w-[200px] text-center"
            >
              {secondaryText}
            </Link>
          </div>

          {/* Trust indicators */}
          <div className="flex flex-wrap items-center justify-center gap-6 mt-12 text-spa-cream/40 text-xs">
            {[
              content.cta_trust_1 || "No upfront payment",
              content.cta_trust_2 || "Free cancellation",
              content.cta_trust_3 || "Certified therapists",
            ].map((item) => (
              <span key={item} className="flex items-center gap-1.5">
                <svg className="w-3.5 h-3.5 text-spa-gold/60" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
                {item}
              </span>
            ))}
          </div>
        </motion.div>
      </div>
    </section>
  );
}
