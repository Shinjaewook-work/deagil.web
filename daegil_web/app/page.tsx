'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { getSupabaseClient, getWebRedirectUrl } from '@/lib/supabase';
import { completePendingRegistration, isRegistrationComplete, withAuthDeadline } from '@/lib/registration';

type View = 'landing' | 'auth' | 'profile' | 'today' | 'result';

type AppState = {
  gate?: string;
  fortune_state?: string;
  fortune_date?: string;
  expires_at?: string;
  birth_profile_exists?: boolean;
  available_pass_count?: number;
  active_pass_count?: number;
  can_use_pass?: boolean;
  can_prepare_rewarded_ad?: boolean;
  fortune_payload?: FortunePayload | null;
};

type FortunePayload = {
  headline?: string;
  ratings?: { overall?: number; money?: number; love?: number; career?: number };
  overall?: string[];
  money?: string[];
  love?: string[];
  career?: string[];
  recommended_actions?: string[];
  avoid_actions?: string[];
  lucky?: { number?: number; color?: string; time?: string; keyword?: string };
};

type Requirement = { id: string; title: string; required: boolean };

const DEMO_RESULT: FortunePayload = {
  headline: '오늘은 속도보다 순서를 정하면 흐름이 좋아져요냥.',
  ratings: { overall: 4, money: 3, love: 4, career: 5 },
  overall: [
    '가장 먼저 해야 할 한 가지를 정하면 마음이 가벼워져요냥.',
    '오전에 정리한 일이 오후의 부담을 줄여줄 수 있어요.',
    '작은 약속을 지키는 일이 좋은 흐름을 만들어요냥.',
    '대화에서는 한 번 더 들어보는 편이 좋아요.',
    '저녁에는 오늘의 성과를 짧게 기록해 보세요냥.',
  ],
  money: ['필요한 지출과 미뤄도 되는 지출을 나눠보세요냥.', '충동 결제는 하루만 더 생각해요.', '작은 예산 정리가 도움이 돼요냥.'],
  love: ['부드러운 말 한마디가 오해를 줄여줘요냥.', '답을 재촉하기보다 마음을 확인해 보세요.', '고마움을 표현하기 좋은 날이에요냥.'],
  career: ['중요한 일부터 순서대로 처리하면 성과가 커져요냥.', '초안은 빠르게, 검토는 천천히 해보세요.', '혼자 끌어안지 말고 필요한 도움을 요청해요냥.'],
  recommended_actions: ['할 일 세 가지 적기냥.', '물 한 잔 마시고 깊게 호흡하기.', '미뤄둔 연락 하나 보내기냥.'],
  avoid_actions: ['한꺼번에 너무 많이 시작하기냥.', '확인하지 않고 바로 답장하기.', '늦은 밤 큰 결정을 내리기냥.'],
  lucky: { number: 7, color: '살구색', time: '14:00-16:00', keyword: '정돈' },
};

const DEFAULT_REQUIREMENTS: Requirement[] = [
  { id: 'terms-v1', title: '서비스 이용약관에 동의합니다.', required: true },
  { id: 'ai-processing-v1', title: 'AI 개인화 처리에 동의합니다.', required: true },
  { id: 'privacy-v1', title: '개인정보 활용에 동의합니다.', required: true },
];

function newRequestId() {
  return crypto.randomUUID();
}

function isRealPayload(payload: FortunePayload | null | undefined): payload is FortunePayload {
  return Boolean(payload && payload.headline && payload.overall?.length);
}

export default function DaegilWeb() {
  const supabase = useMemo(() => getSupabaseClient(), []);
  const [view, setView] = useState<View>('landing');
  const [requirements, setRequirements] = useState<Requirement[]>(DEFAULT_REQUIREMENTS);
  const [accepted, setAccepted] = useState<Set<string>>(new Set());
  const [age14, setAge14] = useState(false);
  const [state, setState] = useState<AppState>({});
  const [busy, setBusy] = useState(false);
  const [restoring, setRestoring] = useState(Boolean(supabase));
  const [hasSession, setHasSession] = useState(false);
  const [requirementsReady, setRequirementsReady] = useState(!supabase);
  const [error, setError] = useState('');
  const [demoMode, setDemoMode] = useState(!supabase);
  const [profile, setProfile] = useState({ birthDate: '', city: '', calendar: 'solar', time: '', precision: 'unknown' });

  const loadRequirements = useCallback(async () => {
    if (!supabase) return;
    const { data, error: rpcError } = await withAuthDeadline(supabase.rpc('get_public_registration_requirements'));
    if (rpcError) throw rpcError;
    const documents = (data as { documents?: unknown }).documents;
    if (!Array.isArray(documents)) throw new Error('INVALID_LEGAL_RESPONSE');
    setRequirements(documents.map((item) => {
      const row = item as Record<string, unknown>;
      return { id: String(row.id), title: String(row.title), required: row.required === true || row.required_for_registration === true };
    }));
    setRequirementsReady(true);
  }, [supabase]);

  const loadState = useCallback(async () => {
    if (!supabase) return;
    const { data, error: rpcError } = await withAuthDeadline(supabase.rpc('get_my_app_state'));
    if (rpcError) throw rpcError;
    if (!data || typeof data !== 'object' || typeof data.gate !== 'string') throw new Error('INVALID_APP_STATE');
    setState(data as AppState);
    return data as AppState;
  }, [supabase]);

  const completeRegistrationIfNeeded = useCallback(async () => {
    if (!supabase || typeof window === 'undefined') return;
    await completePendingRegistration(supabase, window.localStorage);
  }, [supabase]);

  useEffect(() => {
    if (!supabase) return;
    let cancelled = false;
    if (new URLSearchParams(window.location.search).get('login') === 'retry') setView('auth');
    void loadRequirements().catch(() => setError('필수 안내를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.'));
    void (async () => {
      try {
        const { data, error: sessionError } = await withAuthDeadline(supabase.auth.getSession());
        if (sessionError) throw sessionError;
        if (cancelled) return;
        setHasSession(Boolean(data.session));
        if (!data.session) return;
        await completeRegistrationIfNeeded();
        const current = await loadState();
        if (cancelled) return;
        if (!isRegistrationComplete(current)) {
          setView('auth');
          setError('필수 동의 내용을 확인하고 가입을 완료해 주세요.');
          return;
        }
        setView(current?.fortune_state === 'UNLOCKED' ? 'result' : 'today');
      } catch {
        if (!cancelled) {
          setView('auth');
          setError('가입 확인을 완료하지 못했어요. 동의 내용을 확인하고 다시 시도해 주세요.');
        }
      } finally {
        if (!cancelled) setRestoring(false);
      }
    })();
    return () => { cancelled = true; };
  }, [completeRegistrationIfNeeded, loadRequirements, loadState, supabase]);

  function toggleRequirement(id: string) {
    setAccepted((current) => {
      const next = new Set(current);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  }

  const canLogin = requirementsReady && age14 && requirements.filter((item) => item.required).every((item) => accepted.has(item.id));

  async function signIn() {
    if (!canLogin || busy || restoring) return;
    setBusy(true); setError('');
    try {
      if (!supabase) { setDemoMode(true); setView('today'); return; }
      window.localStorage.setItem('daegil-web-registration', JSON.stringify({
        age14PlusAttested: age14,
        displayedDocumentIds: requirements.map((item) => item.id),
        acceptedDocumentIds: [...accepted],
      }));
      if (hasSession) {
        await completeRegistrationIfNeeded();
        const current = await loadState();
        if (!isRegistrationComplete(current)) throw new Error('REGISTRATION_GATE_REMAINS');
        setView(current?.fortune_state === 'UNLOCKED' ? 'result' : 'today');
        return;
      }
      const { error: signInError } = await withAuthDeadline(supabase.auth.signInWithOAuth({
        provider: 'google',
        options: { redirectTo: getWebRedirectUrl() },
      }));
      if (signInError) throw signInError;
    } catch {
      setError('로그인 또는 가입 확인을 완료하지 못했어요. 잠시 후 다시 시도해 주세요.');
    } finally { setBusy(false); }
  }

  async function saveProfile(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault(); setBusy(true); setError('');
    try {
      if (profile.precision !== 'unknown' && !profile.time) throw new Error('출생 시간을 입력하거나 모름을 선택해 주세요.');
      if (supabase) {
        const { error: rpcError } = await supabase.rpc('upsert_my_birth_profile', {
          payload: {
            birth_date: profile.birthDate,
            calendar_type: profile.calendar,
            is_leap_month: false,
            birth_time: profile.precision === 'unknown' ? null : profile.time,
            birth_time_precision: profile.precision,
            birth_country_code: 'KR',
            birth_city: profile.city,
          },
        });
        if (rpcError) throw rpcError;
        await loadState();
      } else {
        setState({ fortune_state: 'LOCKED', birth_profile_exists: true, can_prepare_rewarded_ad: true, can_use_pass: false, available_pass_count: 0 });
      }
      setView('today');
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : '출생정보를 저장하지 못했어요.');
    } finally { setBusy(false); }
  }

  async function usePass() {
    if (!supabase) { setState({ ...state, fortune_state: 'UNLOCKED', fortune_payload: DEMO_RESULT }); setView('result'); return; }
    setBusy(true); setError('');
    try {
      const response = await supabase.functions.invoke('use-fortune-pass', { body: {} });
      if (response.error) throw response.error;
      await loadState();
    } catch (cause) { setError(cause instanceof Error ? cause.message : '패스권을 사용하지 못했어요.'); }
    finally { setBusy(false); }
  }

  async function showRewardedAd() {
    if (!supabase) {
      setBusy(true); setError('');
      window.setTimeout(() => { setState({ ...state, fortune_state: 'UNLOCKED', fortune_payload: DEMO_RESULT }); setView('result'); setBusy(false); }, 900);
      return;
    }
    const unit = process.env.NEXT_PUBLIC_WEB_REWARDED_AD_UNIT;
    if (!unit) { setError('웹 광고 설정이 아직 연결되지 않았어요.'); return; }
    setBusy(true); setError('');
    try {
      const prepared = await supabase.functions.invoke('prepare-ad-session', { body: { prepare_request_id: newRequestId(), platform: 'web' } });
      if (prepared.error || !prepared.data?.ad_attempt_id) throw prepared.error ?? new Error('AD_PREPARE_FAILED');
      await new Promise<void>((resolve, reject) => {
        const adWindow = window as unknown as { googletag?: WebGoogletag };
        const gpt = adWindow.googletag ?? ({ cmd: [] } as unknown as WebGoogletag);
        adWindow.googletag = gpt;
        gpt.cmd.push(() => {
          const slot = gpt.defineOutOfPageSlot(unit, gpt.enums.OutOfPageFormat.REWARDED);
          if (!slot) { reject(new Error('WEB_REWARDED_UNAVAILABLE')); return; }
          slot.addService(gpt.pubads());
          const grant = async () => {
            await supabase.functions.invoke('report-ad-impression', { body: { ad_attempt_id: prepared.data.ad_attempt_id } });
            const claim = await supabase.functions.invoke('claim-ad-reward', { body: { ad_attempt_id: prepared.data.ad_attempt_id } });
            if (claim.error) throw claim.error;
            await loadState();
            setView('today');
            resolve();
          };
          let rewardGranted = false;
          gpt.pubads().addEventListener('rewardedSlotReady', (event: WebRewardedEvent) => { if (event.slot === slot) event.makeRewardedVisible?.(); });
          gpt.pubads().addEventListener('rewardedSlotGranted', (event: WebRewardedEvent) => { if (event.slot === slot) { rewardGranted = true; void grant().catch(reject); } });
          gpt.pubads().addEventListener('rewardedSlotClosed', (event: WebRewardedEvent) => { if (event.slot === slot && !rewardGranted) void supabase.functions.invoke('report-ad-dismissed', { body: { ad_attempt_id: prepared.data.ad_attempt_id, terminal_reason: 'dismissed' } }); });
          gpt.display(slot);
        });
      });
    } catch (cause) { setError(cause instanceof Error ? cause.message : '광고를 준비하지 못했어요.'); }
    finally { setBusy(false); }
  }

  const currentPayload = isRealPayload(state.fortune_payload) ? state.fortune_payload : null;

  if (restoring) return <main className="page"><div className="frame"><div className="card" role="status">로그인과 가입 상태를 확인하는 중이다냥…</div></div></main>;

  return (
    <main className="page">
      <div className="frame">
        <header className="topbar">
          <div className="brand"><img src="/assets/images/daegil_cat_mascot.png" alt="" /><span>대길</span></div>
          <button className="icon-button" aria-label="메뉴" onClick={() => setError('설정은 운세 체험 후 준비할게요냥.')}>☰</button>
        </header>

        {view === 'landing' && <Landing onStart={() => setView(supabase ? 'auth' : 'profile')} />}
        {view === 'auth' && <><Auth requirements={requirements} accepted={accepted} age14={age14} busy={busy || !requirementsReady} buttonLabel={hasSession ? '동의 완료하고 시작하기' : 'Google로 계속하기'} error={error} onAge={() => setAge14(!age14)} onToggle={toggleRequirement} onSignIn={signIn} />{!requirementsReady && <button className="button button-secondary" disabled={busy} onClick={async () => { setBusy(true); try { await loadRequirements(); setError(''); } catch { setError('필수 안내를 불러오지 못했어요. 연결을 확인하고 다시 시도해 주세요.'); } finally { setBusy(false); } }}>동의 내용 다시 불러오기</button>}</>}
        {view === 'profile' && <Profile profile={profile} setProfile={setProfile} busy={busy} error={error} onSubmit={saveProfile} />}
        {view === 'today' && <Today state={state} demoMode={demoMode} busy={busy} error={error} onProfile={() => setView('profile')} onPass={usePass} onAd={showRewardedAd} onResult={() => setView('result')} />}
        {view === 'result' && <Result payload={currentPayload ?? DEMO_RESULT} onBack={() => setView('today')} />}
      </div>
      {view !== 'landing' && view !== 'auth' && (demoMode || isRegistrationComplete(state)) && <nav className="footer-nav"><div className="footer-nav-inner"><button className={view === 'today' ? 'active' : ''} onClick={() => setView('today')}>오늘 운세</button><button onClick={() => setView('profile')}>출생정보</button><button onClick={() => setView('landing')}>대길 소개</button></div></nav>}
    </main>
  );
}

function Landing({ onStart }: { onStart: () => void }) {
  return <section className="hero"><img className="mascot" src="/assets/images/daegil_cat_wave.png" alt="대길 고양이" /><h1>오늘의 흐름을<br />대길에게 물어보세요냥.</h1><p>출생정보를 바탕으로<br />고양이 대길이 오늘의 운세를 읽어드려요.</p><div className="stack" style={{ marginTop: 24 }}><button className="button button-primary" onClick={onStart}>오늘 운세 받아보기 🐾</button><span className="small">오락·문화 목적으로 제공되는 AI 운세예요.</span></div></section>;
}

function Auth({ requirements, accepted, age14, busy, buttonLabel, error, onAge, onToggle, onSignIn }: { requirements: Requirement[]; accepted: Set<string>; age14: boolean; busy: boolean; buttonLabel: string; error: string; onAge: () => void; onToggle: (id: string) => void; onSignIn: () => void }) {
return <section><div className="hero"><img className="mascot" src="/assets/images/daegil_cat_yawn.png" alt="" /><h1>대길과<br />첫 인사를 나눠요냥.</h1><p>안전한 운세 체험을 위해<br />몇 가지 확인이 필요해요.</p></div><div className="card stack"><label className="check"><input type="checkbox" checked={age14} onChange={onAge} />만 14세 이상입니다.</label>{requirements.map((item) => <label className="check" key={item.id}><input type="checkbox" checked={accepted.has(item.id)} onChange={() => onToggle(item.id)} />{item.title}{!item.required && <span className="small"> (선택)</span>}</label>)}<button className="button button-primary" disabled={!age14 || !requirements.filter((item) => item.required).every((item) => accepted.has(item.id)) || busy} onClick={onSignIn}>{buttonLabel}</button>{error && <p className="error">{error}</p>}</div></section>;
}

function Profile({ profile, setProfile, busy, error, onSubmit }: { profile: { birthDate: string; city: string; calendar: string; time: string; precision: string }; setProfile: React.Dispatch<React.SetStateAction<{ birthDate: string; city: string; calendar: string; time: string; precision: string }>>; busy: boolean; error: string; onSubmit: (event: React.FormEvent<HTMLFormElement>) => void }) {
  return <section><div className="hero"><img className="mascot" src="/assets/images/daegil_cat_stretch.png" alt="" /><h1>대길에게<br />출생정보를 알려주세요냥.</h1><p>정확한 주소는 필요하지 않아요.<br />시·군 정도만 알려주면 돼요.</p></div><form className="card stack" onSubmit={onSubmit}><div><label className="label" htmlFor="birth-date">생년월일</label><input className="field" id="birth-date" type="date" required value={profile.birthDate} onChange={(e) => setProfile((p) => ({ ...p, birthDate: e.target.value }))} /></div><div className="row"><div><label className="label" htmlFor="calendar">달력</label><select className="field" id="calendar" value={profile.calendar} onChange={(e) => setProfile((p) => ({ ...p, calendar: e.target.value }))}><option value="solar">양력</option><option value="lunar">음력</option></select></div><div><label className="label" htmlFor="city">출생 도시</label><input className="field" id="city" required maxLength={80} placeholder="예: 서울" value={profile.city} onChange={(e) => setProfile((p) => ({ ...p, city: e.target.value }))} /></div></div><div><label className="label" htmlFor="precision">출생 시간</label><div className="row"><select className="field" id="precision" value={profile.precision} onChange={(e) => setProfile((p) => ({ ...p, precision: e.target.value }))}><option value="unknown">모름</option><option value="exact">정확히 알아요</option><option value="approximate">대략 알아요</option></select><input className="field" type="time" disabled={profile.precision === 'unknown'} value={profile.time} onChange={(e) => setProfile((p) => ({ ...p, time: e.target.value }))} /></div></div><button className="button button-primary" disabled={busy} type="submit">저장하고 오늘 운세 보기</button>{error && <p className="error">{error}</p>}</form></section>;
}

function Today({ state, demoMode, busy, error, onProfile, onPass, onAd, onResult }: { state: AppState; demoMode: boolean; busy: boolean; error: string; onProfile: () => void; onPass: () => void; onAd: () => void; onResult: () => void }) {
  const unlocked = state.fortune_state === 'UNLOCKED' && isRealPayload(state.fortune_payload);
  return <section><div className="hero"><img className="mascot" src="/assets/images/daegil_cat_butterfly.png" alt="대길 고양이" /><h1>오늘의 운세</h1><p>{unlocked ? '대길이 오늘의 흐름을 준비했어요냥.' : '대길이 오늘의 흐름을 읽을 준비를 하고 있어요.'}</p></div>{!state.birth_profile_exists && <div className="card stack"><h2 className="section-title">먼저 출생정보가 필요해요냥.</h2><p className="small">출생정보는 서버에서 안전하게 검증하고, 운세 생성에 필요한 범위만 사용해요.</p><button className="button button-primary" onClick={onProfile}>출생정보 입력하기</button></div>}{state.birth_profile_exists && unlocked && <div className="card stack"><div className="notice">오늘 운세가 도착했어요냥. 같은 날에는 광고 없이 다시 볼 수 있어요.</div><button className="button button-primary" onClick={onResult}>결과 읽기</button></div>}{state.birth_profile_exists && !unlocked && <div className="card stack"><span className="pass">🎟 광고 패스권 {state.available_pass_count ?? 0} / 3</span><h2 className="section-title">오늘의 AI 운세를 알려줄까냥?</h2><p className="small">광고를 완료하면 오늘의 운세를 확인할 수 있어요. 운세 생성에 문제가 생겨도 추가 광고 없이 다시 준비해드려요.</p>{(state.available_pass_count ?? 0) > 0 && <button className="button button-jade" disabled={busy} onClick={onPass}>🎟 패스권 쓰겠다냥!</button>}<button className="button button-primary" disabled={busy} onClick={onAd}>{demoMode ? '광고 체험하고 알려달라냥!' : '광고 보고 알려달라냥!'}</button>{error && <p className="error">{error}</p>}</div>}</section>;
}

function Result({ payload, onBack }: { payload: FortunePayload; onBack: () => void }) {
  const section = (title: string, items?: string[]) => <div className="card"><h2 className="section-title">{title}</h2><ol className="list">{(items ?? []).map((item, i) => <li key={`${title}-${i}`}>{item}</li>)}</ol></div>;
  return <section><div className="hero"><img className="mascot" src="/assets/images/daegil_cat_mascot.png" alt="대길 고양이" /><h1>오늘의 AI 운세</h1><p>{payload.headline}</p></div><div className="card"><div className="rating"><span>오늘의 전체 흐름</span><strong>{payload.ratings?.overall ?? 4}/5</strong></div><p className="small">대길이 출생정보와 오늘 날짜를 바탕으로 읽어드렸어요냥.</p></div>{section('전체운', payload.overall)}{section('재물운', payload.money)}{section('연애운', payload.love)}{section('직장·학업운', payload.career)}{section('오늘 하면 좋다냥', payload.recommended_actions)}{section('오늘은 피하라냥', payload.avoid_actions)}<div className="card"><h2 className="section-title">오늘의 행운</h2><p className="small">숫자 {payload.lucky?.number} · {payload.lucky?.color} · {payload.lucky?.time} · {payload.lucky?.keyword}</p></div><div className="card"><p className="small"><strong>AI 생성 콘텐츠</strong><br /><br />오락·문화 목적으로 제공되며 의료·법률·재무 등 전문적인 판단을 대신하지 않습니다.</p><button className="button button-secondary" onClick={onBack}>오늘 화면으로 돌아가기</button></div></section>;
}

type WebRewardedEvent = { slot: unknown; payload?: { type?: string; amount?: number }; makeRewardedVisible?: () => boolean };
type WebGoogletag = { cmd: (() => void)[]; enums: { OutOfPageFormat: { REWARDED: string } }; defineOutOfPageSlot: (unit: string, format: string) => WebSlot | null; pubads: () => { addEventListener: (name: string, cb: (event: WebRewardedEvent) => void) => void }; display: (slot: WebSlot) => void };
type WebSlot = { addService: (service: unknown) => void };
