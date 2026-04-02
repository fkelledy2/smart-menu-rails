import { Controller } from '@hotwired/stimulus';

/**
 * Concierge Controller — Customer-facing natural-language menu discovery.
 *
 * Targets:
 *   bar        — collapsed trigger bar
 *   panel      — expanded panel
 *   input      — textarea for query
 *   submitBtn  — send button
 *   loading    — spinner shown during fetch
 *   error      — error message container
 *   results    — item recommendation cards container
 *   basket     — basket preview container
 *
 * Values:
 *   url      (String) — POST endpoint for concierge queries
 *   currency (String) — restaurant currency code, e.g. 'EUR'
 */
export default class extends Controller {
  static targets = ['bar', 'panel', 'input', 'submitBtn', 'loading', 'error', 'results', 'basket'];
  static values = {
    url: String,
    currency: { type: String, default: 'EUR' },
  };

  connect() {
    this.conversationHistory = [];
    this.workflowRunId = null;
    this._abortController = null;
  }

  disconnect() {
    this._abortController?.abort();
  }

  escapeHtml(str) {
    return String(str ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  open() {
    this.panelTarget.classList.remove('d-none');
    this.panelTarget.classList.add('concierge-open');
    document.body.classList.add('concierge-active');
    this.inputTarget.focus();
  }

  close() {
    this.panelTarget.classList.add('d-none');
    this.panelTarget.classList.remove('concierge-open');
    document.body.classList.remove('concierge-active');
    this._abortController?.abort();
    this._clearResults();
  }

  handleKeydown(event) {
    // Submit on Enter (without Shift for newline)
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      this.submit();
    }
  }

  async submit() {
    const queryText = this.inputTarget.value.trim();
    if (!queryText) return;

    this._showLoading();
    this._hideError();
    this._hideResults();
    this.submitBtnTarget.disabled = true;

    // Abort any in-flight request
    this._abortController?.abort();
    this._abortController = new AbortController();

    const body = {
      query_text: queryText,
      conversation_history: this.conversationHistory.slice(-5),
    };
    if (this.workflowRunId) body.workflow_run_id = this.workflowRunId;

    try {
      const response = await fetch(this.urlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content ?? '',
        },
        body: JSON.stringify(body),
        signal: this._abortController.signal,
      });

      const data = await response.json();

      if (!response.ok || data.error) {
        this._showError(data.error || 'Recommendations unavailable right now — browse the menu below');
        return;
      }

      // Persist conversation context
      this.conversationHistory.push({ role: 'user', content: queryText });
      this.conversationHistory.push({
        role: 'assistant',
        content: `Recommended ${(data.items || []).length} items`,
      });
      if (data.workflow_run_id) this.workflowRunId = data.workflow_run_id;

      this._renderResults(data.items || [], data.basket);
    } catch (err) {
      if (err.name === 'AbortError') return;
      this._showError('Recommendations unavailable right now — browse the menu below');
    } finally {
      this._hideLoading();
      this.submitBtnTarget.disabled = false;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Private rendering helpers
  // ──────────────────────────────────────────────────────────────

  _renderResults(items, basket) {
    if (!items.length) {
      this._showError('No matching items found — try a different description');
      return;
    }

    const currency = this.currencyValue;
    const itemsHtml = items.map((item) => this._itemCardHtml(item, currency)).join('');

    this.resultsTarget.innerHTML = `
      <p class="concierge-results-label">${this.escapeHtml(`${items.length} suggestion${items.length !== 1 ? 's' : ''}`)}</p>
      <div class="concierge-items">${itemsHtml}</div>
    `;
    this.resultsTarget.classList.remove('d-none');

    if (basket && basket.items && basket.items.length) {
      this._renderBasket(basket, currency);
    }
  }

  _itemCardHtml(item, currency) {
    const name        = this.escapeHtml(item.name || '');
    const price       = this.escapeHtml(this._formatPrice(item.price, currency));
    const explanation = this.escapeHtml(item.explanation || '');

    return `
      <div class="concierge-item-card" data-item-id="${parseInt(item.id, 10) || 0}">
        <div class="concierge-item-info">
          <span class="concierge-item-name">${name}</span>
          <span class="concierge-item-price">${price}</span>
          ${explanation ? `<p class="concierge-item-explanation">${explanation}</p>` : ''}
        </div>
      </div>
    `;
  }

  _renderBasket(basket, currency) {
    const total    = this.escapeHtml(this._formatPrice(basket.total, currency));
    const count    = basket.item_count || basket.items.length;
    const forGroup = basket.group_size ? ` for ${basket.group_size} people` : '';

    const rowsHtml = (basket.items || []).map((item) => `
      <div class="concierge-basket-row">
        <span class="concierge-basket-item-name">${this.escapeHtml(item.name || '')}</span>
        <span class="concierge-basket-item-price">${this.escapeHtml(this._formatPrice(item.price, currency))}</span>
      </div>
    `).join('');

    this.basketTarget.innerHTML = `
      <div class="concierge-basket-header">
        <span class="concierge-basket-title">Suggested basket${this.escapeHtml(forGroup)} (${count} items)</span>
        <span class="concierge-basket-total">${total}</span>
      </div>
      <div class="concierge-basket-rows">${rowsHtml}</div>
    `;
    this.basketTarget.classList.remove('d-none');
  }

  _formatPrice(price, currency) {
    if (price == null) return '';
    try {
      return new Intl.NumberFormat(undefined, {
        style: 'currency',
        currency: currency || 'EUR',
        minimumFractionDigits: 2,
      }).format(price);
    } catch {
      return `${price}`;
    }
  }

  _showLoading() {
    this.loadingTarget.classList.remove('d-none');
  }

  _hideLoading() {
    this.loadingTarget.classList.add('d-none');
  }

  _showError(message) {
    this.errorTarget.textContent = message;
    this.errorTarget.classList.remove('d-none');
  }

  _hideError() {
    this.errorTarget.classList.add('d-none');
    this.errorTarget.textContent = '';
  }

  _hideResults() {
    this.resultsTarget.classList.add('d-none');
    this.resultsTarget.innerHTML = '';
    this.basketTarget.classList.add('d-none');
    this.basketTarget.innerHTML = '';
  }

  _clearResults() {
    this._hideResults();
    this._hideError();
    this._hideLoading();
    if (this.hasInputTarget) this.inputTarget.value = '';
  }
}
