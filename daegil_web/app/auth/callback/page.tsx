'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { getSupabaseClient } from '@/lib/supabase';

export default function AuthCallback() {
  const router = useRouter();
  const [message, setMessage] = useState('로그인을 확인하는 중이다냥…');
  useEffect(() => {
    const client = getSupabaseClient();
    if (!client) { router.replace('/'); return; }
    const code = new URLSearchParams(window.location.search).get('code');
    if (!code) { setMessage('로그인 링크가 유효하지 않아요.'); return; }
    void client.auth.exchangeCodeForSession(code).then(({ error }) => {
      if (error) { setMessage('로그인을 완료하지 못했어요. 다시 시도해 주세요.'); return; }
      router.replace('/');
    });
  }, [router]);
  return <main className="page"><div className="frame"><div className="card" style={{ marginTop: 48, textAlign: 'center' }}>{message}</div></div></main>;
}
