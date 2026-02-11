import './globals.css';
import SuiProvider from '../providers/SuiProvider';
import { Quicksand, Space_Mono } from 'next/font/google';

const quicksand = Quicksand({ 
  subsets: ['latin'],
  variable: '--font-heading',
  display: 'swap',
});

const spaceMono = Space_Mono({ 
  subsets: ['latin'],
  weight: ['400', '700'],
  variable: '--font-mono',
  display: 'swap',
});

// eslint-disable-next-line react-refresh/only-export-components
export const metadata = {
  title: 'Magic Swap',
  description: 'Your bridge to digital fortune!',
};

export default function RootLayout({ children }) {
  return (
    <html lang="en" className={`${quicksand.variable} ${spaceMono.variable}`}>
      <body>
        <SuiProvider>
          {children}
        </SuiProvider>
      </body>
    </html>
  );
}
