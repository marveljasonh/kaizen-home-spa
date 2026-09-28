---
name: project-overview
description: Core stack, design system, pages, and Supabase config for Kaizen Home Spa website
metadata:
  type: project
---

# Kaizen Home Spa Website

Premium home spa service landing site based in West Java, Indonesia.

## Tech Stack
- **Next.js 16.2.9** (App Router, Turbopack default, params/cookies fully async)
- **React 19** with TypeScript
- **Tailwind CSS v4** (CSS-first config via `@theme` in globals.css)
- **Framer Motion** — animations (client components only)
- **@supabase/supabase-js** — data fetching + auth
- Dev server runs on port 3001 (3000 taken by another process)

## Design System (globals.css `@theme`)
- `--color-spa-dark: #1C1C1A` — main background
- `--color-spa-darker: #1A1A14` — alternate section bg
- `--color-spa-deepest: #141412` — footer bg
- `--color-spa-olive: #4E523B` — primary CTA color
- `--color-spa-gold: #C9A96E` — accent/highlight
- `--color-spa-cream: #FAF7F2` — body text
- `--font-display: var(--font-cormorant)` — Cormorant Garamond for headings
- CSS utility classes: `.glass-card`, `.glass-card-hover`, `.gold-text`, `.btn-olive`, `.btn-gold`, `.section-label`, `.animate-ticker`

## Supabase
- URL: `https://zxiofkulrvjtpusgzoei.supabase.co`
- Anon key in `.env.local`
- `supabase` client: `lib/supabase.ts`
- Tables used: `treatments` (may have varied column names), `bookings`
- Auth: email/password via `supabase.auth.signInWithPassword` / `signUp`

## Pages
| Route | File | Type |
|---|---|---|
| `/` | app/page.tsx | Server |
| `/services` | app/services/page.tsx | Server (async) |
| `/about` | app/about/page.tsx | Server |
| `/pricing` | app/pricing/page.tsx | Server |
| `/login` | app/login/page.tsx | Client |
| `/register` | app/register/page.tsx | Client |
| `/order` | app/order/page.tsx | Client (3-step flow) |
| `/dashboard` | app/dashboard/page.tsx | Client (auth-gated) |

## Components (app/components/)
- `Navbar.tsx` — sticky, blur on scroll, mobile menu, gold underline active links
- `Hero.tsx` — full-screen bg image, animated with Framer Motion, stats row
- `Ticker.tsx` — CSS animated scrolling banner
- `ServicesPreview.tsx` — Server component, fetches from Supabase with fallback
- `WhyChooseUs.tsx` — 4 animated feature cards
- `Testimonials.tsx` — 3 glass card testimonials
- `CTASection.tsx` — Full-bleed bg image CTA
- `Footer.tsx` — Brand, links, contact, social icons

## CMS Content System

`website_content` table: rows of `{ key: string, value: string }`.

**Data flow:**
- `lib/supabase/server.ts` — async `createClient()` wrapper (anon key, no cookie handling needed)
- `lib/content.ts` — `getContent()` fetches all rows, returns `Record<string, string>`
- `app/page.tsx` — fetches once, passes `content` prop to client components
- `Footer.tsx` — server component, calls `getContent()` directly (used on all pages)
- `CTASection.tsx` — `content` prop is optional (default `{}`), used on /about without prop

**Content keys used:**
| Key | Component | Fallback |
|---|---|---|
| `hero_headline` | Hero | "Kaizen Home Spa" |
| `hero_subtext` | Hero | long description |
| `hero_cta` | Hero | "Book Our Massage" |
| `hero_cta_secondary` | Hero | "Explore Treatments" |
| `hero_rating_text` | Hero | "Excellent — 4.8 out of 5" |
| `hero_location` | Hero | "West Java, Indonesia" |
| `stat_clients_value/label` | Hero | "500+" / "Happy Clients" |
| `stat_treatments_value/label` | Hero | "15+" / "Treatments" |
| `stat_rating_value/label` | Hero | "4.8★" / "Average Rating" |
| `stat_years_value/label` | Hero | "3+" / "Years Experience" |
| `ticker_text` | Ticker | pipe-separated default items |
| `why_us_section_title` | WhyChooseUs | "The Kaizen Difference" |
| `why_us_section_subtitle` | WhyChooseUs | full subtitle |
| `why_us_1_title` … `why_us_4_title` | WhyChooseUs | feature titles |
| `why_us_1_desc` … `why_us_4_desc` | WhyChooseUs | feature descriptions |
| `testimonials_title` | Testimonials | "What Our Clients Say" |
| `testimonials_rating_text` | Testimonials | "4.8 average from 200+ reviews" |
| `cta_headline` | CTASection | "Ready to Relax?" |
| `cta_subtext` | CTASection | long description |
| `cta_button_text` | CTASection | "Book Now" |
| `cta_secondary_text` | CTASection | "See Treatments" |
| `cta_trust_1/2/3` | CTASection | trust badges |
| `footer_tagline` | Footer | brand description |
| `footer_address` | Footer | "West Java, Indonesia" |
| `footer_phone` | Footer | "+62 812 3456 7890" |
| `footer_email` | Footer | "hello@kaizenhomespa.id" |
| `footer_copyright` | Footer | "© 2024 Kaizen Home Spa..." |
| `site_name` | Footer | "Kaizen Home Spa" |
| `social_instagram/whatsapp/tiktok` | Footer | "#" (href) |

## Known Supabase schema notes
- `treatments` table may not have `starting_price` column (could be `price` or null)
- Always use null-safe formatPrice: `if (!price) return "Hubungi kami"`
- Map Supabase rows defensively: `row.starting_price ?? row.price ?? null`

**Why:** The live Supabase project had treatments rows but null prices; this caused runtime 500 errors on first load.
**How to apply:** Always null-check prices when reading from Supabase treatments table.
