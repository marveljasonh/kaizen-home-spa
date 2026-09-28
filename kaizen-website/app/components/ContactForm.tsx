"use client";

import { useState } from "react";
import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

type Status = "idle" | "loading" | "success" | "error";

export function ContactForm() {
  const [form, setForm] = useState({
    name: "",
    email: "",
    phone: "",
    message: "",
  });
  const [status, setStatus] = useState<Status>("idle");

  function set(field: keyof typeof form) {
    return (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
      setForm((prev) => ({ ...prev, [field]: e.target.value }));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!form.name || !form.email || !form.message) return;
    setStatus("loading");
    try {
      const { error } = await supabase.from("contact_inquiries").insert({
        name: form.name,
        email: form.email,
        phone: form.phone || null,
        message: form.message,
      });
      if (error) throw error;
      setStatus("success");
      setForm({ name: "", email: "", phone: "", message: "" });
    } catch {
      setStatus("error");
    }
  }

  const inputClass =
    "w-full px-4 py-3 rounded-xl bg-white/5 border border-white/10 text-spa-cream placeholder-spa-cream/25 text-sm focus:outline-none focus:border-spa-gold/40 focus:bg-white/8 transition-all duration-200";

  if (status === "success") {
    return (
      <div className="text-center py-16">
        <div className="w-14 h-14 rounded-full bg-spa-gold/15 flex items-center justify-center mx-auto mb-5">
          <svg
            className="w-6 h-6 text-spa-gold"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M5 13l4 4L19 7"
            />
          </svg>
        </div>
        <p className="font-display text-xl text-spa-cream mb-2">
          Message sent!
        </p>
        <p className="text-spa-cream/45 text-sm mb-6">
          We&apos;ll get back to you within 24 hours.
        </p>
        <button
          onClick={() => setStatus("idle")}
          className="text-spa-gold/70 text-sm hover:text-spa-gold transition-colors underline underline-offset-4"
        >
          Send another message
        </button>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div>
          <label className="block text-xs text-spa-cream/40 uppercase tracking-wider mb-2">
            Name <span className="text-spa-gold">*</span>
          </label>
          <input
            type="text"
            value={form.name}
            onChange={set("name")}
            placeholder="Your full name"
            required
            className={inputClass}
          />
        </div>
        <div>
          <label className="block text-xs text-spa-cream/40 uppercase tracking-wider mb-2">
            Email <span className="text-spa-gold">*</span>
          </label>
          <input
            type="email"
            value={form.email}
            onChange={set("email")}
            placeholder="you@example.com"
            required
            className={inputClass}
          />
        </div>
      </div>

      <div>
        <label className="block text-xs text-spa-cream/40 uppercase tracking-wider mb-2">
          Phone
        </label>
        <input
          type="tel"
          value={form.phone}
          onChange={set("phone")}
          placeholder="+62 812 xxx xxxx"
          className={inputClass}
        />
      </div>

      <div>
        <label className="block text-xs text-spa-cream/40 uppercase tracking-wider mb-2">
          Message <span className="text-spa-gold">*</span>
        </label>
        <textarea
          value={form.message}
          onChange={set("message")}
          placeholder="Tell us how we can help you…"
          required
          rows={5}
          className={`${inputClass} resize-none`}
        />
      </div>

      {status === "error" && (
        <p className="text-red-400/80 text-xs">
          Something went wrong — please try again or WhatsApp us directly.
        </p>
      )}

      <button
        type="submit"
        disabled={status === "loading"}
        className="w-full py-3.5 rounded-full btn-gold font-medium text-sm disabled:opacity-60 disabled:cursor-not-allowed transition-opacity flex items-center justify-center gap-2"
      >
        {status === "loading" ? (
          <>
            <svg
              className="w-4 h-4 animate-spin"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle
                className="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                strokeWidth="4"
              />
              <path
                className="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8v8H4z"
              />
            </svg>
            Sending…
          </>
        ) : (
          "Send Message"
        )}
      </button>
    </form>
  );
}
