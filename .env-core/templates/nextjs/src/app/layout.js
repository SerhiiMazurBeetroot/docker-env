import '@/styles/global.scss'

import { Poppins } from 'next/font/google'
import { Providers } from '@/components/UI/ThemeChanger/providers'

import Header from '@/components/Layouts/Header'
import Footer from '@/components/Layouts/Footer'

const poppins = Poppins({
  subsets: ['latin'],
  weight: ['100', '200', '300', '400', '500', '600', '700', '800', '900'],
  variable: '--font-poppins'
})

export const metadata = {}

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body className={poppins.className}>
        <Providers>
          <Header />
          {children}
          <Footer />
        </Providers>
      </body>
    </html>
  )
}
