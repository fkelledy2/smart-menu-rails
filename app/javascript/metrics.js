// Only run on pages that have the metrics container
export function initMetrics() {
  // Check if we're on a page that needs metrics
  if ($('#metrics-table').length === 0) return;

  // Only load metrics once per page load
  if (window.metricsLoaded) return;
  
  // Set a flag to prevent multiple loads
  window.metricsLoaded = true;

  // Add loading state
  $('#metrics-table').addClass('loading');

  $.get("/metrics.json")
    .done(function(data) {
      if (!data || !data[0]) return;
      
      const currentMetrics = data[0];
      const numberOfRestaurants = currentMetrics.numberOfRestaurants;
      
      if (numberOfRestaurants > 100) {
        // Update all metrics at once to reduce reflows
        const metrics = [
          { id: 'metrics-numberOfRestaurants', value: numberOfRestaurants },
          { id: 'metrics-numberOfMenus', value: currentMetrics.numberOfMenus },
          { id: 'metrics-numberOfOrders', value: currentMetrics.numberOfOrders },
          { id: 'metrics-totalOrderValue', value: parseFloat(currentMetrics.totalOrderValue).toFixed(0) }
        ];
        
        metrics.forEach(metric => {
          const element = document.getElementById(metric.id);
          if (element) element.textContent = metric.value;
        });
        
        $('#metrics-table').show();
      } else {
        $('#metrics-table').hide();
      }
    })
    .fail(function() {
      console.error('Failed to load metrics');
      $('#metrics-table').hide();
    })
    .always(function() {
      $('#metrics-table').removeClass('loading');
    });
};