import type { Metadata } from 'next';
import Script from 'next/script';
import './globals.css';

export const metadata: Metadata = {
  title: '대길 — 오늘의 운세를 알려주는 고양이',
  description: '고양이 대길이 출생정보를 바탕으로 오늘의 운세를 알려드려요.',
  metadataBase: new URL('https://daegil.allinfoworld119.com'),
  openGraph: {
    title: '대길 — 오늘의 운세를 알려주는 고양이',
    description: '오늘의 운세를 대길이에게 물어보세요.',
    type: 'website',
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ko">
      <body>{children}</body>
      <Script
        src="https://securepubads.g.doubleclick.net/tag/js/gpt.js"
        strategy="afterInteractive"
      />
    </html>
  );
}
