import { Navbar } from "../components/Navbar";
import { Footer } from "../components/Footer";
import { EventsClient } from "../components/EventsClient";
import type { SpaEvent } from "../components/EventsClient";
import { supabase } from "@/lib/supabase";

async function getEvents(): Promise<SpaEvent[]> {
  try {
    const { data, error } = await supabase
      .from("events")
      .select("*")
      .eq("is_active", true)
      .order("event_date", { ascending: true });
    if (!error && data) return data as SpaEvent[];
  } catch {}
  return [];
}

export default async function EventsPage() {
  const events = await getEvents();

  return (
    <>
      <Navbar />
      <main className="min-h-screen bg-spa-dark">
        {/* Hero */}
        <section
          className="relative pt-32 pb-24 px-5 text-center overflow-hidden"
          style={{
            backgroundImage:
              "url('https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1920&q=80')",
            backgroundSize: "cover",
            backgroundPosition: "center 40%",
          }}
        >
          <div className="absolute inset-0 bg-spa-dark/85" />
          <div className="relative z-10">
            <p className="section-label mb-4">Experiences & Partnerships</p>
            <h1 className="font-display text-5xl md:text-6xl font-bold text-white mb-5">
              Events &{" "}
              <span className="gold-text italic">Collaboration</span>
            </h1>
            <p className="text-spa-cream/60 max-w-xl mx-auto text-base leading-relaxed">
              Partner with us for unforgettable wellness experiences
            </p>
          </div>
        </section>

        <EventsClient events={events} />
      </main>
      <Footer />
    </>
  );
}
