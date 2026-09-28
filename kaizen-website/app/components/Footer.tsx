import Link from "next/link";
import { getContent } from "@/lib/content";

function LeafIcon() {
  return (
    <svg viewBox="0 0 32 32" className="w-6 h-6" fill="none">
      <path
        d="M16 3C9 3 4 11 4 11s3 3 6 3c1.5 0 2.8-.5 3.8-1.4C14.8 13.5 16 14 17 14s2.2-.5 3.2-1.4C21.2 13.5 22.5 14 24 14c3 0 6-3 6-3S23 3 16 3z"
        fill="#C9A96E"
      />
      <path d="M16 14v14" stroke="#C9A96E" strokeWidth="1.5" strokeLinecap="round" />
    </svg>
  );
}

const quickLinks = [
  { href: "/", label: "Home" },
  { href: "/services", label: "Services" },
  { href: "/about", label: "About Us" },
  { href: "/pricing", label: "Pricing" },
  { href: "/order", label: "Book Now" },
];

const accountLinks = [
  { href: "/login", label: "Sign In" },
  { href: "/register", label: "Create Account" },
  { href: "/dashboard", label: "My Bookings" },
];

export async function Footer() {
  const content = await getContent();

  const tagline =
    content.footer_tagline ||
    "Premium home spa service in West Java, Indonesia. We bring the luxury of a professional spa directly to your home.";
  const address = content.footer_address || "West Java, Indonesia";
  const phone = content.footer_phone || "+62 812 3456 7890";
  const email = content.footer_email || "hello@kaizenhomespa.id";
  const copyright = content.footer_copyright || "© 2024 Kaizen Home Spa. All rights reserved.";

  return (
    <footer className="bg-spa-deepest border-t border-white/5 pt-16 pb-8 px-5">
      <div className="max-w-7xl mx-auto">
        <div className="grid grid-cols-1 md:grid-cols-12 gap-10 mb-14">
          {/* Brand column */}
          <div className="md:col-span-5">
            <Link href="/" className="flex items-center gap-2.5 mb-5 group w-fit">
              <LeafIcon />
              <span className="font-display text-xl font-semibold text-spa-cream group-hover:text-spa-gold transition-colors">
                {content.site_name || "Kaizen Home Spa"}
              </span>
            </Link>
            <p className="text-spa-cream/45 text-sm leading-relaxed max-w-xs mb-6">
              {tagline}
            </p>
            {/* Social links */}
            <div className="flex gap-2.5">
              <a
                href={content.social_instagram || "#"}
                className="w-9 h-9 rounded-full border border-white/10 flex items-center justify-center text-spa-cream/40 hover:border-spa-gold/40 hover:text-spa-gold transition-all duration-300"
                aria-label="Instagram"
              >
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z" />
                </svg>
              </a>
              <a
                href={content.social_whatsapp || "#"}
                className="w-9 h-9 rounded-full border border-white/10 flex items-center justify-center text-spa-cream/40 hover:border-spa-gold/40 hover:text-spa-gold transition-all duration-300"
                aria-label="WhatsApp"
              >
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z" />
                </svg>
              </a>
              <a
                href={content.social_tiktok || "#"}
                className="w-9 h-9 rounded-full border border-white/10 flex items-center justify-center text-spa-cream/40 hover:border-spa-gold/40 hover:text-spa-gold transition-all duration-300"
                aria-label="TikTok"
              >
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z" />
                </svg>
              </a>
            </div>
          </div>

          {/* Quick links */}
          <div className="md:col-span-3">
            <h4 className="text-spa-cream text-sm font-semibold mb-5 tracking-wide">Quick Links</h4>
            <ul className="space-y-3">
              {quickLinks.map((link) => (
                <li key={link.href}>
                  <Link href={link.href} className="text-spa-cream/45 text-sm hover:text-spa-gold transition-colors">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Account */}
          <div className="md:col-span-2">
            <h4 className="text-spa-cream text-sm font-semibold mb-5 tracking-wide">Account</h4>
            <ul className="space-y-3">
              {accountLinks.map((link) => (
                <li key={link.href}>
                  <Link href={link.href} className="text-spa-cream/45 text-sm hover:text-spa-gold transition-colors">
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Contact */}
          <div className="md:col-span-2">
            <h4 className="text-spa-cream text-sm font-semibold mb-5 tracking-wide">Contact</h4>
            <ul className="space-y-3.5">
              <li className="flex items-start gap-2.5">
                <svg className="w-4 h-4 mt-0.5 text-spa-gold/50 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
                <span className="text-spa-cream/45 text-sm">{address}</span>
              </li>
              <li className="flex items-start gap-2.5">
                <svg className="w-4 h-4 mt-0.5 text-spa-gold/50 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                </svg>
                <span className="text-spa-cream/45 text-sm">{phone}</span>
              </li>
              <li className="flex items-start gap-2.5">
                <svg className="w-4 h-4 mt-0.5 text-spa-gold/50 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                </svg>
                <span className="text-spa-cream/45 text-sm">{email}</span>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="border-t border-white/6 pt-7 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-spa-cream/25 text-xs">{copyright}</p>
          <div className="flex gap-5 text-spa-cream/25 text-xs">
            <a href="#" className="hover:text-spa-cream/50 transition-colors">Privacy Policy</a>
            <a href="#" className="hover:text-spa-cream/50 transition-colors">Terms of Service</a>
          </div>
        </div>
      </div>
    </footer>
  );
}
