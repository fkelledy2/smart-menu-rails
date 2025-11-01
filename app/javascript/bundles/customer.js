// Customer-facing functionality
import '../modules/menus/CustomerMenuModule.js';
import '../modules/orders/OrderModule.js';

// Only load order channel if order functionality is present
if (document.querySelector('[data-order-channel]')) {
  import('../channels/ordr_channel.js')
    .then(() => {
      console.log('[SmartMenu] Order channel loaded');
    })
    .catch((error) => {
      console.warn('[SmartMenu] Order channel not available:', error.message);
    });
}

console.log('[SmartMenu] Customer bundle loaded');
