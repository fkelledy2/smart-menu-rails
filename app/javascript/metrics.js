// Only run on pages that have the metrics container
export function initMetrics() {
  // Check if we're on a page that needs metrics
  if ($('#metrics-table').length === 0) return;

  // Check if user is authenticated - multiple checks for reliability
  const csrfToken = document.querySelector("meta[name='csrf-token']");
  const isHomePage = window.location.pathname === '/';
  const hasUserMenu = document.querySelector('.navbar .dropdown-toggle'); // User dropdown in navbar
  const hasLoginForm = document.querySelector('form[action*="sign_in"]'); // Login form present

  // If we're on the home page and there's no user menu, user is likely logged out
  if (isHomePage && !hasUserMenu) {
    console.log(
      '[Metrics] User appears to be logged out (home page, no user menu), skipping metrics load'
    );
    return;
  }

  // If there's a login form, user is definitely logged out
  if (hasLoginForm) {
    console.log('[Metrics] Login form detected, user not authenticated, skipping metrics load');
    return;
  }

  // If no CSRF token, definitely not authenticated
  if (!csrfToken) {
    console.log('[Metrics] No CSRF token, user not authenticated, skipping metrics load');
    return;
  }

  // Only load metrics once per page load
  if (window.metricsLoaded) return;

  // Set a flag to prevent multiple loads
  window.metricsLoaded = true;

  // Add loading state
  $('#metrics-table').addClass('loading');

  $.get('/metrics.json')
    .done(function (data) {
      if (!data || !data[0]) return;

      const currentMetrics = data[0];
      const numberOfRestaurants = currentMetrics.numberOfRestaurants;

      if (numberOfRestaurants > 100) {
        // Update all metrics at once to reduce reflows
        const metrics = [
          { id: 'metrics-numberOfRestaurants', value: numberOfRestaurants },
          { id: 'metrics-numberOfMenus', value: currentMetrics.numberOfMenus },
          { id: 'metrics-numberOfOrders', value: currentMetrics.numberOfOrders },
          {
            id: 'metrics-totalOrderValue',
            value: parseFloat(currentMetrics.totalOrderValue).toFixed(0),
          },
        ];

        metrics.forEach((metric) => {
          const element = document.getElementById(metric.id);
          if (element) element.textContent = metric.value;
        });

        $('#metrics-table').show();
      } else {
        $('#metrics-table').hide();
      }
    })
    .fail(function () {
      console.error('Failed to load metrics');
      $('#metrics-table').hide();
    })
    .always(function () {
      $('#metrics-table').removeClass('loading');
    });
}
