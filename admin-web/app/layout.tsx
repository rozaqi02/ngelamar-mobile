import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Ngelamar Admin',
  description: 'Console admin privat untuk Ngelamar',
  robots: { index: false, follow: false },
}

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="id">
      <body>{children}</body>
    </html>
  )
}
