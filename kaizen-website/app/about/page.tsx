import { Navbar } from "../components/Navbar";
import { Footer } from "../components/Footer";
import { CTASection } from "../components/CTASection";

const team = [
  {
    name: "Riani Kusuma",
    role: "Founder & Head Therapist",
    bio: "Certified massage therapist with 8+ years of experience in luxury wellness centers across Bali and Jakarta.",
    initials: "RK",
  },
  {
    name: "Dinda Ayu",
    role: "Senior Aromatherapist",
    bio: "Specialist in therapeutic essential oils and holistic body treatments with training from the Indonesian Wellness Institute.",
    initials: "DA",
  },
  {
    name: "Hendra Putra",
    role: "Deep Tissue Specialist",
    bio: "Sports massage expert trained in deep tissue and trigger point therapy for athletes and active professionals.",
    initials: "HP",
  },
];

const values = [
  {
    title: "Excellence",
    description: "Every session is delivered with the highest standard of care, using only the finest techniques and products.",
  },
  {
    title: "Comfort",
    description: "We design every experience around your total comfort — in your own home, on your schedule.",
  },
  {
    title: "Kaizen",
    description: "The Japanese philosophy of continuous improvement drives us to always be better for our clients.",
  },
  {
    title: "Trust",
    description: "We build lasting relationships with every client through transparency, professionalism, and genuine care.",
  },
];

export default function AboutPage() {
  return (
    <>
      <Navbar />
      <main className="min-h-screen bg-spa-dark">
        {/* Hero */}
        <section className="relative pt-32 pb-24 px-5 text-center overflow-hidden">
          <div
            className="absolute inset-0 bg-cover bg-center"
            style={{
              backgroundImage:
                "url('https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=1920&q=80')",
            }}
          />
          <div className="absolute inset-0 bg-spa-dark/87" />
          <div className="relative z-10 max-w-3xl mx-auto">
            <p className="section-label mb-4">Our Story</p>
            <h1 className="font-display text-5xl md:text-6xl font-bold text-white mb-6">
              About <span className="gold-text italic">Kaizen</span>
            </h1>
            <p className="text-spa-cream/65 text-lg leading-relaxed">
              Born from a belief that everyone deserves access to genuine, professional
              spa care — not just those who can travel to a wellness center.
            </p>
          </div>
        </section>

        {/* Story section */}
        <section className="py-20 px-5">
          <div className="max-w-6xl mx-auto grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            <div>
              <p className="section-label mb-4">How We Started</p>
              <h2 className="font-display text-4xl font-bold text-spa-cream mb-6">
                Wellness Without Boundaries
              </h2>
              <div className="space-y-4 text-spa-cream/60 text-sm leading-relaxed">
                <p>
                  Kaizen Home Spa was founded in West Java, Indonesia with a simple but
                  powerful idea: bring the full luxury spa experience directly to people&apos;s
                  homes. No traffic, no waiting rooms, no unfamiliar environments.
                </p>
                <p>
                  The name &ldquo;Kaizen&rdquo; — the Japanese concept of continuous improvement —
                  reflects our commitment to always getting better. Every session, every
                  interaction, every product we select is chosen with the intention of
                  making the next experience even better than the last.
                </p>
                <p>
                  Today we serve hundreds of clients across West Java, delivering
                  certified therapeutic treatments that truly heal, restore, and rejuvenate.
                </p>
              </div>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-2 gap-5">
              {[
                { value: "500+", label: "Happy Clients" },
                { value: "4.8★", label: "Average Rating" },
                { value: "15+", label: "Treatments" },
                { value: "3+", label: "Years Experience" },
              ].map((stat) => (
                <div
                  key={stat.label}
                  className="glass-card rounded-2xl p-7 text-center"
                >
                  <div className="font-display text-4xl font-bold text-spa-gold mb-2">
                    {stat.value}
                  </div>
                  <div className="text-spa-cream/50 text-sm">{stat.label}</div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Values */}
        <section className="py-20 px-5 bg-spa-darker">
          <div className="max-w-6xl mx-auto">
            <div className="text-center mb-14">
              <p className="section-label mb-4">What We Stand For</p>
              <h2 className="font-display text-4xl font-bold text-spa-cream">
                Our Core Values
              </h2>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
              {values.map((v, i) => (
                <div key={i} className="glass-card rounded-2xl p-6 hover:border-spa-gold/25 transition-all duration-300">
                  <div className="w-8 h-8 rounded-lg bg-spa-olive/30 flex items-center justify-center mb-4">
                    <div className="w-2 h-2 rounded-full bg-spa-gold" />
                  </div>
                  <h3 className="font-display text-lg font-semibold text-spa-cream mb-2">
                    {v.title}
                  </h3>
                  <p className="text-spa-cream/55 text-sm leading-relaxed">
                    {v.description}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Team */}
        <section className="py-20 px-5">
          <div className="max-w-5xl mx-auto">
            <div className="text-center mb-14">
              <p className="section-label mb-4">Meet the Team</p>
              <h2 className="font-display text-4xl font-bold text-spa-cream">
                Expert Therapists
              </h2>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {team.map((member, i) => (
                <div
                  key={i}
                  className="glass-card rounded-2xl p-7 text-center hover:border-spa-gold/20 transition-all duration-300"
                >
                  <div className="w-16 h-16 rounded-full bg-spa-olive/50 flex items-center justify-center mx-auto mb-4 text-spa-cream text-xl font-display font-bold">
                    {member.initials}
                  </div>
                  <h3 className="font-display text-lg font-semibold text-spa-cream mb-1">
                    {member.name}
                  </h3>
                  <p className="text-spa-gold text-xs mb-4 tracking-wide">
                    {member.role}
                  </p>
                  <p className="text-spa-cream/55 text-sm leading-relaxed">
                    {member.bio}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </section>

        <CTASection />
      </main>
      <Footer />
    </>
  );
}
