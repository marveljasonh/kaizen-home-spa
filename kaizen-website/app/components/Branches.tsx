import { supabase } from "@/lib/supabase";

type Branch = {
  id: string | number;
  name: string;
  address: string;
  phone: string;
};

const fallbackBranches: Branch[] = [
  {
    id: 1,
    name: "Bandung Pusat",
    address: "Jl. Asia Afrika No. 158, Bandung 40261",
    phone: "+62 811 2345 6789",
  },
  {
    id: 2,
    name: "Cimahi",
    address: "Jl. Raya Cimahi No. 45, Cimahi 40511",
    phone: "+62 811 3456 7890",
  },
  {
    id: 3,
    name: "Sukabumi",
    address: "Jl. Ahmad Yani No. 22, Sukabumi 43112",
    phone: "+62 811 4567 8901",
  },
];

function toWhatsAppHref(phone: string) {
  const digits = phone.replace(/[^0-9]/g, "");
  const normalized = digits.startsWith("0") ? "62" + digits.slice(1) : digits;
  return `https://wa.me/${normalized}`;
}

async function getBranches(): Promise<Branch[]> {
  try {
    const { data, error } = await supabase
      .from("branches")
      .select("id, name, address, phone");
    if (!error && data && data.length > 0) return data as Branch[];
  } catch {}
  return fallbackBranches;
}

export async function Branches() {
  const branches = await getBranches();

  return (
    <section className="py-20 px-5 bg-spa-dark">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <p className="section-label mb-4">Find Us</p>
          <h2 className="font-display text-4xl md:text-5xl font-bold text-spa-cream">
            Our <span className="gold-text italic">Locations</span>
          </h2>
        </div>

        {/* Cards — horizontal scroll on mobile, grid on desktop */}
        <div className="flex gap-5 overflow-x-auto pb-4 md:pb-0 md:grid md:grid-cols-3 md:overflow-visible snap-x snap-mandatory md:snap-none scrollbar-none">
          {branches.map((branch) => (
            <div
              key={branch.id}
              className="glass-card rounded-2xl p-6 flex-shrink-0 w-72 md:w-auto snap-start hover:border-spa-gold/25 transition-all duration-300 group"
            >
              {/* Pin icon + name */}
              <div className="flex items-start gap-3 mb-4">
                <div className="w-9 h-9 rounded-xl bg-spa-olive/30 flex items-center justify-center shrink-0 mt-0.5 group-hover:bg-spa-gold/12 transition-colors">
                  <svg
                    className="w-4 h-4 text-spa-gold"
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
                </div>
                <div>
                  <h3 className="font-display text-lg font-semibold text-spa-cream group-hover:text-spa-gold transition-colors">
                    {branch.name}
                  </h3>
                  <p className="text-spa-cream/50 text-xs mt-1 leading-relaxed">
                    {branch.address}
                  </p>
                </div>
              </div>

              {/* Divider */}
              <div className="h-px bg-white/6 mb-4" />

              {/* Phone + WhatsApp */}
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 text-spa-cream/50 text-sm">
                  <svg
                    className="w-3.5 h-3.5 text-spa-gold/60 shrink-0"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={1.5}
                      d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
                    />
                  </svg>
                  <span>{branch.phone}</span>
                </div>

                <a
                  href={toWhatsAppHref(branch.phone)}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-full border border-[#25D366]/30 text-[#25D366]/80 text-xs font-medium hover:border-[#25D366]/60 hover:text-[#25D366] hover:bg-[#25D366]/8 transition-all duration-200"
                >
                  <svg className="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z" />
                  </svg>
                  WhatsApp
                </a>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
