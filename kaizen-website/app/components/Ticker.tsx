"use client";

const DEFAULT_ITEMS = [
  "✦ Professional Home Spa Service",
  "✦ West Java, Indonesia",
  "✦ Expert Certified Therapists",
  "✦ Premium Aromatherapy Products",
  "✦ Flexible Scheduling 7 Days a Week",
  "✦ Excellent ★ 4.8 Rating",
  "✦ Book Now & Relax at Home",
  "✦ Deep Tissue & Swedish Massage",
];

type Props = {
  content: Record<string, string>;
};

export function Ticker({ content }: Props) {
  const items = content.ticker_text
    ? content.ticker_text.split("|").map((s) => s.trim()).filter(Boolean)
    : DEFAULT_ITEMS;

  const doubled = [...items, ...items];

  return (
    <div className="bg-spa-olive/20 border-y border-spa-gold/15 overflow-hidden py-3">
      <div className="animate-ticker">
        {doubled.map((item, i) => (
          <span
            key={i}
            className="text-xs text-spa-gold/70 font-medium tracking-wider shrink-0"
          >
            {item}
          </span>
        ))}
      </div>
    </div>
  );
}
