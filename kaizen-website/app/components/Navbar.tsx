"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";

function LeafIcon() {
  return (
    <svg viewBox="0 0 32 32" className="w-7 h-7" fill="none">
      <path
        d="M16 3C9 3 4 11 4 11s3 3 6 3c1.5 0 2.8-.5 3.8-1.4C14.8 13.5 16 14 17 14s2.2-.5 3.2-1.4C21.2 13.5 22.5 14 24 14c3 0 6-3 6-3S23 3 16 3z"
        fill="#C9A96E"
      />
      <path
        d="M16 18c-3.5 0-6 2-7 4.5C10 26 13 28.5 16 28.5s6-2.5 7-6C22 20 19.5 18 16 18z"
        fill="#C9A96E"
        opacity="0.7"
      />
      <path
        d="M16 14v14"
        stroke="#C9A96E"
        strokeWidth="1.5"
        strokeLinecap="round"
      />
    </svg>
  );
}

const navLinks = [
  { href: "/", label: "Home" },
  { href: "/services", label: "Massage & Spa" },
  { href: "/events", label: "Events" },
  { href: "/about", label: "About Us" },
  { href: "/contact", label: "Contact" },
];

export function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const pathname = usePathname();

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 60);
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500 ${
        scrolled || menuOpen
          ? "bg-spa-dark/95 backdrop-blur-md shadow-[0_4px_30px_rgba(0,0,0,0.4)]"
          : "bg-transparent"
      }`}
    >
      <div className="max-w-7xl mx-auto px-5 sm:px-8">
        <div className="flex items-center justify-between h-20">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2.5 group">
            <LeafIcon />
            <div className="flex flex-col leading-none">
              <span className="font-display text-lg font-semibold text-spa-cream tracking-wide group-hover:text-spa-gold transition-colors">
                Kaizen Home Spa
              </span>
              <span className="text-[9px] tracking-[0.2em] text-spa-gold/60 uppercase font-sans">
                West Java
              </span>
            </div>
          </Link>

          {/* Desktop nav */}
          <div className="hidden md:flex items-center gap-8">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                className={`text-sm font-medium tracking-wide transition-all duration-200 hover:text-spa-gold relative group ${
                  pathname === link.href
                    ? "text-spa-gold"
                    : "text-spa-cream/75"
                }`}
              >
                {link.label}
                <span
                  className={`absolute -bottom-1 left-0 h-px bg-spa-gold transition-all duration-300 ${
                    pathname === link.href ? "w-full" : "w-0 group-hover:w-full"
                  }`}
                />
              </Link>
            ))}
          </div>

          {/* Desktop CTA */}
          <div className="hidden md:flex items-center gap-5">
            <Link
              href="/login"
              className="text-sm text-spa-cream/60 hover:text-spa-cream transition-colors"
            >
              Sign In
            </Link>
            <Link
              href="/order"
              className="px-5 py-2.5 rounded-full btn-olive text-sm font-medium border border-spa-gold/25 hover:border-spa-gold/50"
            >
              Order Here
            </Link>
          </div>

          {/* Mobile toggle */}
          <button
            className="md:hidden p-2 text-spa-cream/70 hover:text-spa-cream transition-colors"
            onClick={() => setMenuOpen(!menuOpen)}
            aria-label="Toggle menu"
          >
            <svg
              className="w-6 h-6"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              {menuOpen ? (
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={1.5}
                  d="M6 18L18 6M6 6l12 12"
                />
              ) : (
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={1.5}
                  d="M4 6h16M4 12h16M4 18h16"
                />
              )}
            </svg>
          </button>
        </div>

        {/* Mobile menu */}
        {menuOpen && (
          <div className="md:hidden pb-6 border-t border-white/8">
            <div className="pt-4 flex flex-col gap-1">
              {navLinks.map((link) => (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`py-3 px-2 text-sm font-medium transition-colors ${
                    pathname === link.href
                      ? "text-spa-gold"
                      : "text-spa-cream/70 hover:text-spa-cream"
                  }`}
                  onClick={() => setMenuOpen(false)}
                >
                  {link.label}
                </Link>
              ))}
              <div className="flex gap-3 mt-4">
                <Link
                  href="/login"
                  className="flex-1 text-center py-2.5 rounded-full border border-white/15 text-spa-cream/70 text-sm hover:border-white/30 transition-colors"
                  onClick={() => setMenuOpen(false)}
                >
                  Sign In
                </Link>
                <Link
                  href="/order"
                  className="flex-1 text-center py-2.5 rounded-full btn-olive text-sm font-medium border border-spa-gold/25"
                  onClick={() => setMenuOpen(false)}
                >
                  Order Here
                </Link>
              </div>
            </div>
          </div>
        )}
      </div>
    </nav>
  );
}
