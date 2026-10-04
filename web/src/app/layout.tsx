import type { Metadata } from "next";
import { brand } from "@/config/brand";
import "./globals.css";

export const metadata: Metadata = { title: brand.name, description: brand.description };

export default function RootLayout({children}:{readonly children:React.ReactNode}) {
  return <html lang="en"><body>{children}</body></html>;
}
