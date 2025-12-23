import { post as commonsPost, getCurrentOrderId, getCurrentMenuId, getRestaurantId, initOrderBindings as commonsInitOrderBindings } from './ordr_commons';

function qs(sel) { return document.querySelector(sel); }

function ensureUi() {
  if (document.getElementById('voice-ptt')) return;
  const host = document.body || document.documentElement;
  if (!host) return;

  (function ensureVoiceWaveStyles() {
    if (document.getElementById('voice-wave-styles')) return;
    const style = document.createElement('style');
    style.id = 'voice-wave-styles';
    style.textContent = `
      @keyframes voiceWave {
        0% { transform: scaleY(0.35); opacity: 0.7; }
        50% { transform: scaleY(1.0); opacity: 1; }
        100% { transform: scaleY(0.35); opacity: 0.7; }
      }
      .voice-wave { display: inline-flex; align-items: flex-end; gap: 3px; height: 18px; }
      .voice-wave span { width: 3px; height: 100%; background: currentColor; border-radius: 2px; transform-origin: bottom; animation: voiceWave 0.9s ease-in-out infinite; }
      .voice-wave span:nth-child(1) { animation-delay: 0s; height: 10px; }
      .voice-wave span:nth-child(2) { animation-delay: 0.12s; height: 16px; }
      .voice-wave span:nth-child(3) { animation-delay: 0.24s; height: 12px; }
      .voice-wave span:nth-child(4) { animation-delay: 0.36s; height: 18px; }
    `;
    document.head.appendChild(style);
  })();

  const wrap = document.createElement('div');
  wrap.id = 'voice-menu-ui';
  wrap.style.position = 'fixed';
  wrap.style.left = '50%';
  wrap.style.bottom = '0px';
  wrap.style.transform = 'translateX(-50%)';
  wrap.style.zIndex = '2147483647';
  wrap.style.display = 'flex';
  wrap.style.flexDirection = 'column';
  wrap.style.alignItems = 'center';
  wrap.style.pointerEvents = 'none';
  wrap.style.position = 'fixed';
  wrap.style.width = '180px';
  wrap.style.height = '70px';
  wrap.style.justifyContent = 'flex-end';
  wrap.style.overflow = 'visible';

  const btn = document.createElement('button');
  btn.id = 'voice-ptt';
  btn.type = 'button';
  btn.className = 'btn btn-primary';
  btn.style.pointerEvents = 'auto';
  btn.style.width = '180px';
  btn.style.height = '70px';
  btn.style.borderRadius = '999px 999px 0 0';
  btn.style.border = '0';
  btn.style.display = 'flex';
  btn.style.alignItems = 'center';
  btn.style.justifyContent = 'center';
  btn.style.gap = '10px';
  btn.style.boxShadow = '0 -6px 18px rgba(0,0,0,0.25)';
  btn.style.fontWeight = '600';
  btn.style.letterSpacing = '0.2px';
  btn.innerHTML = '<i class="bi bi-mic-fill" aria-hidden="true"></i><span>Speak</span>';

  const out = document.createElement('div');
  out.id = 'voice-output';
  out.style.position = 'absolute';
  out.style.left = '50%';
  out.style.bottom = '78px';
  out.style.transform = 'translateX(-50%)';
  out.style.padding = '8px 10px';
  out.style.borderRadius = '10px';
  out.style.background = 'rgba(0,0,0,0.75)';
  out.style.color = '#fff';
  out.style.fontSize = '13px';
  out.style.maxWidth = '260px';
  out.style.display = 'none';
  out.style.pointerEvents = 'auto';

  wrap.appendChild(out);
  wrap.appendChild(btn);
  host.appendChild(wrap);
}

function setPttButtonState(listening) {
  const btn = document.getElementById('voice-ptt');
  if (!btn) return;
  if (listening) {
    btn.innerHTML = '<span class="voice-wave" aria-hidden="true"><span></span><span></span><span></span><span></span></span><span>Speak</span>';
  } else {
    btn.innerHTML = '<i class="bi bi-mic-fill" aria-hidden="true"></i><span>Speak</span>';
  }
}

function showMessage(msg) {
  const out = document.getElementById('voice-output');
  if (!out) return;
  out.textContent = msg;
  out.style.display = '';
}

function hideMessageSoon() {
  const out = document.getElementById('voice-output');
  if (!out) return;
  setTimeout(() => { try { out.style.display = 'none'; } catch (_) {} }, 4500);
}

function getSmartmenuSlug() {
  try { return document.body?.dataset?.smartmenuId || null; } catch (_) { return null; }
}

function stripPoliteness(text) {
  let s = String(text || '').trim().toLowerCase();
  s = s.replace(/[\s.,!?]+$/g, '');
  // Remove common trailing politeness/filler phrases; repeat until stable
  // Examples: "please", "thanks", "thank you", "cheers".
  // Keep this conservative to avoid stripping legitimate menu words in the middle.
  while (true) {
    const before = s;
    s = s.replace(/\s*(please|pls|plz|thanks|thank\s+you|thank\s+u|thx|cheers|ta|much\s+appreciated|appreciate\s+it)\s*$/g, '');
    s = s.replace(/[\s.,!?]+$/g, '');
    if (s === before) break;
  }
  return s.trim();
}

function normalizeForMatch(text) {
  let s = stripPoliteness(text);
  // Normalize & vs and
  s = s.replace(/&/g, ' and ');
  s = s.replace(/\band\b/g, ' and ');
  // Drop punctuation/symbols, keep letters/numbers/spaces
  s = s.replace(/[^a-z0-9\s]/g, ' ');
  s = s.replace(/\s+/g, ' ').trim();
  return s;
}

function diceCoefficient(a, b) {
  const s1 = normalizeForMatch(a);
  const s2 = normalizeForMatch(b);
  if (!s1 || !s2) return 0;
  if (s1 === s2) return 1;
  if (s1.length < 2 || s2.length < 2) return 0;

  const bigrams = (s) => {
    const out = new Map();
    for (let i = 0; i < s.length - 1; i++) {
      const bg = s.slice(i, i + 2);
      out.set(bg, (out.get(bg) || 0) + 1);
    }
    return out;
  };

  const b1 = bigrams(s1);
  const b2 = bigrams(s2);
  let overlap = 0;
  for (const [bg, c1] of b1.entries()) {
    const c2 = b2.get(bg) || 0;
    overlap += Math.min(c1, c2);
  }
  return (2 * overlap) / ((s1.length - 1) + (s2.length - 1));
}

function tokenOverlapScore(query, candidate) {
  const q = normalizeForMatch(query);
  const c = normalizeForMatch(candidate);
  if (!q || !c) return 0;

  const qTokens = q.split(' ').filter(Boolean);
  const cTokens = new Set(c.split(' ').filter(Boolean));
  if (!qTokens.length || !cTokens.size) return 0;

  let hits = 0;
  for (const t of qTokens) if (cTokens.has(t)) hits++;
  return hits / qTokens.length;
}

function bestMenuItemMatch(query) {
  const q = normalizeForMatch(query);
  if (!q) return null;

  const nodes = document.querySelectorAll('[data-bs-menuitem_id][data-bs-menuitem_name]');
  let best = null;

  for (const n of nodes) {
    const id = n.getAttribute('data-bs-menuitem_id');
    if (!id) continue;
    const name = n.getAttribute('data-bs-menuitem_name') || '';
    const desc = n.getAttribute('data-bs-menuitem_description') || '';
    const hay = `${name} ${desc}`;
    const hayN = normalizeForMatch(hay);

    // Combine a few cheap signals
    let score = 0;
    if (hayN === q) score = 1;
    else if (hayN.includes(q)) score = 0.92;
    else if (normalizeForMatch(name).includes(q)) score = 0.88;
    else {
      const dice = diceCoefficient(q, hayN);
      const tok = tokenOverlapScore(q, hayN);
      score = Math.max(dice * 0.75 + tok * 0.25, tok * 0.7);
    }

    if (!best || score > best.score) {
      const rawPrice = n.getAttribute('data-bs-menuitem_price');
      const price = rawPrice != null && rawPrice !== '' ? Number(rawPrice) : 0;
      best = {
        id,
        price: Number.isFinite(price) ? price : 0,
        score,
      };
    }
  }

  // Threshold: avoid adding random items on weak matches
  if (!best) return null;
  if (best.score < 0.45) return null;
  return best;
}

async function pollVoiceCommand(slug, id) {
  const url = `/smartmenus/${encodeURIComponent(slug)}/voice_commands/${id}`;
  for (let i = 0; i < 40; i++) {
    const r = await fetch(url, { headers: { Accept: 'application/json' } });
    const data = await r.json().catch(() => null);
    if (!data) break;
    if (data.status === 'completed') return data;
    if (data.status === 'failed') return data;
    await new Promise((res) => setTimeout(res, 350));
  }
  return null;
}

function findMenuItemIdByQuery(query) {
  const m = bestMenuItemMatch(query);
  return m ? m.id : null;
}

function resolveMenuItemByQuery(query) {
  const m = bestMenuItemMatch(query);
  return m ? { id: m.id, price: m.price } : null;
}

async function executeIntent(payload) {
  const intent = payload?.intent || {};
  const type = intent.type;

  if (type === 'empty') { showMessage('I did not hear anything.'); hideMessageSoon(); return; }
  if (type === 'unknown') { showMessage(`Sorry, I didn't understand: ${payload.transcript || ''}`); hideMessageSoon(); return; }

  if (type === 'start_order') {
    // Prefer clicking the visible Start Order CTA (it opens #openOrderModal)
    const startCta = document.querySelector('[data-bs-target="#openOrderModal"]');
    if (startCta) {
      startCta.click();
      showMessage('Starting order…');
      hideMessageSoon();
      return;
    }
    // Fallback: show modal directly
    const openOrderModal = document.getElementById('openOrderModal');
    if (openOrderModal && window.bootstrap && window.bootstrap.Modal) {
      const inst = window.bootstrap.Modal.getInstance(openOrderModal) || window.bootstrap.Modal.getOrCreateInstance(openOrderModal);
      inst.show();
      showMessage('Starting order…');
      hideMessageSoon();
      return;
    }
    showMessage('Cannot start an order on this page.');
    hideMessageSoon();
    return;
  }

  if (type === 'close_order') {
    // Prefer the existing close order button if present
    const closeBtn = qs('#close-order');
    if (closeBtn && !closeBtn.hasAttribute('disabled')) {
      closeBtn.click();
      showMessage('Closing order…');
      hideMessageSoon();
      return;
    }

    const orderId = getCurrentOrderId();
    const restaurantId = getRestaurantId();
    if (!restaurantId || !orderId) {
      showMessage('No active order to close.');
      hideMessageSoon();
      return;
    }

    const csrf = document.querySelector("meta[name='csrf-token']")?.content || '';
    await fetch(`/restaurants/${restaurantId}/ordrs/${orderId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        'X-CSRF-Token': csrf,
      },
      body: JSON.stringify({ ordr: { status: 40 } }),
    });
    showMessage('Order closed.');
    hideMessageSoon();
    return;
  }

  // Require an active order for order mutations.
  const orderId = getCurrentOrderId();
  const restaurantId = getRestaurantId();
  const menuId = getCurrentMenuId();

  if (!restaurantId || !menuId) {
    showMessage('Missing context. Please refresh the menu.');
    hideMessageSoon();
    return;
  }

  if (type === 'submit_order') {
    const btn = qs('#confirm-order');
    if (btn) { btn.click(); showMessage('Submitting order…'); hideMessageSoon(); return; }
    showMessage('Cannot submit order yet.'); hideMessageSoon();
    return;
  }

  if (type === 'request_bill') {
    const btn = qs('#request-bill');
    if (btn) { btn.click(); showMessage('Requesting bill…'); hideMessageSoon(); return; }
    showMessage('Cannot request bill yet.'); hideMessageSoon();
    return;
  }

  if (!orderId) {
    showMessage('Please start an order first, then try again.');
    hideMessageSoon();
    return;
  }

  if (type === 'add_item') {
    const resolved = resolveMenuItemByQuery(intent.query) || resolveMenuItemByQuery((payload.transcript || '').toLowerCase());
    if (!resolved || !resolved.id) {
      showMessage(`Couldn't find an item matching: ${intent.query}`);
      hideMessageSoon();
      return;
    }

    const menuitemId = resolved.id;
    const ordritemprice = resolved.price;

    const qty = typeof intent.qty === 'number' ? intent.qty : 1;
    for (let i = 0; i < qty; i++) {
      await commonsPost(`/restaurants/${restaurantId}/ordritems`, {
        ordritem: {
          ordr_id: orderId,
          menuitem_id: menuitemId,
          status: 0,
          ordritemprice: ordritemprice,
        },
      });
    }

    showMessage(`Added ${qty} item(s).`);
    hideMessageSoon();
    return;
  }

  if (type === 'remove_item') {
    // Remove by matching existing state order items to the resolved query
    const items = (window.__SM_STATE && window.__SM_STATE.order && Array.isArray(window.__SM_STATE.order.items)) ? window.__SM_STATE.order.items : [];
    if (!items.length) { showMessage('No items to remove.'); hideMessageSoon(); return; }

    const targetMenuitemId = findMenuItemIdByQuery(intent.query);
    if (!targetMenuitemId) { showMessage(`Couldn't find an item matching: ${intent.query}`); hideMessageSoon(); return; }

    const qty = typeof intent.qty === 'number' ? intent.qty : 1;
    let removed = 0;
    for (const it of items) {
      if (removed >= qty) break;
      if (String(it.menuitem_id) !== String(targetMenuitemId)) continue;
      if (String(it.status || '').toLowerCase() !== 'opened') continue;
      await fetch(`/restaurants/${restaurantId}/ordritems/${it.id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")?.content || '',
        },
        body: JSON.stringify({ ordritem: { status: 10, ordritemprice: 0 } }),
      });
      removed++;
    }

    showMessage(removed ? `Removed ${removed} item(s).` : 'No matching item to remove.');
    hideMessageSoon();
    return;
  }
}

async function sendAudio(blob, locale) {
  const slug = getSmartmenuSlug();
  if (!slug) return null;

  const fd = new FormData();
  fd.append('audio', blob, 'voice.webm');
  if (locale) fd.append('locale', locale);
  fd.append('restaurant_id', getRestaurantId() || '');
  fd.append('menu_id', getCurrentMenuId() || '');
  fd.append('order_id', getCurrentOrderId() || '');

  const csrf = document.querySelector("meta[name='csrf-token']")?.content || '';
  const r = await fetch(`/smartmenus/${encodeURIComponent(slug)}/voice_commands`, {
    method: 'POST',
    headers: { 'X-CSRF-Token': csrf, Accept: 'application/json' },
    body: fd,
  });
  return r.ok ? r.json() : null;
}

async function sendTranscript(transcript, locale) {
  const slug = getSmartmenuSlug();
  if (!slug) return null;

  const csrf = document.querySelector("meta[name='csrf-token']")?.content || '';
  const r = await fetch(`/smartmenus/${encodeURIComponent(slug)}/voice_commands`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'X-CSRF-Token': csrf,
    },
    body: JSON.stringify({
      transcript,
      locale,
      restaurant_id: getRestaurantId(),
      menu_id: getCurrentMenuId(),
      order_id: getCurrentOrderId(),
    }),
  });
  return r.ok ? r.json() : null;
}

function canUseWebSpeech() {
  return typeof window !== 'undefined' && (window.SpeechRecognition || window.webkitSpeechRecognition);
}

function startWebSpeech(locale, onResult, onError) {
  const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
  const rec = new SR();
  rec.continuous = false;
  rec.interimResults = false;
  if (locale) rec.lang = locale;

  rec.onresult = (evt) => {
    try {
      const t = evt.results && evt.results[0] && evt.results[0][0] ? evt.results[0][0].transcript : '';
      onResult(t);
    } catch (e) { onError(e); }
  };
  rec.onerror = (e) => onError(e);
  rec.start();

  return () => { try { rec.stop(); } catch (_) {} };
}

async function startRecording(locale) {
  const constraints = {
    audio: {
      echoCancellation: true,
      noiseSuppression: true,
      autoGainControl: true,
    },
  };

  const stream = await navigator.mediaDevices.getUserMedia(constraints);
  const mimeType = MediaRecorder.isTypeSupported('audio/webm;codecs=opus') ? 'audio/webm;codecs=opus' : 'audio/webm';
  const recorder = new MediaRecorder(stream, { mimeType });
  const chunks = [];

  recorder.ondataavailable = (e) => { if (e.data && e.data.size) chunks.push(e.data); };

  recorder.start();

  return {
    stop: () => new Promise((resolve) => {
      recorder.onstop = () => {
        try { stream.getTracks().forEach((t) => t.stop()); } catch (_) {}
        const blob = new Blob(chunks, { type: mimeType });
        resolve(blob);
      };
      try { recorder.stop(); } catch (_) { resolve(null); }
    }),
  };
}

export function initVoiceMenus() {
  try {
    const ctx = document.getElementById('contextContainer');
    const allowOrdering = (ctx?.dataset?.menuAllowOrdering || '') === '1';
    const voiceOrderingEnabled = (ctx?.dataset?.menuVoiceOrderingEnabled || '') === '1';

    if (!(allowOrdering && voiceOrderingEnabled)) {
      try { document.getElementById('voice-menu-ui')?.remove(); } catch (_) {}
      return;
    }
  } catch (_) {}

  ensureUi();

  const btn = document.getElementById('voice-ptt');
  if (!btn) return;
  if (btn.__voiceBound) return;
  btn.__voiceBound = true;

  try { commonsInitOrderBindings(); } catch (_) {}

  let stopSpeech = null;
  let recorder = null;

  const locale = (document.querySelector('meta[name="current-locale"]')?.content || '').trim();

  const onDown = async () => {
    btn.disabled = true;
    setPttButtonState(true);
    showMessage('Listening…');

    try {
      if (canUseWebSpeech()) {
        stopSpeech = startWebSpeech(locale, async (transcript) => {
          showMessage(`Heard: ${transcript}`);
          const created = await sendTranscript(transcript, locale);
          if (!created || !created.id) { showMessage('Failed to submit voice command.'); hideMessageSoon(); return; }
          showMessage('Processing…');
          const payload = await pollVoiceCommand(getSmartmenuSlug(), created.id);
          await executeIntent(payload);
        }, (e) => {
          showMessage('Speech recognition failed.');
          hideMessageSoon();
        });
      } else {
        recorder = await startRecording(locale);
      }
    } finally {
      btn.disabled = false;
    }
  };

  const onUp = async () => {
    try {
      if (stopSpeech) {
        const stop = stopSpeech;
        stopSpeech = null;
        stop();
        setPttButtonState(false);
        return;
      }

      if (!recorder) return;

      btn.disabled = true;
      showMessage('Uploading…');
      const blob = await recorder.stop();
      recorder = null;

      if (!blob) { showMessage('No audio recorded.'); hideMessageSoon(); return; }

      const created = await sendAudio(blob, locale);
      if (!created || !created.id) { showMessage('Failed to submit voice command.'); hideMessageSoon(); return; }

      showMessage('Processing…');
      const payload = await pollVoiceCommand(getSmartmenuSlug(), created.id);
      await executeIntent(payload);
    } finally {
      btn.disabled = false;
      setPttButtonState(false);
    }
  };

  btn.addEventListener('pointerdown', (e) => { e.preventDefault(); onDown(); });
  btn.addEventListener('pointerup', (e) => { e.preventDefault(); onUp(); });
  btn.addEventListener('pointercancel', (e) => { e.preventDefault(); onUp(); });
}
