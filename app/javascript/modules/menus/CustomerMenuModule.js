/**
 * Customer Menu Module
 * Handles customer-facing menu functionality
 */

import { ComponentBase } from '../../components/ComponentBase.js';

export class CustomerMenuModule extends ComponentBase {
  constructor(container = document) {
    super(container);
    this.name = 'CustomerMenu';
    this.selectedItems = new Map();
  }

  init() {
    console.log('[CustomerMenuModule] Initializing customer menu functionality');

    this.setupEventListeners();
    this.initializeMenuItems();

    return this;
  }

  setupEventListeners() {
    // Menu item selection
    this.container.addEventListener('click', (event) => {
      if (event.target.matches('[data-menu-item]')) {
        this.handleMenuItemClick(event);
      }

      if (event.target.matches('[data-add-to-order]')) {
        this.handleAddToOrder(event);
      }

      if (event.target.matches('[data-menu-category]')) {
        this.handleCategoryClick(event);
      }
    });

    // Quantity changes
    this.container.addEventListener('change', (event) => {
      if (event.target.matches('[data-quantity-input]')) {
        this.handleQuantityChange(event);
      }
    });
  }

  initializeMenuItems() {
    // Initialize menu item displays
    const menuItems = this.container.querySelectorAll('[data-menu-item]');

    menuItems.forEach((item) => {
      this.setupMenuItem(item);
    });
  }

  setupMenuItem(itemElement) {
    const itemId = itemElement.dataset.menuItem;
    const price = parseFloat(itemElement.dataset.price || '0');

    // Add price formatting
    const priceElements = itemElement.querySelectorAll('[data-price]');
    priceElements.forEach((el) => {
      el.textContent = this.formatPrice(price);
    });

    // Initialize quantity controls
    const quantityInput = itemElement.querySelector('[data-quantity-input]');
    if (quantityInput) {
      quantityInput.value = '1';
    }
  }

  handleMenuItemClick(event) {
    const itemElement = event.currentTarget;
    const itemId = itemElement.dataset.menuItem;

    // Toggle selection
    if (itemElement.classList.contains('selected')) {
      this.deselectMenuItem(itemId, itemElement);
    } else {
      this.selectMenuItem(itemId, itemElement);
    }
  }

  selectMenuItem(itemId, itemElement) {
    itemElement.classList.add('selected');

    const itemData = {
      id: itemId,
      name: itemElement.dataset.name,
      price: parseFloat(itemElement.dataset.price || '0'),
      quantity: 1,
    };

    this.selectedItems.set(itemId, itemData);
    this.updateOrderSummary();

    console.log(`[CustomerMenuModule] Selected item: ${itemData.name}`);
  }

  deselectMenuItem(itemId, itemElement) {
    itemElement.classList.remove('selected');
    this.selectedItems.delete(itemId);
    this.updateOrderSummary();

    console.log(`[CustomerMenuModule] Deselected item: ${itemId}`);
  }

  handleAddToOrder(event) {
    const button = event.currentTarget;
    const itemId = button.dataset.addToOrder;
    const itemElement = button.closest('[data-menu-item]');

    if (itemElement) {
      this.selectMenuItem(itemId, itemElement);
      this.showAddedToOrderFeedback(button);
    }
  }

  handleCategoryClick(event) {
    const categoryButton = event.currentTarget;
    const category = categoryButton.dataset.menuCategory;

    // Show/hide menu items by category
    this.filterByCategory(category);

    // Update active category
    this.updateActiveCategoryButton(categoryButton);
  }

  handleQuantityChange(event) {
    const input = event.target;
    const itemElement = input.closest('[data-menu-item]');
    const itemId = itemElement?.dataset.menuItem;

    if (itemId && this.selectedItems.has(itemId)) {
      const quantity = parseInt(input.value) || 1;
      const itemData = this.selectedItems.get(itemId);
      itemData.quantity = quantity;

      this.updateOrderSummary();
    }
  }

  filterByCategory(category) {
    const menuItems = this.container.querySelectorAll('[data-menu-item]');

    menuItems.forEach((item) => {
      const itemCategory = item.dataset.category;

      if (category === 'all' || itemCategory === category) {
        item.style.display = '';
      } else {
        item.style.display = 'none';
      }
    });
  }

  updateActiveCategoryButton(activeButton) {
    // Remove active class from all category buttons
    const categoryButtons = this.container.querySelectorAll('[data-menu-category]');
    categoryButtons.forEach((btn) => btn.classList.remove('active'));

    // Add active class to clicked button
    activeButton.classList.add('active');
  }

  updateOrderSummary() {
    const summaryElement = this.container.querySelector('[data-order-summary]');
    if (!summaryElement) return;

    const totalItems = this.selectedItems.size;
    const totalPrice = Array.from(this.selectedItems.values()).reduce(
      (sum, item) => sum + item.price * item.quantity,
      0
    );

    // Update summary display
    const itemCountElement = summaryElement.querySelector('[data-item-count]');
    const totalPriceElement = summaryElement.querySelector('[data-total-price]');

    if (itemCountElement) {
      itemCountElement.textContent = totalItems;
    }

    if (totalPriceElement) {
      totalPriceElement.textContent = this.formatPrice(totalPrice);
    }

    // Show/hide summary based on selection
    if (totalItems > 0) {
      summaryElement.classList.add('has-items');
    } else {
      summaryElement.classList.remove('has-items');
    }
  }

  showAddedToOrderFeedback(button) {
    const originalText = button.textContent;
    button.textContent = 'Added!';
    button.classList.add('added');

    setTimeout(() => {
      button.textContent = originalText;
      button.classList.remove('added');
    }, 2000);
  }

  formatPrice(price) {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(price);
  }

  getSelectedItems() {
    return Array.from(this.selectedItems.values());
  }

  clearSelection() {
    this.selectedItems.clear();

    // Remove selected class from all items
    const selectedItems = this.container.querySelectorAll('[data-menu-item].selected');
    selectedItems.forEach((item) => item.classList.remove('selected'));

    this.updateOrderSummary();
  }

  destroy() {
    this.selectedItems.clear();
    super.destroy();
  }
}

export default CustomerMenuModule;
