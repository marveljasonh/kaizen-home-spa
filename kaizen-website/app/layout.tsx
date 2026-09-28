import type { Metadata } from "next";
import { Geist } from "next/font/google";
import { Cormorant_Garamond } from "next/font/google";
import "./globals.css";

const geist = Geist({
  variable: "--font-geist",
  subsets: ["latin"],
});

const cormorant = Cormorant_Garamond({
  variable: "--font-cormorant",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

export const metadata: Metadata = {
  title: "Kaizen Home Spa — Premium Home Spa Service in West Java",
  description:
    "Professional home spa service in West Java, Indonesia. Expert therapists, premium products, and total relaxation delivered to your doorstep.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${geist.variable} ${cormorant.variable}`}>
      <body className="min-h-screen bg-spa-dark text-spa-cream antialiased">
        {children}
      </body>
    </html>
  );
}
