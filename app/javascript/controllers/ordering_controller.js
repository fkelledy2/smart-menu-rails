import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="ordering"
export default class extends Controller {
  connect() {
    try {
      const root = this.element;
      if (!root) return;
      if (root.dataset.odInitialized === 'true') return;
      root.dataset.odInitialized = 'true';
      console.log('[OrderingDashboard][Stimulus] connect -> initializing module');

      // Defer one microtask to ensure DOM is settled
      Promise.resolve().then(() => {
        if (window.OrderingModule && typeof window.OrderingModule.init === 'function') {
          window.OrderingModule.init(document);
        } else {
          console.warn('[OrderingDashboard][Stimulus] OrderingModule not found on window');
        }
      });
    } catch (e) {
      console.warn('[OrderingDashboard][Stimulus] connect failed', e);
    }
  }

  disconnect() {
    // No-op for now; OrderingModule handles its own cleanup if needed
  }
}
