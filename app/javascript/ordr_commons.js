// Common order helpers shared by ordrs.js and channels/ordr_channel.js

export function post(url, body) {
  try { $('#orderCart').hide(); } catch (_) {}
  try { $('#orderCartSpinner').show(); } catch (_) {}

  const csrfToken = document.querySelector("meta[name='csrf-token']")?.content || '';

  try { window.dispatchEvent(new CustomEvent('ordr:request:start', { detail: { method: 'POST', url, body, timestamp: Date.now() } })); } catch (_) {}

  return fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'X-CSRF-Token': csrfToken,
    },
    body: JSON.stringify(body),
  })
    .then((response) => {
      if (!response.ok) throw new Error('Network response was not ok.');
      return response.json().catch(() => ({}));
    })
    .then((data) => {
      try { $('#orderCartSpinner').hide(); } catch (_) {}
      try { $('#orderCart').show(); } catch (_) {}
      try { window.dispatchEvent(new CustomEvent('ordr:request:complete', { detail: { method: 'POST', url, status: 200, timestamp: Date.now() } })); } catch (_) {}
      return data;
    })
    .catch((error) => {
      try { $('#orderCartSpinner').hide(); } catch (_) {}
      try { $('#orderCart').show(); } catch (_) {}
      try { window.dispatchEvent(new CustomEvent('ordr:request:error', { detail: { method: 'POST', url, error: String(error), timestamp: Date.now() } })); } catch (_) {}
      throw error;
    });
}

export function patch(url, body) {
  try { $('#orderCart').hide(); } catch (_) {}
  try { $('#orderCartSpinner').show(); } catch (_) {}

  const csrfToken = document.querySelector("meta[name='csrf-token']")?.content || '';

  try { window.dispatchEvent(new CustomEvent('ordr:request:start', { detail: { method: 'PATCH', url, body, timestamp: Date.now() } })); } catch (_) {}

  return fetch(url, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'X-CSRF-Token': csrfToken,
    },
    body: JSON.stringify(body),
  })
    .then((response) => {
      if (!response.ok) throw new Error('Network response was not ok.');
      return response.json().catch(() => ({}));
    })
    .then((data) => {
      try { $('#orderCartSpinner').hide(); } catch (_) {}
      try { $('#orderCart').show(); } catch (_) {}
      return data;
    })
    .catch((error) => {
      try { $('#orderCartSpinner').hide(); } catch (_) {}
      try { $('#orderCart').show(); } catch (_) {}
      throw error;
    });
}

export function getCurrentOrderId() {
  const fromHidden = document.getElementById('currentOrder')?.textContent?.trim();
  if (fromHidden) return fromHidden;
  const fromPay = document.getElementById('openOrderId')?.value?.trim();
  if (fromPay) return fromPay;
  return null;
}

export function getCurrentTableId() {
  const fromHidden = document.getElementById('currentTable')?.textContent?.trim();
  if (fromHidden) return fromHidden;
  return null;
}

export function getCurrentMenuId() {
  const fromHidden = document.getElementById('currentMenu')?.textContent?.trim();
  if (fromHidden) return fromHidden;
  return null;
}
