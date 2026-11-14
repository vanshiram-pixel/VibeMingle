import type { Metadata } from "next";
import type { ReactNode } from "react";
import "./globals.css";

export const metadata: Metadata = {
  title: { default: "VibeMingle — Connect Beyond Borders", template: "%s | VibeMingle" },
  description: "Meet people and connect beyond borders with VibeMingle.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return <html lang="en"><body>{children}</body></html>;
}