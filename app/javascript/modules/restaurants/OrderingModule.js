// OrderingModule - hydrates the Ordering Dashboard (KPIs, charts, tables)
// v1: fetch KPIs/timeseries and render first charts with Chart.js

export const OrderingModule = {
  init(container = document) {
    try {
      const root = container;
      const wrapper = root.querySelector('#ordering-dashboard');
      if (!wrapper) return this; // not on this section
      this.container = root;
      this.wrapper = wrapper;
      this.restaurantId = wrapper.dataset.restaurantId;
      // Determine currency code from dataset or meta tag, fallback to USD
      const dsCode = (wrapper.dataset.currencyCode || '').toUpperCase();
      const metaCode = (document.querySelector('meta[name="restaurant-currency"]')?.content || '').toUpperCase();
      this.currencyCode = dsCode || metaCode || 'USD';
      this.charts = this.charts || {};
      if (this.initialized) {
        console.log('[OrderingModule] already initialized; refreshing');
        this.refresh();
        return this;
      }
      console.log('[OrderingModule] init for restaurant', this.restaurantId);
      this.bindUI();
      this.refresh();
      this.initialized = true;
      return this;
    } catch (e) {
      console.error('[OrderingModule] init failed', e);
      return this;
    }
  },

  renderHorizontalDualBar(canvasId, labels, qtyData, revenueData) {
    const canvas = this.q('#' + canvasId);
    const ctx = canvas;
    if (!ctx || !window.Chart) { return; }
    if (this.charts[canvasId]) { try { this.charts[canvasId].destroy(); } catch(_) {} }
    try {
      const targetH = Math.max(220, labels.length * 26 + 40);
      canvas.style.display = 'block';
      canvas.style.width = '100%';
      canvas.style.height = targetH + 'px';
      canvas.height = targetH;
      const parentW = canvas.parentElement ? canvas.parentElement.clientWidth : 600;
      canvas.width = Math.max(300, parentW);
    } catch(_) {}
    const fmt = this.getCurrencyFormatter();
    this.charts[canvasId] = new window.Chart(ctx, {
      type: 'bar',
      data: {
        labels,
        datasets: [
          { label: 'Qty', data: qtyData, backgroundColor: '#6f42c1', xAxisID: 'xQty' },
          { label: 'Revenue', data: revenueData, backgroundColor: '#0d6efd', xAxisID: 'xRev' },
        ],
      },
      options: {
        indexAxis: 'y',
        responsive: false,
        maintainAspectRatio: false,
        scales: {
          xQty: { position: 'top', beginAtZero: true, grid: { drawOnChartArea: false } },
          xRev: { position: 'bottom', beginAtZero: true, grid: { drawOnChartArea: true }, ticks: { callback: (v) => fmt(v) } },
          y: { ticks: { autoSkip: false, maxRotation: 0, minRotation: 0 } },
        },
        plugins: {
          tooltip: {
            callbacks: {
              label: (ctx) => ctx.dataset.label === 'Revenue' ? `Revenue: ${fmt(ctx.parsed.x)}` : `Qty: ${ctx.parsed.x}`,
            }
          },
        },
      },
    });
    console.log('[OrderingModule] chart rendered', canvasId, { bars: labels.length, orientation: 'horizontal' });
  },

  bindUI() {
    if (this._odBound) return;
    const range = this.q('#od-time-range');
    const compare = this.q('#od-compare');
    ['change', 'input'].forEach(evt => {
      range && range.addEventListener(evt, () => this.refresh());
      compare && compare.addEventListener(evt, () => this.refresh());
    });
    ['#od-filter-menu', '#od-filter-employee', '#od-filter-table', '#od-filter-status']
      .forEach(sel => { const el = this.q(sel); el && el.addEventListener('change', () => this.refresh()); });

    // Export buttons
    const expOrders = this.q('#od-export-orders');
    const expItems = this.q('#od-export-items');
    expOrders && expOrders.addEventListener('click', () => {
      if (this.tables?.orders) {
        const fname = `orders_${(new Date()).toISOString().slice(0,10)}.csv`;
        this.tables.orders.download('csv', fname);
      }
    });
    expItems && expItems.addEventListener('click', () => {
      if (this.tables?.items) {
        const fname = `items_${(new Date()).toISOString().slice(0,10)}.csv`;
        this.tables.items.download('csv', fname);
      }
    });
    this._odBound = true;
  },

  params() {
    const p = new URLSearchParams();
    const range = this.val('#od-time-range');
    const compare = this.q('#od-compare')?.checked ? 'true' : 'false';
    const menu = this.val('#od-filter-menu');
    const emp = this.val('#od-filter-employee');
    const table = this.val('#od-filter-table');
    const status = this.val('#od-filter-status');
    p.set('range', range || 'last28');
    p.set('compare', compare);
    if (range === 'custom') {
      const s = this.val('#od-start');
      const e = this.val('#od-end');
      if (s) p.set('start', s);
      if (e) p.set('end', e);
    }
    if (menu && menu !== 'all') p.set('menu_id', menu);
    if (emp && emp !== 'all') p.set('employee_id', emp);
    if (table && table !== 'all') p.set('table_id', table);
    if (status && status !== 'all') p.set('status', status);
    const s = p.toString();
    console.log('[OrderingModule] params', s);
    return s;
  },

  async refresh() {
    // Debounce rapid successive calls that can happen on frame/layout changes
    if (this._refreshTimer) clearTimeout(this._refreshTimer);
    this._refreshTimer = setTimeout(async () => {
      try {
        console.log('[OrderingModule] refresh start');
        this.renderLoading();
        await Promise.all([
          this.loadKpis(),
          this.loadTimeseries(),
          this.loadMenuMix(),
          this.loadTopItems(),
          this.loadStaffPerformance(),
          this.loadTablePerformance(),
        ]);
        await this.loadTables();
        console.log('[OrderingModule] refresh done');
      } catch (e) {
        console.error('[OrderingModule] refresh failed', e);
      }
    }, 100);
  },

  async loadKpis() {
    const url = `/restaurants/${this.restaurantId}/analytics/kpis?${this.params()}`;
    console.log('[OrderingModule] GET', url);
    const json = await this.fetchJSON(url);
    console.log('[OrderingModule] KPIs payload', json);
    const k = json?.kpis || {};
    const d = json?.deltas || {};
    this.updateKpiCard('gross', k.gross, d.gross);
    this.updateKpiCard('net', k.net, d.net);
    this.updateKpiCard('taxes', k.taxes, d.taxes);
    this.updateKpiCard('tips', k.tips, d.tips);
    this.updateKpiCard('service', k.service, d.service);
    this.updateKpiCard('orders', k.orders, d.orders);
    this.updateKpiCard('items', k.items, d.items);
    this.updateKpiCard('aov', k.aov, d.aov);
  },

  async loadTimeseries() {
    const url = `/restaurants/${this.restaurantId}/analytics/timeseries?${this.params()}`;
    console.log('[OrderingModule] GET', url);
    const json = await this.fetchJSON(url);
    console.log('[OrderingModule] Timeseries payload', json);
    const series = Array.isArray(json?.series) ? json.series : [];
    const labels = series.map(p => p.t);
    const gross = series.map(p => p.gross || 0);
    const net = series.map(p => p.net || 0);
    const orders = series.map(p => p.orders || 0);
    await this.ensureChartJs();
    this.renderLineChart('od-chart-revenue', labels, [
      { label: 'Gross', data: gross, borderColor: '#0d6efd' },
      { label: 'Net', data: net, borderColor: '#20c997' },
    ]);
    this.renderLineChart('od-chart-orders', labels, [
      { label: 'Orders', data: orders, borderColor: '#6f42c1' },
    ]);
  },

  updateKpiCard(key, value, delta) {
    const el = this.container.querySelector(`.od-kpi-card[data-kpi="${key}"]`);
    if (!el) return;
    const valEl = el.querySelector('[data-kpi-value]');
    const deltaEl = el.querySelector('[data-kpi-delta]');
    if (valEl) valEl.textContent = this.formatValue(key, value);
    if (deltaEl) deltaEl.textContent = this.formatDelta(delta);
  },

  formatValue(key, v) {
    if (v === null || v === undefined) return '—';
    if (['gross','net','taxes','tips','service','aov'].includes(key)) {
      const code = this.currencyCode || 'USD';
      try {
        return new Intl.NumberFormat(undefined, { style: 'currency', currency: code }).format(Number(v));
      } catch (e) {
        // Fallback if invalid code
        return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD' }).format(Number(v));
      }
    }
    return String(v);
  },

  formatDelta(d) {
    if (d === null || d === undefined) return '';
    const pct = Number(d);
    if (isNaN(pct)) return '';
    const sign = pct > 0 ? '+' : '';
    return `${sign}${pct.toFixed(1)}% vs prev`;
  },

  renderLoading() {
    // simple shimmer-free loading: clear deltas
    this.qAll('.od-kpi-card [data-kpi-delta]').forEach(el => el.textContent = '');
  },

  async ensureChartJs() {
    if (window.Chart) return;
    // Try to find existing script
    let script = document.querySelector('script[src*="cdn.jsdelivr.net/npm/chart.js"]');
    if (!script) {
      script = document.createElement('script');
      script.src = 'https://cdn.jsdelivr.net/npm/chart.js';
      script.async = true;
      document.head.appendChild(script);
    }
    await new Promise((resolve) => {
      let tries = 0;
      const maxTries = 80; // ~4s at 50ms
      const iv = setInterval(() => {
        if (window.Chart || ++tries >= maxTries) {
          clearInterval(iv);
          resolve();
        }
      }, 50);
      script.addEventListener('load', () => { resolve(); });
      script.addEventListener('error', () => { resolve(); });
    });
    if (!window.Chart) {
      console.warn('[OrderingModule] Chart.js failed to load; charts will be skipped');
    }
  },

  renderLineChart(canvasId, labels, datasets) {
    const canvas = this.q('#' + canvasId);
    const ctx = canvas;
    if (!ctx) { console.warn('[OrderingModule] canvas not found', canvasId); return; }
    if (!window.Chart) { console.warn('[OrderingModule] Chart.js unavailable'); return; }
    // Destroy existing chart if re-rendering
    if (this.charts[canvasId]) {
      try { this.charts[canvasId].destroy(); } catch(_) {}
    }
    // Ensure stable height to avoid vertical growth across renders
    try {
      const targetH = 220;
      canvas.style.display = 'block';
      canvas.style.width = '100%';
      canvas.style.height = targetH + 'px';
      // Fix pixel dimensions to prevent Chart.js responsive resizing loops
      canvas.height = targetH;
      const parentW = canvas.parentElement ? canvas.parentElement.clientWidth : 600;
      canvas.width = Math.max(300, parentW);
    } catch(_) {}
    const ds = datasets.map(d => ({
      label: d.label,
      data: d.data,
      borderColor: d.borderColor,
      backgroundColor: d.borderColor,
      borderWidth: 2,
      pointRadius: 0,
      tension: 0.3,
    }));
    this.charts[canvasId] = new window.Chart(ctx, {
      type: 'line',
      data: { labels, datasets: ds },
      options: {
        responsive: false,
        maintainAspectRatio: false,
        scales: { x: { display: true }, y: { display: true, beginAtZero: true } },
        plugins: { legend: { display: true }, tooltip: { mode: 'index', intersect: false } },
      },
    });
    console.log('[OrderingModule] chart rendered', canvasId, { points: labels.length });
  },

  renderBarChart(canvasId, labels, data, seriesLabel) {
    const canvas = this.q('#' + canvasId);
    const ctx = canvas;
    if (!ctx || !window.Chart) { return; }
    if (this.charts[canvasId]) { try { this.charts[canvasId].destroy(); } catch(_) {} }
    try {
      const targetH = 220;
      canvas.style.display = 'block';
      canvas.style.width = '100%';
      canvas.style.height = targetH + 'px';
      canvas.height = targetH;
      const parentW = canvas.parentElement ? canvas.parentElement.clientWidth : 600;
      canvas.width = Math.max(300, parentW);
    } catch(_) {}
    const fmt = this.getCurrencyFormatter();
    this.charts[canvasId] = new window.Chart(ctx, {
      type: 'bar',
      data: { labels, datasets: [{ label: seriesLabel, data, backgroundColor: '#0d6efd' }] },
      options: {
        responsive: false,
        maintainAspectRatio: false,
        scales: { x: { display: true }, y: { display: true, beginAtZero: true } },
        plugins: {
          legend: { display: false },
          tooltip: { callbacks: { label: (ctx) => fmt(ctx.parsed.y || ctx.parsed) } },
        },
      },
    });
    console.log('[OrderingModule] chart rendered', canvasId, { bars: labels.length });
  },

  renderDoughnutChart(canvasId, labels, data) {
    const canvas = this.q('#' + canvasId);
    const ctx = canvas;
    if (!ctx || !window.Chart) { return; }
    if (this.charts[canvasId]) { try { this.charts[canvasId].destroy(); } catch(_) {} }
    try {
      const targetH = 220;
      canvas.style.display = 'block';
      canvas.style.width = '100%';
      canvas.style.height = targetH + 'px';
      canvas.height = targetH;
      const parentW = canvas.parentElement ? canvas.parentElement.clientWidth : 600;
      canvas.width = Math.max(300, parentW);
    } catch(_) {}
    const colors = ['#0d6efd','#20c997','#6f42c1','#fd7e14','#dc3545','#198754','#0dcaf0','#6c757d','#6610f2','#d63384','#1982c4','#8ac926'];
    this.charts[canvasId] = new window.Chart(ctx, {
      type: 'doughnut',
      data: { labels, datasets: [{ data, backgroundColor: labels.map((_, i) => colors[i % colors.length]) }] },
      options: { responsive: false, maintainAspectRatio: false, plugins: { legend: { display: true } } },
    });
    console.log('[OrderingModule] chart rendered', canvasId, { slices: labels.length });
  },

  getCurrencyFormatter() {
    const code = this.currencyCode || 'USD';
    try {
      const intl = new Intl.NumberFormat(undefined, { style: 'currency', currency: code });
      return (n) => intl.format(Number(n || 0));
    } catch(_) {
      const intl = new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD' });
      return (n) => intl.format(Number(n || 0));
    }
  },

  async loadMenuMix() {
    const url = `/restaurants/${this.restaurantId}/analytics/menu_mix?${this.params()}`;
    console.log('[OrderingModule] GET', url);
    const json = await this.fetchJSON(url);
    const rows = Array.isArray(json?.data) ? json.data : [];
    await this.ensureChartJs();
    const labels = rows.map(r => r.menu_name || `#${r.menu_id}`);
    const data = rows.map(r => r.revenue || 0);
    this.renderDoughnutChart('od-chart-menu-mix', labels, data);
  },

  async loadTopItems() {
    const url = `/restaurants/${this.restaurantId}/analytics/top_items?${this.params()}`;
    console.log('[OrderingModule] GET', url);
    const json = await this.fetchJSON(url);
    const rows = Array.isArray(json?.data) ? json.data : [];
    await this.ensureChartJs();
    const labels = rows.map(r => r.item_name || `#${r.item_id}`);
    const qty = rows.map(r => r.qty || 0);
    const revenue = rows.map(r => r.revenue || 0);
    this.renderHorizontalDualBar('od-chart-top-items', labels, qty, revenue);
  },

  async loadStaffPerformance() {
    const url = `/restaurants/${this.restaurantId}/analytics/staff_performance?${this.params()}`;
    console.log('[OrderingModule] GET', url);
    const json = await this.fetchJSON(url);
    const rows = Array.isArray(json?.data) ? json.data : [];
    await this.ensureChartJs();
    const labels = rows.map(r => r.employee_name || `#${r.employee_id}`);
    const data = rows.map(r => r.revenue || 0);
    this.renderBarChart('od-chart-staff', labels, data, 'Revenue');
  },

  async loadTablePerformance() {
    const url = `/restaurants/${this.restaurantId}/analytics/table_performance?${this.params()}`;
    console.log('[OrderingModule] GET', url);
    const json = await this.fetchJSON(url);
    const rows = Array.isArray(json?.data) ? json.data : [];
    await this.ensureChartJs();
    const labels = rows.map(r => r.table_name || `#${r.table_id}`);
    const data = rows.map(r => r.revenue || 0);
    this.renderBarChart('od-chart-tables', labels, data, 'Revenue');
  },

  destroy() {
    try {
      Object.keys(this.charts || {}).forEach((key) => {
        try { this.charts[key].destroy(); } catch(_) {}
      });
    } catch(_) {}
    this.charts = {};
    try {
      if (this.tables?.orders) { this.tables.orders.destroy(); }
      if (this.tables?.items) { this.tables.items.destroy(); }
    } catch(_) {}
    this.tables = {};
    this.initialized = false;
    this._odBound = false;
    console.log('[OrderingModule] destroyed');
  },

  async fetchJSON(url) {
    const headers = {
      'X-Requested-With': 'XMLHttpRequest',
      'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")?.content || ''
    };
    const res = await fetch(url, { headers });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json();
  },

  val(sel) { return this.q(sel)?.value; },
  q(sel) { return this.container.querySelector(sel); },
  qAll(sel) { return Array.from(this.container.querySelectorAll(sel)); },

  async loadTables() {
    await Promise.all([this.loadOrdersTable(), this.loadItemsTable()]);
  },

  async loadOrdersTable() {
    const url = `/restaurants/${this.restaurantId}/analytics/orders?${this.params()}&page=1&per=50`;
    console.log('[OrderingModule] GET', url);
    const json = await this.fetchJSON(url);
    const rows = Array.isArray(json?.rows) ? json.rows : [];
    const container = this.q('#od-table-orders');
    if (!container) return;
    // Destroy prior table
    if (!this.tables) this.tables = {};
    if (this.tables.orders) { try { this.tables.orders.destroy(); } catch(_) {} }
    const twoDp = (cell) => {
      const n = Number(cell.getValue() ?? 0);
      return new Intl.NumberFormat(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(n);
    };
    // Build Tabulator
    this.tables.orders = new window.Tabulator(container, {
      layout: 'fitColumns',
      height: 300,
      columns: [
        { title: 'Date', field: 'created_at', sorter: 'datetime', width: 150 },
        { title: 'Status', field: 'status', sorter: 'string', width: 110 },
        { title: 'Menu', field: 'menu', sorter: 'string' },
        { title: 'Table', field: 'table', sorter: 'string' },
        { title: 'Employee', field: 'employee', sorter: 'string' },
        { title: 'Net', field: 'net', hozAlign: 'right', sorter: 'number', formatter: twoDp },
        { title: 'Tax', field: 'tax', hozAlign: 'right', sorter: 'number', formatter: twoDp },
        { title: 'Service', field: 'service', hozAlign: 'right', sorter: 'number', formatter: twoDp },
        { title: 'Tip', field: 'tip', hozAlign: 'right', sorter: 'number', formatter: twoDp },
        { title: 'Gross', field: 'gross', hozAlign: 'right', sorter: 'number', formatter: twoDp },
      ],
      data: rows,
      placeholder: 'No orders',
    });
  },

  async loadItemsTable() {
    const url = `/restaurants/${this.restaurantId}/analytics/items?${this.params()}&page=1&per=50`;
    console.log('[OrderingModule] GET', url);
    const json = await this.fetchJSON(url);
    const rows = Array.isArray(json?.rows) ? json.rows : [];
    const container = this.q('#od-table-items');
    if (!container) return;
    if (!this.tables) this.tables = {};
    if (this.tables.items) { try { this.tables.items.destroy(); } catch(_) {} }
    const twoDp = (cell) => {
      const n = Number(cell.getValue() ?? 0);
      return new Intl.NumberFormat(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(n);
    };
    this.tables.items = new window.Tabulator(container, {
      layout: 'fitColumns',
      height: 300,
      columns: [
        { title: 'Date', field: 'created_at', sorter: 'datetime', width: 150 },
        { title: 'Order', field: 'ordr_id', sorter: 'number', width: 100 },
        { title: 'Item', field: 'item', sorter: 'string' },
        { title: 'Revenue', field: 'revenue', hozAlign: 'right', sorter: 'number', formatter: twoDp },
      ],
      data: rows,
      placeholder: 'No items',
    });
  },
};

// Make available globally for inline initializers if needed
if (typeof window !== 'undefined') {
  window.OrderingModule = OrderingModule;
}
