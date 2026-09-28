import { getContent } from "@/lib/content";
import { Navbar } from "./components/Navbar";
import { Hero } from "./components/Hero";
import { Ticker } from "./components/Ticker";
import { Branches } from "./components/Branches";
import { ServicesPreview } from "./components/ServicesPreview";
import { WhyChooseUs } from "./components/WhyChooseUs";
import { Testimonials } from "./components/Testimonials";
import { CTASection } from "./components/CTASection";
import { Footer } from "./components/Footer";

export default async function HomePage() {
  const content = await getContent();

  return (
    <>
      <Navbar />
      <main>
        <Hero content={content} />
        <Ticker content={content} />
        <Branches />
        <ServicesPreview />
        <WhyChooseUs content={content} />
        <Testimonials content={content} />
        <CTASection content={content} />
      </main>
      <Footer />
    </>
  );
}
