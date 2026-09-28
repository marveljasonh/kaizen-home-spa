import { Navbar } from "../components/Navbar";
import { Footer } from "../components/Footer";
import { ContactForm } from "../components/ContactForm";
import { supabase } from "@/lib/supabase";

type Branch = {
  id: string | number;
  name: string;
  address: string | null;
  phone: string | null;
  operating_hours?: string | null;
};

const fallbackBranches: Branch[] = [
  {
    id: 1,
    name: "Bandung Pusat",
    address: "Jl. Asia Afrika No. 158, Bandung 40261",
    phone: "+62 811 2345 6789",
    operating_hours: "09:00 – 22:00 WIB",
  },
  {
    id: 2,
    name: "Cimahi",
    address: "Jl. Raya Cimahi No. 45, Cimahi 40511",
    phone: "+62 811 3456 7890",
    operating_hours: "09:00 – 22:00 WIB",
  },
  {
    id: 3,
    name: "Sukabumi",
    address: "Jl. Ahmad Yani No. 22, Sukabumi 43112",
    phone: "+62 811 4567 8901",
    operating_hours: "09:00 – 22:00 WIB",
  },
];

function toWhatsAppHref(phone: string | null | undefined) {
  if (!phone) return "#";
  const digits = phone.replace(/[^0-9]/g, "");
  const normalized = digits.startsWith("0") ? "62" + digits.slice(1) : digits;
  return `https://wa.me/${normalized}`;
}

function toMapsHref(address: string | null | undefined) {
  if (!address) return "#";
  return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(address)}`;
}

async function getBranches(): Promise<Branch[]> {
  try {
    const { data, error } = await supabase
      .from("branches")
      .select("*");
    if (!error && data && data.length > 0) return data as Branch[];
  } catch {}
  return fallbackBranches;
}

export default async function ContactPage() {
  const branches = await getBranches();

  return (
    <>
      <Navbar />
      <main className="min-h-screen bg-spa-dark">
        {/* Hero */}
        <section
          className="relative pt-32 pb-20 px-5 text-center overflow-hidden"
          style={{
            backgroundImage:
              "url('https://images.unsplash.com/photo-1560066984-138dadb4c035?w=1920&q=80')",
            backgroundSize: "cover",
            backgroundPosition: "center",
          }}
        >
          <div className="absolute inset-0 bg-spa-dark/85" />
          <div className="relative z-10">
            <p className="section-label mb-4">We&apos;d Love to Hear From You</p>
            <h1 className="font-display text-5xl md:text-6xl font-bold text-white mb-5">
              Contact <span className="gold-text italic">Us</span>
            </h1>
            <p className="text-spa-cream/60 max-w-xl mx-auto text-base leading-relaxed">
              Find us at your nearest location or send us a message below
            </p>
          </div>
        </section>

        {/* ── Branches ───────────────────────────────────────── */}
        <section className="py-20 px-5">
          <div className="max-w-7xl mx-auto">
            <div className="text-center mb-12">
              <p className="section-label mb-4">Find Us</p>
              <h2 className="font-display text-4xl md:text-5xl font-bold text-spa-cream">
                Our <span className="gold-text italic">Locations</span>
              </h2>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              {branches.map((branch) => (
                <div
                  key={branch.id}
                  className="glass-card glass-card-hover rounded-2xl p-7 group"
                >
                  {/* Name */}
                  <h3 className="font-display text-xl font-semibold text-spa-gold mb-4 group-hover:text-spa-gold-light transition-colors">
                    {branch.name}
                  </h3>

                  <div className="space-y-3 mb-6">
                    {/* Address */}
                    <div className="flex items-start gap-3">
                      <div className="w-7 h-7 rounded-lg bg-spa-olive/30 flex items-center justify-center shrink-0 mt-0.5">
                        <svg className="w-3.5 h-3.5 text-spa-gold" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                        </svg>
                      </div>
                      <p className="text-spa-cream/60 text-sm leading-relaxed pt-0.5">
                        {branch.address}
                      </p>
                    </div>

                    {/* Phone */}
                    <div className="flex items-center gap-3">
                      <div className="w-7 h-7 rounded-lg bg-spa-olive/30 flex items-center justify-center shrink-0">
                        <svg className="w-3.5 h-3.5 text-spa-gold" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                        </svg>
                      </div>
                      <a
                        href={toWhatsAppHref(branch.phone)}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-spa-cream/60 text-sm hover:text-spa-gold transition-colors"
                      >
                        {branch.phone}
                      </a>
                    </div>

                    {/* Operating hours */}
                    {branch.operating_hours && (
                      <div className="flex items-center gap-3">
                        <div className="w-7 h-7 rounded-lg bg-spa-olive/30 flex items-center justify-center shrink-0">
                          <svg className="w-3.5 h-3.5 text-spa-gold" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                          </svg>
                        </div>
                        <p className="text-spa-cream/60 text-sm">{branch.operating_hours}</p>
                      </div>
                    )}
                  </div>

                  {/* Action row */}
                  <div className="flex items-center gap-3">
                    <a
                      href={toMapsHref(branch.address)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex-1 text-center py-2.5 rounded-full border border-spa-gold/30 text-spa-gold/80 text-xs font-medium hover:border-spa-gold/60 hover:text-spa-gold hover:bg-spa-gold/5 transition-all duration-200"
                    >
                      Open in Maps
                    </a>
                    <a
                      href={toWhatsAppHref(branch.phone)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex-1 text-center py-2.5 rounded-full border border-[#25D366]/30 text-[#25D366]/80 text-xs font-medium hover:border-[#25D366]/60 hover:text-[#25D366] hover:bg-[#25D366]/5 transition-all duration-200"
                    >
                      WhatsApp
                    </a>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ── Contact form + general info ──────────────────── */}
        <section className="py-20 px-5 bg-spa-darker">
          <div className="max-w-7xl mx-auto">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-14">
              {/* Form */}
              <div>
                <p className="section-label mb-4">Send a Message</p>
                <h2 className="font-display text-3xl md:text-4xl font-bold text-spa-cream mb-2">
                  We&apos;re Here to{" "}
                  <span className="gold-text italic">Help</span>
                </h2>
                <p className="text-spa-cream/45 text-sm mb-8 leading-relaxed">
                  Have a question, want to book a group session, or explore a
                  partnership? Drop us a message and we&apos;ll respond within 24
                  hours.
                </p>
                <div className="glass-card rounded-2xl p-7">
                  <ContactForm />
                </div>
              </div>

              {/* General info */}
              <div className="flex flex-col gap-6">
                <div>
                  <p className="section-label mb-4">Get in Touch</p>
                  <h2 className="font-display text-3xl md:text-4xl font-bold text-spa-cream mb-8">
                    Connect <span className="gold-text italic">With Us</span>
                  </h2>
                </div>

                {[
                  {
                    label: "WhatsApp",
                    value: "+62 812 3456 7890",
                    href: "https://wa.me/6281234567890",
                    icon: (
                      <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z" />
                      </svg>
                    ),
                    color: "#25D366",
                  },
                  {
                    label: "Email",
                    value: "hello@kaizenhomaspa.com",
                    href: "mailto:hello@kaizenhomaspa.com",
                    icon: (
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                      </svg>
                    ),
                    color: "#C9A96E",
                  },
                  {
                    label: "Instagram",
                    value: "@kaizenhomaspa",
                    href: "https://instagram.com/kaizenhomaspa",
                    icon: (
                      <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z" />
                      </svg>
                    ),
                    color: "#E1306C",
                  },
                ].map((item) => (
                  <a
                    key={item.label}
                    href={item.href}
                    target={item.href.startsWith("mailto") ? undefined : "_blank"}
                    rel="noopener noreferrer"
                    className="glass-card glass-card-hover rounded-2xl p-5 flex items-center gap-4 group"
                  >
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 transition-transform group-hover:scale-110"
                      style={{ background: `${item.color}20`, color: item.color }}
                    >
                      {item.icon}
                    </div>
                    <div>
                      <p className="text-spa-cream/35 text-xs uppercase tracking-wider mb-0.5">
                        {item.label}
                      </p>
                      <p className="text-spa-cream text-sm font-medium group-hover:text-spa-gold transition-colors">
                        {item.value}
                      </p>
                    </div>
                    <svg
                      className="w-4 h-4 text-spa-cream/20 ml-auto group-hover:text-spa-gold/50 transition-colors"
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                    </svg>
                  </a>
                ))}

                {/* Hours card */}
                <div className="glass-card rounded-2xl p-5">
                  <div className="flex items-center gap-3 mb-4">
                    <div className="w-10 h-10 rounded-xl bg-spa-gold/15 flex items-center justify-center shrink-0">
                      <svg className="w-4 h-4 text-spa-gold" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                    </div>
                    <p className="text-spa-cream text-sm font-medium">Operating Hours</p>
                  </div>
                  <div className="space-y-2">
                    {[
                      { day: "Monday – Friday", hours: "09:00 – 22:00 WIB" },
                      { day: "Saturday – Sunday", hours: "08:00 – 22:00 WIB" },
                      { day: "Public Holidays", hours: "10:00 – 21:00 WIB" },
                    ].map((row) => (
                      <div
                        key={row.day}
                        className="flex items-center justify-between text-sm"
                      >
                        <span className="text-spa-cream/45">{row.day}</span>
                        <span className="text-spa-cream/70">{row.hours}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </>
  );
}
