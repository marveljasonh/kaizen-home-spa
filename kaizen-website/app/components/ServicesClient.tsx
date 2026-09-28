"use client";

import { useState } from "react";
import Link from "next/link";

export type Category = {
  id: string | number;
  name: string;
};

export type Treatment = {
  id: string | number;
  name: string;
  description: string;
  starting_price: number | null;
  image_url: string;
  duration?: number | null;
  category_id?: string | number | null;
  category_name?: string | null;
};

type Props = {
  treatments: Treatment[];
  categories: Category[];
};

function formatPrice(price: number | null | undefined) {
  if (!price) return "Hubungi kami";
  return `Rp ${price.toLocaleString("id-ID")}`;
}

export function ServicesClient({ treatments, categories }: Props) {
  const [selectedCategory, setSelectedCategory] = useState<string>("all");

  const filtered =
    selectedCategory === "all"
      ? treatments
      : treatments.filter((t) => String(t.category_id) === selectedCategory);

  return (
    <section className="py-20 px-5 max-w-7xl mx-auto">
      {/* Category filter pills */}
      <div className="flex flex-wrap gap-3 mb-6">
        <button
          onClick={() => setSelectedCategory("all")}
          className={`px-5 py-2 rounded-full text-sm font-medium transition-all duration-200 ${
            selectedCategory === "all"
              ? "bg-[#C9A96E] text-black"
              : "bg-white/10 text-white/70 hover:bg-white/20"
          }`}
        >
          All
        </button>
        {categories.map((cat) => (
          <button
            key={cat.id}
            onClick={() => setSelectedCategory(String(cat.id))}
            className={`px-5 py-2 rounded-full text-sm font-medium transition-all duration-200 ${
              selectedCategory === String(cat.id)
                ? "bg-[#C9A96E] text-black"
                : "bg-white/10 text-white/70 hover:bg-white/20"
            }`}
          >
            {cat.name}
          </button>
        ))}
      </div>

      {/* Result count */}
      <p className="text-spa-cream/35 text-xs mb-8 tracking-wide">
        {filtered.length} treatment{filtered.length !== 1 ? "s" : ""} available
      </p>

      {/* Grid */}
      {filtered.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filtered.map((service) => (
            <div
              key={service.id}
              className="glass-card glass-card-hover rounded-2xl overflow-hidden group"
            >
              {/* Image */}
              <div className="relative h-52 overflow-hidden">
                <img
                  src={service.image_url}
                  alt={service.name}
                  className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-[#1C1C1A] via-[#1C1C1A]/10 to-transparent" />
                {service.duration && (
                  <div className="absolute top-4 right-4">
                    <span className="px-3 py-1 rounded-full bg-spa-dark/80 backdrop-blur-sm border border-white/10 text-spa-gold/70 text-xs">
                      {service.duration} min
                    </span>
                  </div>
                )}
              </div>

              {/* Content */}
              <div className="p-6">
                {service.category_name && (
                  <span className="text-xs text-[#C9A96E] uppercase tracking-wider">
                    {service.category_name}
                  </span>
                )}
                <h3
                  className={`font-display text-xl font-semibold text-spa-cream group-hover:text-spa-gold transition-colors ${
                    service.category_name ? "mt-1 mb-2" : "mb-2"
                  }`}
                >
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
                    <p className="text-spa-gold font-semibold text-lg">
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
      ) : (
        <div className="text-center py-24">
          <div className="w-12 h-12 rounded-full bg-spa-olive/20 flex items-center justify-center mx-auto mb-4">
            <svg className="w-5 h-5 text-spa-gold/40" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <p className="text-spa-cream/40 text-sm">No treatments in this category yet.</p>
        </div>
      )}
    </section>
  );
}
