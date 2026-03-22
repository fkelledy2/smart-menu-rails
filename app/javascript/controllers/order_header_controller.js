import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static values = { customer: { type: Boolean, default: false } };

  connect() {
    this.render();
    document.addEventListener('state:order', () => this.render());
    document.addEventListener('state:changed', () => this.render());
  }

  render() {
    const container = this.element;
    const buttonGroup = container.querySelector('.order-button-group');
    if (!buttonGroup) return;

    const layoutGroup = buttonGroup.querySelector('.layout-toggle-group');
    if (!layoutGroup) return;

    // Remove any extra buttons after layout group (staff buttons)
    Array.from(buttonGroup.children).forEach((child, i) => {
      if (i > 0) child.remove();
    });

    // Add staff buttons if needed
    if (!this.customerValue) {
      const gs = window.__SM_STATE || {};
      const hasOrder = !!(gs.order && gs.order.id);

      if (hasOrder && gs.flags) {
        const btn = document.createElement('button');
        btn.className = 'btn-touch-secondary btn-touch-sm';
        btn.innerHTML = '<i class="bi bi-receipt"></i> Order';
        buttonGroup.appendChild(btn);
      }
    }

    container.style.visibility = 'visible';
  }
}
