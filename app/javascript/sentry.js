// Sentry JavaScript Error Tracking
// Initializes Sentry for frontend error tracking and performance monitoring

import * as Sentry from '@sentry/browser';

// Initialize Sentry only if DSN is configured
const sentryDsn = document.querySelector('meta[name="sentry-dsn"]')?.content;
const sentryEnvironment = document.querySelector('meta[name="sentry-environment"]')?.content || 'development';
const sentryRelease = document.querySelector('meta[name="sentry-release"]')?.content || 'unknown';

if (sentryDsn && sentryEnvironment !== 'test' && sentryEnvironment !== 'development') {
  Sentry.init({
    dsn: sentryDsn,
    environment: sentryEnvironment,
    release: sentryRelease,

    // Performance Monitoring
    tracesSampleRate: sentryEnvironment === 'production' ? 0.1 : 1.0,

    // Session Replay (optional - can be enabled later)
    // replaysSessionSampleRate: 0.1,
    // replaysOnErrorSampleRate: 1.0,

    // Integrations
    integrations: [
      // Automatic instrumentation
      Sentry.browserTracingIntegration({
        // Track navigation and page loads
        tracePropagationTargets: ['localhost', /^\//],
      }),
    ],

    // Filter sensitive data before sending
    beforeSend(event, hint) {
      // Remove sensitive form data
      if (event.request?.data) {
        const sensitiveFields = [
          'password',
          'password_confirmation',
          'current_password',
          'credit_card_number',
          'cvv',
          'ssn',
          'api_key',
          'access_token',
        ];

        sensitiveFields.forEach((field) => {
          if (event.request.data[field]) {
            event.request.data[field] = '[Filtered]';
          }
        });
      }

      // Filter out certain errors
      if (hint.originalException) {
        const error = hint.originalException;

        // Ignore network errors from ad blockers
        if (error.message && error.message.includes('Failed to fetch')) {
          return null;
        }

        // Ignore ResizeObserver errors (common browser quirk)
        if (error.message && error.message.includes('ResizeObserver')) {
          return null;
        }
      }

      return event;
    },

    // Ignore certain errors
    ignoreErrors: [
      // Browser extensions
      'top.GLOBALS',
      'chrome-extension://',
      'moz-extension://',
      // Random plugins/extensions
      'fb_xd_fragment',
      // Network errors
      'NetworkError',
      'Network request failed',
      // Common browser errors
      'ResizeObserver loop limit exceeded',
      'ResizeObserver loop completed with undelivered notifications',
    ],
  });

  // Set user context if available
  const userEmail = document.querySelector('meta[name="current-user-email"]')?.content;
  const userId = document.querySelector('meta[name="current-user-id"]')?.content;

  if (userId) {
    Sentry.setUser({
      id: userId,
      email: userEmail,
    });
  }

  // Add custom tags
  Sentry.setTag('component', 'javascript');
  Sentry.setTag('framework', 'rails');

  // Export for use in other modules
  window.Sentry = Sentry;
}

export default Sentry;
