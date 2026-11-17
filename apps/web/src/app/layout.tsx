import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "VibeMingle — Meet. Chat. Connect.", description: "Meet new people, build friendships, and connect through private chats and calls." };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en"><body>{children}</body></html>; }