"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";
import type { User } from "@supabase/supabase-js";

type Booking = {
  id: string;
  treatment_name: string;
  date: string;
  time: string;
  address: string;
  price: number;
  status: "pending" | "confirmed" | "completed" | "cancelled";
  created_at: string;
};

function formatPrice(price: number) {
  return `Rp ${price?.toLocaleString("id-ID") ?? "–"}`;
}

const statusColors: Record<string, string> = {
  pending: "text-amber-400 bg-amber-400/10 border-amber-400/25",
  confirmed: "text-blue-400 bg-blue-400/10 border-blue-400/25",
  completed: "text-green-400 bg-green-400/10 border-green-400/25",
  cancelled: "text-red-400 bg-red-400/10 border-red-400/25",
};

export default function DashboardPage() {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      const { data: { user: currentUser } } = await supabase.auth.getUser();

      if (!currentUser) {
        router.push("/login");
        return;
      }

      setUser(currentUser);

      const { data } = await supabase
        .from("bookings")
        .select("*")
        .eq("user_id", currentUser.id)
        .order("created_at", { ascending: false });

      setBookings((data as Booking[]) ?? []);
      setLoading(false);
    }

    load();
  }, [router]);

  async function handleSignOut() {
    await supabase.auth.signOut();
    router.push("/");
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-spa-dark flex items-center justify-center">
        <div className="text-center">
          <div className="w-10 h-10 border-2 border-spa-gold/30 border-t-spa-gold rounded-full animate-spin mx-auto mb-4" />
          <p className="text-spa-cream/40 text-sm">Loading your dashboard...</p>
        </div>
      </div>
    );
  }

  const userName = user?.user_metadata?.full_name || user?.email?.split("@")[0] || "Guest";
  const upcomingCount = bookings.filter((b) => b.status !== "completed" && b.status !== "cancelled").length;

  return (
    <div className="min-h-screen bg-spa-dark">
      {/* Header */}
      <header className="border-b border-white/6 bg-spa-dark/95 backdrop-blur-md sticky top-0 z-40">
        <div className="max-w-6xl mx-auto px-5 h-16 flex items-center justify-between">
          <Link href="/" className="font-display text-lg font-semibold text-spa-cream hover:text-spa-gold transition-colors">
            Kaizen Home Spa
          </Link>
          <div className="flex items-center gap-4">
            <span className="text-spa-cream/50 text-sm hidden sm:block">
              {user?.email}
            </span>
            <button
              onClick={handleSignOut}
              className="text-spa-cream/50 text-sm hover:text-spa-cream transition-colors"
            >
              Sign out
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-5 py-10">
        {/* Welcome */}
        <div className="mb-10">
          <p className="text-spa-cream/45 text-sm mb-1">Welcome back,</p>
          <h1 className="font-display text-3xl font-bold text-spa-cream">
            {userName}
          </h1>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-10">
          {[
            { label: "Total Bookings", value: bookings.length },
            { label: "Upcoming", value: upcomingCount },
            { label: "Completed", value: bookings.filter((b) => b.status === "completed").length },
            {
              label: "Total Spent",
              value: formatPrice(bookings.filter((b) => b.status === "completed").reduce((s, b) => s + (b.price || 0), 0)),
            },
          ].map((stat) => (
            <div key={stat.label} className="glass-card rounded-2xl p-5">
              <div className="text-spa-cream/40 text-xs mb-2">{stat.label}</div>
              <div className="font-display text-2xl font-bold text-spa-gold">
                {stat.value}
              </div>
            </div>
          ))}
        </div>

        {/* Bookings list */}
        <div className="mb-5 flex items-center justify-between">
          <h2 className="font-display text-xl font-semibold text-spa-cream">
            Your Bookings
          </h2>
          <Link
            href="/order"
            className="px-5 py-2 rounded-full btn-olive text-sm border border-spa-gold/25"
          >
            Book New
          </Link>
        </div>

        {bookings.length === 0 ? (
          <div className="glass-card rounded-2xl p-12 text-center">
            <div className="w-14 h-14 rounded-full bg-spa-olive/20 flex items-center justify-center mx-auto mb-4">
              <svg className="w-7 h-7 text-spa-gold/50" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
            <p className="text-spa-cream/55 text-sm mb-5">
              You haven&apos;t made any bookings yet
            </p>
            <Link
              href="/order"
              className="inline-block px-7 py-3 rounded-full btn-gold text-sm font-semibold"
            >
              Book Your First Session
            </Link>
          </div>
        ) : (
          <div className="space-y-3">
            {bookings.map((booking) => (
              <div
                key={booking.id}
                className="glass-card rounded-2xl p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4"
              >
                <div className="flex-1">
                  <div className="flex items-start gap-3 mb-2">
                    <h3 className="text-spa-cream font-medium text-sm">{booking.treatment_name}</h3>
                    <span className={`px-2.5 py-0.5 rounded-full text-xs border ${statusColors[booking.status] || statusColors.pending}`}>
                      {booking.status}
                    </span>
                  </div>
                  <div className="flex flex-wrap gap-4 text-spa-cream/45 text-xs">
                    <span className="flex items-center gap-1.5">
                      <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                      {booking.date} at {booking.time}
                    </span>
                    <span className="flex items-center gap-1.5">
                      <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                      </svg>
                      {booking.address}
                    </span>
                  </div>
                </div>
                <div className="text-right shrink-0">
                  <p className="text-spa-gold font-semibold text-base font-display">
                    {formatPrice(booking.price)}
                  </p>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
