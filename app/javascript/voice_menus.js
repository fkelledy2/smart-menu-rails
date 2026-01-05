import { post as commonsPost, getCurrentOrderId, getCurrentMenuId, getRestaurantId, initOrderBindings as commonsInitOrderBindings } from './ordr_commons';

function qs(sel) { return document.querySelector(sel); }

function normalizeUiLocale(raw) {
  const s = String(raw || '').trim().toLowerCase().replace('_', '-');
  const base = (s.split('-')[0] || '').trim();
  if (base === 'fr' || base === 'it' || base === 'es' || base === 'en') return base;
  return 'en';
}

function getUiLocale() {
  return normalizeUiLocale(document.querySelector('meta[name="current-locale"]')?.content || '');
}

const VOICE_UI_I18N = {
  en: {
    failed_submit: 'Failed to submit voice command.',
    speech_failed: 'Speech recognition failed.',
    no_audio_recorded: 'No audio recorded.',
    did_not_hear: 'I did not hear anything.',
    didnt_understand: "Sorry, I didn't understand: %{transcript}",
    couldnt_find_item: "Couldn't find an item matching: %{query}",
    cannot_submit_order_yet: 'Cannot submit order yet.',
    cannot_request_bill_yet: 'Cannot request bill yet.',
    missing_context_refresh: 'Missing context. Please refresh the menu.',
    cannot_start_order: 'Cannot start an order on this page.',
    no_active_order_to_close: 'No active order to close.',
    please_start_order_first: 'Please start an order first, then try again.',
    no_items_to_remove: 'No items to remove.',
    no_matching_item_to_remove: 'No matching item to remove.',
  },
  fr: {
    failed_submit: "Échec de l’envoi de la commande vocale.",
    speech_failed: 'La reconnaissance vocale a échoué.',
    no_audio_recorded: 'Aucun audio enregistré.',
    did_not_hear: "Je n’ai rien entendu.",
    didnt_understand: "Désolé, je n’ai pas compris : %{transcript}",
    couldnt_find_item: "Impossible de trouver un article correspondant : %{query}",
    cannot_submit_order_yet: 'Impossible de valider la commande pour le moment.',
    cannot_request_bill_yet: "Impossible de demander l’addition pour le moment.",
    missing_context_refresh: 'Contexte manquant. Veuillez actualiser le menu.',
    cannot_start_order: 'Impossible de démarrer une commande sur cette page.',
    no_active_order_to_close: 'Aucune commande active à clôturer.',
    please_start_order_first: "Veuillez d’abord démarrer une commande, puis réessayer.",
    no_items_to_remove: 'Aucun article à retirer.',
    no_matching_item_to_remove: "Aucun article correspondant à retirer.",
  },
  it: {
    failed_submit: 'Invio del comando vocale non riuscito.',
    speech_failed: 'Il riconoscimento vocale non è riuscito.',
    no_audio_recorded: 'Nessun audio registrato.',
    did_not_hear: 'Non ho sentito nulla.',
    didnt_understand: 'Mi dispiace, non ho capito: %{transcript}',
    couldnt_find_item: 'Non riesco a trovare un elemento corrispondente: %{query}',
    cannot_submit_order_yet: 'Impossibile inviare l’ordine al momento.',
    cannot_request_bill_yet: 'Impossibile richiedere il conto al momento.',
    missing_context_refresh: 'Contesto mancante. Aggiorna il menu.',
    cannot_start_order: 'Impossibile avviare un ordine su questa pagina.',
    no_active_order_to_close: 'Nessun ordine attivo da chiudere.',
    please_start_order_first: 'Avvia prima un ordine, poi riprova.',
    no_items_to_remove: 'Nessun elemento da rimuovere.',
    no_matching_item_to_remove: 'Nessun elemento corrispondente da rimuovere.',
  },
  es: {
    failed_submit: 'No se pudo enviar el comando de voz.',
    speech_failed: 'Falló el reconocimiento de voz.',
    no_audio_recorded: 'No se grabó audio.',
    did_not_hear: 'No escuché nada.',
    didnt_understand: 'Lo siento, no entendí: %{transcript}',
    couldnt_find_item: 'No pude encontrar un artículo que coincida: %{query}',
    cannot_submit_order_yet: 'No se puede enviar el pedido todavía.',
    cannot_request_bill_yet: 'No se puede pedir la cuenta todavía.',
    missing_context_refresh: 'Falta contexto. Actualiza el menú.',
    cannot_start_order: 'No se puede iniciar un pedido en esta página.',
    no_active_order_to_close: 'No hay un pedido activo para cerrar.',
    please_start_order_first: 'Primero inicia un pedido y vuelve a intentarlo.',
    no_items_to_remove: 'No hay artículos para eliminar.',
    no_matching_item_to_remove: 'No hay ningún artículo coincidente para eliminar.',
  },
};

function tUi(key, vars) {
  const loc = getUiLocale();
  const table = VOICE_UI_I18N[loc] || VOICE_UI_I18N.en;
  const tpl = table[key] || VOICE_UI_I18N.en[key] || String(key);
  const v = vars || {};
  return String(tpl)
    .replace(/%\{transcript\}/g, String(v.transcript || ''))
    .replace(/%\{query\}/g, String(v.query || ''));
}

let __voiceMicStream = null;
let __voiceMicReleaseTimer = null;

function stopMicStream() {
  try {
    if (__voiceMicReleaseTimer) {
      clearTimeout(__voiceMicReleaseTimer);
      __voiceMicReleaseTimer = null;
    }
  } catch (_) {}

  try {
    if (__voiceMicStream) {
      try { __voiceMicStream.getTracks().forEach((t) => t.stop()); } catch (_) {}
    }
  } finally {
    __voiceMicStream = null;
  }
}

async function getOrCreateMicStream(constraints) {
  if (__voiceMicStream) {
    try {
      if (__voiceMicReleaseTimer) {
        clearTimeout(__voiceMicReleaseTimer);
        __voiceMicReleaseTimer = null;
      }
    } catch (_) {}
    return __voiceMicStream;
  }

  __voiceMicStream = await navigator.mediaDevices.getUserMedia(constraints);
  return __voiceMicStream;
}

function scheduleMicRelease(ms = 45000) {
  // Keep the mic stream alive briefly to avoid mobile Chrome re-showing the permission banner
  // on every press/hold. Release after idle to avoid keeping the mic on indefinitely.
  try {
    if (__voiceMicReleaseTimer) clearTimeout(__voiceMicReleaseTimer);
    __voiceMicReleaseTimer = setTimeout(() => {
      stopMicStream();
    }, ms);
  } catch (_) {}
}

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

  // If table selection changes after init, hide/show voice UI accordingly.
  (function bindTableSelectionWatcher() {
    if (window.__VOICE_TABLE_WATCH_BOUND) return;
    window.__VOICE_TABLE_WATCH_BOUND = true;

    const ctx = document.getElementById('contextContainer');
    if (!ctx) return;

    const apply = () => {
      try {
        const hasTable = !!(ctx?.dataset?.tableId && String(ctx.dataset.tableId).trim().length);
        const wrap = document.getElementById('voice-menu-ui');
        if (!hasTable) {
          try { wrap?.remove(); } catch (_) {}
          try { stopMicStream(); } catch (_) {}
        } else {
          // If the UI was removed and voice is enabled, re-init.
          if (!document.getElementById('voice-ptt')) {
            try { initVoiceMenus(); } catch (_) {}
          }
        }
      } catch (_) {}
    };

    try {
      const obs = new MutationObserver(apply);
      obs.observe(ctx, { attributes: true, attributeFilter: ['data-table-id'] });
    } catch (_) {}
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

  // iOS Chrome/Safari: when the browser toolbar collapses/expands on scroll, `position: fixed; bottom: 0`
  // can appear to "float" above the true bottom. Use VisualViewport to keep it pinned.
  (function bindVisualViewportPinning() {
    if (wrap.__vvBound) return;
    wrap.__vvBound = true;

    const wrapHeight = 70;
    let raf = null;

    const positionToVisualViewport = () => {
      raf = null;
      try {
        const vv = window.visualViewport;
        if (!vv) return;

        // Place wrapper at the bottom of the *visual* viewport.
        const top = Math.max(0, Math.round(vv.offsetTop + vv.height - wrapHeight));
        wrap.style.top = `${top}px`;
        wrap.style.bottom = 'auto';
      } catch (_) {}
    };

    const schedule = () => {
      if (raf) return;
      raf = window.requestAnimationFrame(positionToVisualViewport);
    };

    try {
      if (window.visualViewport) {
        window.visualViewport.addEventListener('resize', schedule);
        window.visualViewport.addEventListener('scroll', schedule);
      }
      window.addEventListener('orientationchange', schedule);
      window.addEventListener('resize', schedule);
    } catch (_) {}

    // Initial position
    schedule();
  })();
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

function isElementInViewport(el) {
  try {
    if (!el || !(el instanceof Element)) return false;
    const r = el.getBoundingClientRect();
    const vh = window.innerHeight || document.documentElement.clientHeight || 0;
    const vw = window.innerWidth || document.documentElement.clientWidth || 0;
    if (!vh || !vw) return false;
    // Consider "visible" if it intersects the viewport.
    return r.bottom > 0 && r.right > 0 && r.top < vh && r.left < vw;
  } catch (_) {
    return false;
  }
}

function bestMenuItemMatchInNodes(query, nodes, { visibleBias = false } = {}) {
  const q = normalizeForMatch(query);
  if (!q) return null;
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

    if (visibleBias && score > 0) {
      // Mild boost for items the customer can currently see.
      if (isElementInViewport(n)) score += 0.08;
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

function bestMenuItemMatch(query, { preferVisible = false } = {}) {
  const all = document.querySelectorAll('[data-bs-menuitem_id][data-bs-menuitem_name]');
  if (!preferVisible) return bestMenuItemMatchInNodes(query, all);

  // First try visible items only.
  const visible = Array.from(all).filter((n) => isElementInViewport(n));
  if (visible.length) {
    const m1 = bestMenuItemMatchInNodes(query, visible, { visibleBias: true });
    // If we got a strong visible match, take it.
    if (m1 && m1.score >= 0.55) return m1;
  }

  // Fall back to entire menu, still applying a mild visibility bias.
  return bestMenuItemMatchInNodes(query, all, { visibleBias: true });
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

function findMenuItemIdByQuery(query, opts) {
  const m = bestMenuItemMatch(query, opts);
  return m ? m.id : null;
}

function resolveMenuItemByQuery(query, opts) {
  const m = bestMenuItemMatch(query, opts);
  return m ? { id: m.id, price: m.price } : null;
}

async function executeIntent(payload) {
  const intent = payload?.intent || {};
  const type = intent.type;

  if (type === 'empty') { showMessage(tUi('did_not_hear')); hideMessageSoon(); return; }
  if (type === 'unknown') { showMessage(tUi('didnt_understand', { transcript: payload.transcript || '' })); hideMessageSoon(); return; }

  if (type === 'start_order') {
    // Prefer clicking the visible Start Order CTA (it opens #openOrderModal)
    const startCta = document.querySelector('[data-bs-target="#openOrderModal"]');
    if (startCta) {
      startCta.click();
      return;
    }
    // Fallback: show modal directly
    const openOrderModal = document.getElementById('openOrderModal');
    if (openOrderModal && window.bootstrap && window.bootstrap.Modal) {
      const inst = window.bootstrap.Modal.getInstance(openOrderModal) || window.bootstrap.Modal.getOrCreateInstance(openOrderModal);
      inst.show();
      return;
    }
    showMessage(tUi('cannot_start_order'));
    hideMessageSoon();
    return;
  }

  if (type === 'close_order') {
    // Prefer the existing close order button if present
    const closeBtn = qs('#close-order');
    if (closeBtn && !closeBtn.hasAttribute('disabled')) {
      closeBtn.click();
      return;
    }

    const orderId = getCurrentOrderId();
    const restaurantId = getRestaurantId();
    if (!restaurantId || !orderId) {
      showMessage(tUi('no_active_order_to_close'));
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
    return;
  }

  // Require an active order for order mutations.
  const orderId = getCurrentOrderId();
  const restaurantId = getRestaurantId();
  const menuId = getCurrentMenuId();

  if (!restaurantId || !menuId) {
    showMessage(tUi('missing_context_refresh'));
    hideMessageSoon();
    return;
  }

  if (type === 'submit_order') {
    const btn = qs('#confirm-order');
    if (btn) { btn.click(); return; }
    showMessage(tUi('cannot_submit_order_yet')); hideMessageSoon();
    return;
  }

  if (type === 'request_bill') {
    const btn = qs('#request-bill');
    if (btn) { btn.click(); return; }
    showMessage(tUi('cannot_request_bill_yet')); hideMessageSoon();
    return;
  }

  if (!orderId) {
    showMessage(tUi('please_start_order_first'));
    hideMessageSoon();
    return;
  }

  if (type === 'add_item') {
    let menuitemId = intent.menuitem_id;
    let ordritemprice = 0;
    if (!menuitemId) {
      const resolved = resolveMenuItemByQuery(intent.query, { preferVisible: true }) || resolveMenuItemByQuery((payload.transcript || '').toLowerCase(), { preferVisible: true });
      if (!resolved || !resolved.id) {
        showMessage(tUi('couldnt_find_item', { query: intent.query }));
        hideMessageSoon();
        return;
      }
      menuitemId = resolved.id;
      ordritemprice = resolved.price;
    }

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
    return;
  }

  if (type === 'remove_item') {
    // Remove by matching existing state order items to the resolved query
    const items = (window.__SM_STATE && window.__SM_STATE.order && Array.isArray(window.__SM_STATE.order.items)) ? window.__SM_STATE.order.items : [];
    if (!items.length) { showMessage(tUi('no_items_to_remove')); hideMessageSoon(); return; }

    let targetMenuitemId = intent.menuitem_id;
    if (!targetMenuitemId) targetMenuitemId = findMenuItemIdByQuery(intent.query);
    if (!targetMenuitemId) { showMessage(tUi('couldnt_find_item', { query: intent.query })); hideMessageSoon(); return; }

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

    if (!removed) {
      showMessage(tUi('no_matching_item_to_remove'));
      hideMessageSoon();
    }
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

  if (!navigator.mediaDevices?.getUserMedia) {
    throw new Error('Microphone not supported in this browser.');
  }

  const stream = await getOrCreateMicStream(constraints);

  // Mobile Safari often does not support audio/webm; forcing it causes MediaRecorder to throw.
  // Pick the first supported mimeType; if none are supported, omit the option and let the browser decide.
  const candidates = [
    'audio/webm;codecs=opus',
    'audio/webm',
    'audio/mp4',
    'audio/aac',
  ];
  const supported = candidates.find((t) => {
    try { return typeof MediaRecorder !== 'undefined' && MediaRecorder.isTypeSupported && MediaRecorder.isTypeSupported(t); } catch (_) { return false; }
  }) || null;

  let recorder;
  try {
    recorder = supported ? new MediaRecorder(stream, { mimeType: supported }) : new MediaRecorder(stream);
  } catch (e) {
    // If MediaRecorder cannot be created, release mic so we don't leave it open.
    stopMicStream();
    throw e;
  }
  const chunks = [];

  recorder.ondataavailable = (e) => { if (e.data && e.data.size) chunks.push(e.data); };

  recorder.start();

  return {
    stop: () => new Promise((resolve) => {
      recorder.onstop = () => {
        // Do not stop the underlying mic stream immediately; keep it briefly to avoid
        // repeated mobile permission banners on every press/hold.
        scheduleMicRelease();
        const blobType = supported || recorder.mimeType || '';
        const blob = blobType ? new Blob(chunks, { type: blobType }) : new Blob(chunks);
        resolve(blob);
      };
      try { recorder.stop(); } catch (_) { resolve(null); }
    }),
  };
}

export function initVoiceMenus() {
  try {
    const isCustomerView = !!document.querySelector('[data-testid="smartmenu-customer-view"]');
    const ctx = document.getElementById('contextContainer');
    const allowOrdering = (ctx?.dataset?.menuAllowOrdering || '') === '1';
    const voiceOrderingEnabled = (ctx?.dataset?.menuVoiceOrderingEnabled || '') === '1';
    const hasTableSelected = !!(ctx?.dataset?.tableId && String(ctx.dataset.tableId).trim().length);

    if (!(isCustomerView && allowOrdering && voiceOrderingEnabled && hasTableSelected)) {
      try { document.getElementById('voice-menu-ui')?.remove(); } catch (_) {}
      try { stopMicStream(); } catch (_) {}
      return;
    }
  } catch (_) {}

  ensureUi();

  const btn = document.getElementById('voice-ptt');
  if (!btn) return;
  if (btn.__voiceBound) return;
  btn.__voiceBound = true;

  // Help mobile browsers treat this as a deliberate gesture (avoid scroll/pinch interfering).
  try { btn.style.touchAction = 'none'; } catch (_) {}

  try { commonsInitOrderBindings(); } catch (_) {}

  // Ensure we don't keep the mic stream alive when the page is backgrounded/navigated away.
  (function bindMicCleanup() {
    if (window.__VOICE_MIC_CLEANUP_BOUND) return;
    window.__VOICE_MIC_CLEANUP_BOUND = true;

    try {
      window.addEventListener('pagehide', () => { try { stopMicStream(); } catch (_) {} }, { passive: true });
      document.addEventListener('visibilitychange', () => {
        if (document.visibilityState !== 'visible') {
          try { stopMicStream(); } catch (_) {}
        }
      }, { passive: true });
    } catch (_) {}
  })();

  let stopSpeech = null;
  let recorder = null;

  const locale = (document.querySelector('meta[name="current-locale"]')?.content || '').trim();

  const onDown = async () => {
    btn.disabled = true;
    setPttButtonState(true);

    try {
      if (canUseWebSpeech()) {
        stopSpeech = startWebSpeech(locale, async (transcript) => {
          const created = await sendTranscript(transcript, locale);
          if (!created || !created.id) { showMessage(tUi('failed_submit')); hideMessageSoon(); return; }
          const payload = await pollVoiceCommand(getSmartmenuSlug(), created.id);
          await executeIntent(payload);
        }, (e) => {
          showMessage(tUi('speech_failed'));
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
      const blob = await recorder.stop();
      recorder = null;

      if (!blob) { showMessage(tUi('no_audio_recorded')); hideMessageSoon(); return; }

      const created = await sendAudio(blob, locale);
      if (!created || !created.id) { showMessage(tUi('failed_submit')); hideMessageSoon(); return; }

      const payload = await pollVoiceCommand(getSmartmenuSlug(), created.id);
      await executeIntent(payload);
    } finally {
      btn.disabled = false;
      setPttButtonState(false);
    }
  };

  // Prefer Pointer Events; add touch/mouse fallbacks for older/mobile browsers.
  const bind = (name, fn, opts) => { try { btn.addEventListener(name, fn, opts); } catch (_) {} };

  bind('pointerdown', (e) => { try { e.preventDefault(); } catch (_) {} onDown(); }, { passive: false });
  bind('pointerup', (e) => { try { e.preventDefault(); } catch (_) {} onUp(); }, { passive: false });
  bind('pointercancel', (e) => { try { e.preventDefault(); } catch (_) {} onUp(); }, { passive: false });

  bind('touchstart', (e) => { try { e.preventDefault(); } catch (_) {} onDown(); }, { passive: false });
  bind('touchend', (e) => { try { e.preventDefault(); } catch (_) {} onUp(); }, { passive: false });
  bind('touchcancel', (e) => { try { e.preventDefault(); } catch (_) {} onUp(); }, { passive: false });

  bind('mousedown', (e) => { try { e.preventDefault(); } catch (_) {} onDown(); }, false);
  bind('mouseup', (e) => { try { e.preventDefault(); } catch (_) {} onUp(); }, false);
}
