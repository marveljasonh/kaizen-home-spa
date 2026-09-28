"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

function LeafIcon() {
  return (
    <svg viewBox="0 0 32 32" className="w-8 h-8" fill="none">
      <path d="M16 3C9 3 4 11 4 11s3 3 6 3c1.5 0 2.8-.5 3.8-1.4C14.8 13.5 16 14 17 14s2.2-.5 3.2-1.4C21.2 13.5 22.5 14 24 14c3 0 6-3 6-3S23 3 16 3z" fill="#C9A96E" />
      <path d="M16 14v14" stroke="#C9A96E" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");

    const { error: authError } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (authError) {
      setError(authError.message);
      setLoading(false);
    } else {
      const params = new URLSearchParams(window.location.search);
      router.push(params.get("redirect") || "/dashboard");
    }
  }

  return (
    <div
      className="min-h-screen flex items-center justify-center px-5 bg-spa-dark"
      style={{
        backgroundImage: "url('https://images.unsplash.com/photo-1600334089648-b0d9d3028eb2?w=1920&q=80')",
        backgroundSize: "cover",
        backgroundPosition: "center",
      }}
    >
      <div className="absolute inset-0 bg-spa-dark/88" />

      <div className="relative z-10 w-full max-w-md">
        {/* Logo */}
        <Link href="/" className="flex items-center justify-center gap-2.5 mb-8 group">
          <LeafIcon />
          <span className="font-display text-xl font-semibold text-spa-cream group-hover:text-spa-gold transition-colors">
            Kaizen Home Spa
          </span>
        </Link>

        {/* Card */}
        <div className="glass-card rounded-2xl p-8">
          <div className="text-center mb-7">
            <h1 className="font-display text-3xl font-bold text-spa-cream mb-2">
              Welcome back
            </h1>
            <p className="text-spa-cream/50 text-sm">
              Sign in to manage your bookings
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-spa-cream/60 text-xs font-medium mb-2 tracking-wide uppercase">
                Email address
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full px-4 py-3 rounded-xl bg-white/5 border border-white/10 text-spa-cream placeholder-spa-cream/30 text-sm focus:outline-none focus:border-spa-gold/50 focus:bg-white/8 transition-all"
                placeholder="your@email.com"
              />
            </div>

            <div>
              <div className="flex items-center justify-between mb-2">
                <label className="text-spa-cream/60 text-xs font-medium tracking-wide uppercase">
                  Password
                </label>
                <a href="#" className="text-spa-gold/70 text-xs hover:text-spa-gold transition-colors">
                  Forgot password?
                </a>
              </div>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full px-4 py-3 rounded-xl bg-white/5 border border-white/10 text-spa-cream placeholder-spa-cream/30 text-sm focus:outline-none focus:border-spa-gold/50 focus:bg-white/8 transition-all"
                placeholder="••••••••"
              />
            </div>

            {error && (
              <div className="px-4 py-3 rounded-xl bg-red-500/10 border border-red-500/20 text-red-400 text-sm">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3.5 rounded-xl btn-olive font-semibold text-sm border border-spa-gold/25 hover:border-spa-gold/50 disabled:opacity-50 disabled:cursor-not-allowed mt-2"
            >
              {loading ? "Signing in..." : "Sign In"}
            </button>
          </form>

          <div className="mt-6 text-center">
            <p className="text-spa-cream/45 text-sm">
              Don&apos;t have an account?{" "}
              <Link href="/register" className="text-spa-gold hover:text-spa-gold-light transition-colors font-medium">
                Create one
              </Link>
            </p>
          </div>
        </div>

        <p className="text-center text-spa-cream/30 text-xs mt-6">
          By signing in, you agree to our{" "}
          <a href="#" className="hover:text-spa-cream/50 transition-colors">Terms</a> and{" "}
          <a href="#" className="hover:text-spa-cream/50 transition-colors">Privacy Policy</a>
        </p>
      </div>
    </div>
  );
}
