document.addEventListener("turbo:load", () => {

    $.get( "/metrics.json", function(data) {
      var currentMetrics = data[0];
      var numberOfRestaurants = currentMetrics.numberOfRestaurants;
      if( numberOfRestaurants > 100 ) {
          $('#metrics-numberOfRestaurants').html(numberOfRestaurants);
          var numberOfMenus = currentMetrics.numberOfMenus;
          $('#metrics-numberOfMenus').html(numberOfMenus);
          var numberOfOrders = currentMetrics.numberOfOrders;
          $('#metrics-numberOfOrders').html(numberOfOrders);
          var totalOrderValue = currentMetrics.totalOrderValue;
          $('#metrics-totalOrderValue').html(parseFloat(totalOrderValue).toFixed(0));
      } else {
          $('#metrics-table').hide();
          $('#testimonials').hide();
      }
    });
})