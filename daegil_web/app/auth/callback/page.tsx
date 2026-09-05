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
    let timeoutId: number | undefined;
    const finishLogin = async () => {
      const params = new URLSearchParams(window.location.search);
      const callbackError = params.get('error_description') ?? params.get('error');
      if (callbackError) {
        setMessage('Google 로그인이 취소되었거나 만료되었어요. 다시 시도해 주세요.');
        return;
      }
      const code = params.get('code');
      if (!code) {
        setMessage('로그인 링크가 유효하지 않아요. 다시 시도해 주세요.');
        return;
      }
      try {
        const result = await Promise.race([
          client.auth.exchangeCodeForSession(code),
          new Promise<never>((_, reject) => {
            timeoutId = window.setTimeout(() => reject(new Error('AUTH_CALLBACK_TIMEOUT')), 15_000);
          }),
        ]);
        if (result.error) {
          setMessage('로그인을 완료하지 못했어요. 다시 시도해 주세요.');
          return;
        }
        router.replace('/');
      } catch {
        setMessage('로그인 확인이 지연되고 있어요. 로그인 화면으로 돌아가 다시 시도해 주세요.');
      } finally {
        if (timeoutId !== undefined) window.clearTimeout(timeoutId);
      }
    };
    void finishLogin();
  }, [router]);
  return <main className="page"><div className="frame"><div className="card" style={{ marginTop: 48, textAlign: 'center' }}><p role="status">{message}</p>{message !== '로그인을 확인하는 중이다냥…' && <a className="button button-secondary" style={{ display: 'block', marginTop: 16 }} href="/?login=retry">로그인 화면으로 돌아가기</a>}</div></div></main>;
}
