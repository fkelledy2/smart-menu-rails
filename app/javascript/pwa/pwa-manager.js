/**
 * PWA Manager
 * Handles service worker registration, install prompts, and PWA lifecycle
 */

class PWAManager {
  constructor() {
    this.deferredPrompt = null;
    this.isInstalled = false;
    this.serviceWorkerRegistration = null;

    this.init();
  }

  async init() {
    console.log('[PWA] Initializing PWA Manager');

    // Check if PWA is already installed
    this.checkInstallStatus();

    // Register service worker
    await this.registerServiceWorker();

    // Setup event listeners
    this.setupEventListeners();

    // Setup install prompt
    this.setupInstallPrompt();

    // Initialize push notifications
    this.initializePushNotifications();

    console.log('[PWA] PWA Manager initialized successfully');
  }

  checkInstallStatus() {
    // Check if app is running in standalone mode (installed)
    this.isInstalled =
      window.matchMedia('(display-mode: standalone)').matches ||
      window.navigator.standalone === true ||
      document.referrer.includes('android-app://');

    if (this.isInstalled) {
      console.log('[PWA] App is running as installed PWA');
      document.body.classList.add('pwa-installed');
    } else {
      console.log('[PWA] App is running in browser');
      document.body.classList.add('pwa-browser');
    }
  }

  async registerServiceWorker() {
    if (!('serviceWorker' in navigator)) {
      console.warn('[PWA] Service Worker not supported');
      return;
    }

    try {
      const registration = await navigator.serviceWorker.register('/pwa/service-worker.js', {
        scope: '/',
      });

      this.serviceWorkerRegistration = registration;

      console.log('[PWA] Service Worker registered successfully');

      // Handle service worker updates
      registration.addEventListener('updatefound', () => {
        const newWorker = registration.installing;

        newWorker.addEventListener('statechange', () => {
          if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
            console.log('[PWA] New service worker available');
            this.showUpdatePrompt();
          }
        });
      });

      // Listen for service worker messages
      navigator.serviceWorker.addEventListener('message', (event) => {
        this.handleServiceWorkerMessage(event);
      });
    } catch (error) {
      console.error('[PWA] Service Worker registration failed:', error);
    }
  }

  setupEventListeners() {
    // Install prompt event
    window.addEventListener('beforeinstallprompt', (e) => {
      console.log('[PWA] Install prompt available');
      e.preventDefault();
      this.deferredPrompt = e;
      this.showInstallButton();
    });

    // App installed event
    window.addEventListener('appinstalled', () => {
      console.log('[PWA] App installed successfully');
      this.isInstalled = true;
      this.hideInstallButton();
      this.trackInstallation();
      this.showInstallSuccessMessage();
    });

    // Online/offline events
    window.addEventListener('online', () => {
      console.log('[PWA] App is online');
      this.handleOnlineStatus(true);
    });

    window.addEventListener('offline', () => {
      console.log('[PWA] App is offline');
      this.handleOnlineStatus(false);
    });

    // Visibility change (for background sync)
    document.addEventListener('visibilitychange', () => {
      if (!document.hidden && navigator.serviceWorker.controller) {
        // App became visible, trigger sync if needed
        this.triggerBackgroundSync();
      }
    });
  }

  setupInstallPrompt() {
    // Create install button if not already installed
    if (!this.isInstalled) {
      this.createInstallButton();
    }
  }

  createInstallButton() {
    // Check if install button already exists
    if (document.getElementById('pwa-install-button')) {
      return;
    }

    const installButton = document.createElement('button');
    installButton.id = 'pwa-install-button';
    installButton.className = 'btn btn-primary pwa-install-btn';
    installButton.innerHTML = `
      <i class="bi bi-download"></i>
      Install App
    `;
    installButton.style.display = 'none';

    installButton.addEventListener('click', () => {
      this.showInstallPrompt();
    });

    // Add to appropriate location in the UI
    const navbar = document.querySelector('.navbar');
    if (navbar) {
      navbar.appendChild(installButton);
    } else {
      document.body.appendChild(installButton);
    }
  }

  showInstallButton() {
    const installButton = document.getElementById('pwa-install-button');
    if (installButton && !this.isInstalled) {
      installButton.style.display = 'block';

      // Show install banner after a delay
      setTimeout(() => {
        this.showInstallBanner();
      }, 3000);
    }
  }

  hideInstallButton() {
    const installButton = document.getElementById('pwa-install-button');
    if (installButton) {
      installButton.style.display = 'none';
    }
    this.hideInstallBanner();
  }

  showInstallBanner() {
    // Don't show if already shown recently
    if (localStorage.getItem('pwa-install-banner-dismissed')) {
      return;
    }

    const banner = document.createElement('div');
    banner.id = 'pwa-install-banner';
    banner.className = 'alert alert-info pwa-install-banner';
    banner.innerHTML = `
      <div class="d-flex justify-content-between align-items-center">
        <div>
          <strong>Install Smart Menu</strong>
          <p class="mb-0">Get the full app experience with offline access and faster loading.</p>
        </div>
        <div>
          <button class="btn btn-primary btn-sm me-2" onclick="window.pwaManager.showInstallPrompt()">
            Install
          </button>
          <button class="btn btn-outline-secondary btn-sm" onclick="window.pwaManager.dismissInstallBanner()">
            Not now
          </button>
        </div>
      </div>
    `;

    document.body.insertBefore(banner, document.body.firstChild);
  }

  hideInstallBanner() {
    const banner = document.getElementById('pwa-install-banner');
    if (banner) {
      banner.remove();
    }
  }

  dismissInstallBanner() {
    this.hideInstallBanner();
    localStorage.setItem('pwa-install-banner-dismissed', Date.now().toString());
  }

  async showInstallPrompt() {
    if (!this.deferredPrompt) {
      console.warn('[PWA] Install prompt not available');
      return;
    }

    try {
      const result = await this.deferredPrompt.prompt();
      console.log('[PWA] Install prompt result:', result.outcome);

      if (result.outcome === 'accepted') {
        console.log('[PWA] User accepted the install prompt');
      } else {
        console.log('[PWA] User dismissed the install prompt');
      }

      this.deferredPrompt = null;
    } catch (error) {
      console.error('[PWA] Install prompt failed:', error);
    }
  }

  showUpdatePrompt() {
    const updateBanner = document.createElement('div');
    updateBanner.id = 'pwa-update-banner';
    updateBanner.className = 'alert alert-warning pwa-update-banner';
    updateBanner.innerHTML = `
      <div class="d-flex justify-content-between align-items-center">
        <div>
          <strong>App Update Available</strong>
          <p class="mb-0">A new version of Smart Menu is available.</p>
        </div>
        <div>
          <button class="btn btn-warning btn-sm me-2" onclick="window.pwaManager.applyUpdate()">
            Update Now
          </button>
          <button class="btn btn-outline-secondary btn-sm" onclick="this.parentElement.parentElement.parentElement.remove()">
            Later
          </button>
        </div>
      </div>
    `;

    document.body.insertBefore(updateBanner, document.body.firstChild);
  }

  async applyUpdate() {
    if (this.serviceWorkerRegistration && this.serviceWorkerRegistration.waiting) {
      // Tell the waiting service worker to skip waiting and become active
      this.serviceWorkerRegistration.waiting.postMessage({ type: 'SKIP_WAITING' });

      // Reload the page to use the new service worker
      window.location.reload();
    }
  }

  handleOnlineStatus(isOnline) {
    const statusIndicator = this.getOrCreateStatusIndicator();

    if (isOnline) {
      statusIndicator.className = 'pwa-status-indicator online';
      statusIndicator.innerHTML = '<i class="bi bi-wifi"></i> Online';

      // Trigger background sync when coming online
      this.triggerBackgroundSync();
    } else {
      statusIndicator.className = 'pwa-status-indicator offline';
      statusIndicator.innerHTML = '<i class="bi bi-wifi-off"></i> Offline';
    }
  }

  getOrCreateStatusIndicator() {
    let indicator = document.getElementById('pwa-status-indicator');

    if (!indicator) {
      indicator = document.createElement('div');
      indicator.id = 'pwa-status-indicator';
      indicator.className = 'pwa-status-indicator';

      // Add to navbar or create floating indicator
      const navbar = document.querySelector('.navbar');
      if (navbar) {
        navbar.appendChild(indicator);
      } else {
        indicator.style.cssText = `
          position: fixed;
          top: 10px;
          right: 10px;
          z-index: 1050;
          padding: 5px 10px;
          border-radius: 4px;
          font-size: 12px;
        `;
        document.body.appendChild(indicator);
      }
    }

    return indicator;
  }

  async initializePushNotifications() {
    if (!('Notification' in window) || !('serviceWorker' in navigator)) {
      console.warn('[PWA] Push notifications not supported');
      return;
    }

    // Check current permission status
    const permission = Notification.permission;
    console.log('[PWA] Notification permission:', permission);

    if (permission === 'granted') {
      await this.subscribeToPushNotifications();
    } else if (permission === 'default') {
      // Show notification permission prompt later
      this.showNotificationPermissionPrompt();
    }
  }

  showNotificationPermissionPrompt() {
    // Show after user interaction to avoid blocking
    setTimeout(() => {
      if (Notification.permission === 'default') {
        const banner = document.createElement('div');
        banner.className = 'alert alert-info pwa-notification-banner';
        banner.innerHTML = `
          <div class="d-flex justify-content-between align-items-center">
            <div>
              <strong>Stay Updated</strong>
              <p class="mb-0">Enable notifications to get real-time order updates.</p>
            </div>
            <div>
              <button class="btn btn-primary btn-sm me-2" onclick="window.pwaManager.requestNotificationPermission()">
                Enable
              </button>
              <button class="btn btn-outline-secondary btn-sm" onclick="this.parentElement.parentElement.parentElement.remove()">
                Not now
              </button>
            </div>
          </div>
        `;

        document.body.insertBefore(banner, document.body.firstChild);
      }
    }, 5000);
  }

  async requestNotificationPermission() {
    try {
      const permission = await Notification.requestPermission();

      if (permission === 'granted') {
        console.log('[PWA] Notification permission granted');
        await this.subscribeToPushNotifications();

        // Remove permission banner
        const banner = document.querySelector('.pwa-notification-banner');
        if (banner) banner.remove();

        // Show success message
        this.showNotificationSuccessMessage();
      } else {
        console.log('[PWA] Notification permission denied');
      }
    } catch (error) {
      console.error('[PWA] Notification permission request failed:', error);
    }
  }

  async subscribeToPushNotifications() {
    if (!this.serviceWorkerRegistration) {
      console.warn('[PWA] Service worker not registered');
      return;
    }

    try {
      // Get existing subscription
      let subscription = await this.serviceWorkerRegistration.pushManager.getSubscription();

      if (!subscription) {
        // Create new subscription
        const vapidPublicKey = await this.getVapidPublicKey();

        subscription = await this.serviceWorkerRegistration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: this.urlBase64ToUint8Array(vapidPublicKey),
        });

        console.log('[PWA] Push subscription created');
      }

      // Send subscription to server
      await this.sendSubscriptionToServer(subscription);
    } catch (error) {
      console.error('[PWA] Push subscription failed:', error);
    }
  }

  async getVapidPublicKey() {
    // This should be fetched from your server or configured
    // For now, return a placeholder
    return 'YOUR_VAPID_PUBLIC_KEY_HERE';
  }

  urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
    const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');

    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
  }

  async sendSubscriptionToServer(subscription) {
    try {
      const response = await fetch('/api/push_subscriptions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
        },
        body: JSON.stringify({
          subscription: {
            endpoint: subscription.endpoint,
            p256dh_key: btoa(
              String.fromCharCode.apply(null, new Uint8Array(subscription.getKey('p256dh')))
            ),
            auth_key: btoa(
              String.fromCharCode.apply(null, new Uint8Array(subscription.getKey('auth')))
            ),
          },
        }),
      });

      if (response.ok) {
        console.log('[PWA] Subscription sent to server successfully');
      } else {
        console.error('[PWA] Failed to send subscription to server');
      }
    } catch (error) {
      console.error('[PWA] Error sending subscription to server:', error);
    }
  }

  triggerBackgroundSync() {
    if ('serviceWorker' in navigator && 'sync' in window.ServiceWorkerRegistration.prototype) {
      navigator.serviceWorker.ready
        .then((registration) => {
          // Trigger different sync events
          registration.sync.register('order-sync');
          registration.sync.register('menu-sync');
          registration.sync.register('analytics-sync');
        })
        .catch((error) => {
          console.error('[PWA] Background sync registration failed:', error);
        });
    }
  }

  handleServiceWorkerMessage(event) {
    const { type, data } = event.data;

    switch (type) {
      case 'CACHE_UPDATED':
        console.log('[PWA] Cache updated:', data);
        break;
      case 'SYNC_COMPLETE':
        console.log('[PWA] Background sync complete:', data);
        this.showSyncCompleteMessage(data);
        break;
      case 'OFFLINE_ACTION_QUEUED':
        console.log('[PWA] Action queued for offline sync:', data);
        this.showOfflineActionMessage(data);
        break;
      default:
        console.log('[PWA] Service worker message:', type, data);
    }
  }

  showInstallSuccessMessage() {
    this.showToast('App installed successfully! You can now use Smart Menu offline.', 'success');
  }

  showNotificationSuccessMessage() {
    this.showToast("Notifications enabled! You'll receive real-time updates.", 'success');
  }

  showSyncCompleteMessage(data) {
    this.showToast(`${data.count || 0} items synced successfully`, 'info');
  }

  showOfflineActionMessage(data) {
    this.showToast(`Action saved. Will sync when online.`, 'warning');
  }

  showToast(message, type = 'info') {
    // Create toast notification
    const toast = document.createElement('div');
    toast.className = `toast align-items-center text-white bg-${type} border-0`;
    toast.setAttribute('role', 'alert');
    toast.innerHTML = `
      <div class="d-flex">
        <div class="toast-body">${message}</div>
        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
      </div>
    `;

    // Add to toast container
    let container = document.querySelector('.toast-container');
    if (!container) {
      container = document.createElement('div');
      container.className = 'toast-container position-fixed top-0 end-0 p-3';
      container.style.zIndex = '1055';
      document.body.appendChild(container);
    }

    container.appendChild(toast);

    // Show toast
    if (window.bootstrap && window.bootstrap.Toast) {
      const bsToast = new window.bootstrap.Toast(toast, { delay: 5000 });
      bsToast.show();

      toast.addEventListener('hidden.bs.toast', () => {
        toast.remove();
      });
    } else {
      // Fallback without Bootstrap
      toast.style.display = 'block';
      setTimeout(() => {
        toast.remove();
      }, 5000);
    }
  }

  trackInstallation() {
    // Track PWA installation
    if (typeof gtag !== 'undefined') {
      gtag('event', 'pwa_install', {
        event_category: 'PWA',
        event_label: 'App Installed',
      });
    }

    // Send to server analytics
    fetch('/api/analytics/events', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector("meta[name='csrf-token']").content,
      },
      body: JSON.stringify({
        event: 'pwa_installed',
        properties: {
          timestamp: new Date().toISOString(),
          user_agent: navigator.userAgent,
        },
      }),
    }).catch((error) => {
      console.error('[PWA] Failed to track installation:', error);
    });
  }
}

// Initialize PWA Manager when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    window.pwaManager = new PWAManager();
  });
} else {
  window.pwaManager = new PWAManager();
}

export default PWAManager;
