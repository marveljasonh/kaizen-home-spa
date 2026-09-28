"use client";

import { motion } from "framer-motion";
import Link from "next/link";

export type SpaEvent = {
  id: string | number;
  title: string;
  description: string | null;
  event_date: string | null;
  location: string | null;
  image_url: string | null;
};

type Props = { events: SpaEvent[] };

const collabTypes = [
  {
    emoji: "🏨",
    title: "Hotels & Resorts",
    desc: "Exclusive spa packages and in-room treatment programs for your guests",
  },
  {
    emoji: "🏢",
    title: "Corporate Wellness",
    desc: "Employee wellness programs, office chair massage, and company retreats",
  },
  {
    emoji: "💒",
    title: "Wedding & Events",
    desc: "Pre-wedding pampering, bridal party packages, and event-day relaxation",
  },
  {
    emoji: "🌿",
    title: "Wellness Brands",
    desc: "Co-branded experiences, product collaborations, and wellness pop-ups",
  },
];

function formatEventDate(dateStr: string | null) {
  if (!dateStr) return "Date TBD";
  const d = new Date(dateStr);
  return d.toLocaleDateString("id-ID", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });
}

const fadeUp = {
  hidden: { opacity: 0, y: 24 },
  show: (i: number) => ({
    opacity: 1,
    y: 0,
    transition: { delay: i * 0.09, duration: 0.5, ease: [0.22, 1, 0.36, 1] },
  }),
};

export function EventsClient({ events }: Props) {
  return (
    <>
      {/* ── Upcoming Events ─────────────────────────────────── */}
      <section className="py-20 px-5 max-w-7xl mx-auto">
        <div className="text-center mb-14">
          <p className="section-label mb-4">Upcoming</p>
          <h2 className="font-display text-4xl md:text-5xl font-bold text-spa-cream">
            Our <span className="gold-text italic">Events</span>
          </h2>
        </div>

        {events.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {events.map((event, i) => (
              <motion.div
                key={event.id}
                custom={i}
                variants={fadeUp}
                initial="hidden"
                whileInView="show"
                viewport={{ once: true, margin: "-60px" }}
                className="glass-card glass-card-hover rounded-2xl overflow-hidden group"
              >
                {/* Image / gradient placeholder */}
                <div className="relative h-48 overflow-hidden">
                  {event.image_url ? (
                    <img
                      src={event.image_url}
                      alt={event.title}
                      className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700"
                    />
                  ) : (
                    <div className="w-full h-full bg-gradient-to-br from-spa-olive/50 via-spa-darker to-spa-deepest" />
                  )}
                  <div className="absolute inset-0 bg-gradient-to-t from-[#1C1C1A] via-transparent to-transparent" />
                  {/* Date badge */}
                  <div className="absolute top-4 left-4">
                    <span className="px-3 py-1.5 rounded-full bg-spa-gold text-spa-dark text-xs font-semibold shadow-lg">
                      {formatEventDate(event.event_date)}
                    </span>
                  </div>
                </div>

                {/* Body */}
                <div className="p-6">
                  <h3 className="font-display text-xl font-semibold text-spa-cream group-hover:text-spa-gold transition-colors mb-2">
                    {event.title}
                  </h3>
                  {event.description && (
                    <p className="text-spa-cream/55 text-sm leading-relaxed mb-4 line-clamp-3">
                      {event.description}
                    </p>
                  )}
                  {event.location && (
                    <div className="flex items-center gap-2 text-spa-cream/40 text-xs mb-5">
                      <svg
                        className="w-3.5 h-3.5 text-spa-gold/50 shrink-0"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={1.5}
                          d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                        />
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          strokeWidth={1.5}
                          d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                        />
                      </svg>
                      {event.location}
                    </div>
                  )}
                  <button className="w-full py-2.5 rounded-full border border-spa-gold/35 text-spa-gold text-sm font-medium hover:bg-spa-gold hover:text-spa-dark transition-all duration-300">
                    Learn More
                  </button>
                </div>
              </motion.div>
            ))}
          </div>
        ) : (
          <motion.div
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="text-center py-28"
          >
            <div className="w-16 h-16 rounded-full bg-spa-olive/20 flex items-center justify-center mx-auto mb-6">
              <svg
                className="w-7 h-7 text-spa-gold/40"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={1.5}
                  d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                />
              </svg>
            </div>
            <p className="font-display text-xl text-spa-cream/50 mb-2">
              No upcoming events
            </p>
            <p className="text-spa-cream/30 text-sm">
              Check back soon for exciting wellness experiences
            </p>
          </motion.div>
        )}
      </section>

      {/* ── Collaboration ───────────────────────────────────── */}
      <section className="py-20 px-5 bg-spa-darker">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-14">
            <p className="section-label mb-4">Work With Us</p>
            <h2 className="font-display text-4xl md:text-5xl font-bold text-spa-cream mb-5">
              Let&apos;s <span className="gold-text italic">Collaborate</span>
            </h2>
            <p className="text-spa-cream/55 max-w-2xl mx-auto text-base leading-relaxed">
              We partner with hotels, corporate offices, wedding organizers, and
              wellness brands to craft tailored experiences your clients will
              remember long after the day is over.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5 mb-12">
            {collabTypes.map((type, i) => (
              <motion.div
                key={type.title}
                custom={i}
                variants={fadeUp}
                initial="hidden"
                whileInView="show"
                viewport={{ once: true, margin: "-60px" }}
                className="glass-card glass-card-hover rounded-2xl p-7 text-center group"
              >
                <div className="text-4xl mb-4">{type.emoji}</div>
                <h3 className="font-display text-lg font-semibold text-spa-cream group-hover:text-spa-gold transition-colors mb-2">
                  {type.title}
                </h3>
                <p className="text-spa-cream/45 text-sm leading-relaxed">
                  {type.desc}
                </p>
              </motion.div>
            ))}
          </div>

          <div className="text-center">
            <Link
              href="/contact"
              className="inline-flex items-center gap-2.5 px-8 py-3.5 rounded-full btn-gold font-medium text-sm"
            >
              Get in Touch
              <svg
                className="w-4 h-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M17 8l4 4m0 0l-4 4m4-4H3"
                />
              </svg>
            </Link>
          </div>
        </div>
      </section>
    </>
  );
}
