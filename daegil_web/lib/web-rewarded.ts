export type WebRewardedEvent = {
  slot: unknown;
  isEmpty?: boolean;
  makeRewardedVisible?: () => boolean;
};
type Listener = (event: WebRewardedEvent) => void;
type WebPubads = {
  addEventListener: (name: string, listener: Listener) => void;
  removeEventListener: (name: string, listener: Listener) => void;
};
type WebSlot = { addService: (service: WebPubads) => void };
export type WebGoogletag = {
  cmd: { push: (callback: () => void) => unknown };
  enums: { OutOfPageFormat: { REWARDED: number } };
  defineOutOfPageSlot: (unit: string, format: number) => WebSlot | null;
  pubads: () => WebPubads;
  enableServices: () => void;
  display: (slot: WebSlot) => void;
  destroySlots: (slots: WebSlot[]) => unknown;
};

// Called only after the user explicitly chooses to view a rewarded ad.
export function runWebRewardedAd(options: {
  gpt: WebGoogletag;
  unit: string;
  signal: AbortSignal;
  onImpression: () => Promise<void>;
  onReward: () => Promise<void>;
  onDismiss: (reason: 'dismissed' | 'show_failed') => Promise<void>;
  loadTimeoutMs?: number;
  showTimeoutMs?: number;
}): Promise<'rewarded' | 'dismissed'> {
  const { gpt, signal } = options;
  return new Promise((resolve, reject) => {
    let finished = false;
    let shown = false;
    let rewarded = false;
    let impressionReported = false;
    let slot: WebSlot | null = null;
    let pubads: WebPubads | undefined;
    let timer: ReturnType<typeof setTimeout>;
    const listeners: [string, Listener][] = [];
    const reports: Promise<unknown>[] = [];

    function report(callback: () => Promise<void>) {
      // Attach rejection handling immediately, even while the ad stays open.
      reports.push(Promise.resolve().then(callback).then(() => null, () => new Error('WEB_AD_REPORT_FAILED')));
    }

    async function finish(reason: 'dismissed' | 'show_failed', failure?: Error) {
      if (finished) return;
      finished = true;
      clearTimeout(timer);
      signal.removeEventListener('abort', abort);
      try {
        for (const [name, listener] of listeners) pubads?.removeEventListener(name, listener);
        if (slot) gpt.destroySlots([slot]);
      } catch {
        failure ??= new Error('WEB_AD_CLEANUP_FAILED');
      }
      report(() => options.onDismiss(reason));
      const errors = await Promise.all(reports);
      const reportFailure = errors.find((error) => error instanceof Error);
      if (failure || reportFailure) reject(failure ?? reportFailure);
      else resolve(rewarded ? 'rewarded' : 'dismissed');
    }

    function abort() { void finish('show_failed', new Error('WEB_AD_CANCELLED')); }
    timer = setTimeout(() => void finish('show_failed', new Error('WEB_AD_LOAD_TIMEOUT')), options.loadTimeoutMs ?? 20_000);
    signal.addEventListener('abort', abort, { once: true });
    if (signal.aborted) { abort(); return; }

    const initialize = () => {
      if (finished) return; // A blocked GPT script may load after the deadline.
      try {
        slot = gpt.defineOutOfPageSlot(options.unit, gpt.enums.OutOfPageFormat.REWARDED);
        if (!slot) { void finish('show_failed', new Error('WEB_REWARDED_UNAVAILABLE')); return; }
        pubads = gpt.pubads();
        slot.addService(pubads);
        const listen = (name: string, handler: Listener) => {
          const listener: Listener = (event) => { if (!finished && event.slot === slot) handler(event); };
          listeners.push([name, listener]);
          pubads!.addEventListener(name, listener);
        };
        listen('rewardedSlotReady', (event) => {
          if (shown) return;
          shown = true;
          try {
            if (!event.makeRewardedVisible?.()) throw new Error('WEB_AD_SHOW_FAILED');
            if (finished) return;
            clearTimeout(timer);
            timer = setTimeout(() => void finish('show_failed', new Error('WEB_AD_SHOW_TIMEOUT')), options.showTimeoutMs ?? 600_000);
          } catch { void finish('show_failed', new Error('WEB_AD_SHOW_FAILED')); }
        });
        listen('impressionViewable', () => {
          if (impressionReported) return;
          impressionReported = true;
          report(options.onImpression);
        });
        listen('rewardedSlotGranted', () => {
          if (rewarded) return;
          rewarded = true;
          report(options.onReward);
        });
        listen('rewardedSlotClosed', () => { void finish('dismissed'); });
        listen('slotRenderEnded', (event) => {
          if (event.isEmpty) void finish('show_failed', new Error('WEB_AD_NO_FILL'));
        });
        gpt.enableServices();
        gpt.display(slot);
      } catch { void finish('show_failed', new Error('WEB_AD_SETUP_FAILED')); }
    };
    try { gpt.cmd.push(initialize); }
    catch { void finish('show_failed', new Error('WEB_AD_SETUP_FAILED')); }
  });
}
