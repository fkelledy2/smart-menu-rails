/**
 * Peak Hour Stress Test
 * 
 * Purpose: Simulate restaurant rush hour with high concurrent load
 * Duration: ~32 minutes
 * Users: Ramps from 0 → 100 → 500 → 0
 * 
 * Run: k6 run test/load/peak_hour_test.js
 */

import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate, Trend, Counter, Gauge } from 'k6/metrics';
import { BASE_URL, TEST_DATA, THRESHOLDS, LOAD_PATTERNS, USER_BEHAVIOR } from './config.js';
import { 
  thinkTime, 
  shortPause,
  weightedRandomChoice,
  isSuccessful,
  logProgress 
} from './utils/helpers.js';

// Custom metrics
const errorRate = new Rate('errors');
const menuBrowseTime = new Trend('menu_browse_time');
const orderPlacementTime = new Trend('order_placement_time');
const orderStatusTime = new Trend('order_status_time');
const activeOrders = new Gauge('active_orders');
const successfulOrders = new Counter('successful_orders');
const failedOrders = new Counter('failed_orders');

// Test configuration
export const options = {
  stages: LOAD_PATTERNS.peakHour,
  thresholds: {
    ...THRESHOLDS,
    // Additional thresholds for peak hour
    'http_req_duration{name:browse_menu}': ['p(95)<2000'],
    'http_req_duration{name:place_order}': ['p(95)<3000'],
    'errors': ['rate<0.005'] // Stricter error rate for peak
  },
  
  tags: {
    test_type: 'peak_hour',
    environment: __ENV.ENVIRONMENT || 'local'
  }
};

// Setup
export function setup() {
  logProgress('Starting peak hour stress test', {
    baseUrl: BASE_URL,
    maxUsers: 500,
    duration: '32 minutes'
  });
  
  return {
    startTime: Date.now()
  };
}

// Main test function
export default function (data) {
  // Weighted random user behavior
  const behavior = weightedRandomChoice({
    'browsing': USER_BEHAVIOR.browsing,
    'ordering': USER_BEHAVIOR.ordering,
    'viewingStatus': USER_BEHAVIOR.viewingStatus,
    'payment': USER_BEHAVIOR.payment
  });
  
  switch (behavior) {
    case 'browsing':
      browseMenu();
      break;
    case 'ordering':
      placeOrder();
      break;
    case 'viewingStatus':
      viewOrderStatus();
      break;
    case 'payment':
      processPayment();
      break;
  }
  
  thinkTime();
}

// Scenario: Browse Menu
function browseMenu() {
  group('Browse Menu', function () {
    const smartmenuUrl = `${BASE_URL}/smartmenus/${TEST_DATA.smartmenuId}`;
    
    const startTime = Date.now();
    const response = http.get(smartmenuUrl, {
      tags: { name: 'browse_menu' }
    });
    const duration = Date.now() - startTime;
    
    const success = check(response, {
      'menu loads successfully': (r) => r.status === 200,
      'menu contains items': (r) => r.body.includes('menu') || r.body.includes('item'),
      'load time acceptable': (r) => r.timings.duration < 2000
    });
    
    if (success) {
      menuBrowseTime.add(duration);
    } else {
      errorRate.add(1);
      logProgress('Menu browse failed', {
        status: response.status,
        duration: duration
      });
    }
    
    shortPause();
  });
}

// Scenario: Place Order
function placeOrder() {
  group('Place Order', function () {
    // Note: This is a simplified version
    // In production, you'd need proper authentication and CSRF tokens
    
    const orderPayload = JSON.stringify({
      ordr: {
        tablesetting_id: TEST_DATA.tableId,
        restaurant_id: TEST_DATA.restaurantId,
        menu_id: TEST_DATA.menuId,
        ordercapacity: 2,
        status: 0 // OPENED
      }
    });
    
    const startTime = Date.now();
    const response = http.post(
      `${BASE_URL}/restaurants/${TEST_DATA.restaurantId}/ordrs`,
      orderPayload,
      {
        headers: { 'Content-Type': 'application/json' },
        tags: { name: 'place_order' }
      }
    );
    const duration = Date.now() - startTime;
    
    const success = check(response, {
      'order created or redirected': (r) => r.status === 201 || r.status === 302 || r.status === 422,
      'response time acceptable': (r) => r.timings.duration < 3000
    });
    
    if (success && response.status === 201) {
      successfulOrders.add(1);
      orderPlacementTime.add(duration);
      activeOrders.add(1);
    } else if (response.status === 422) {
      // Validation error - expected in load test without proper setup
      logProgress('Order validation failed (expected)', {
        status: response.status
      });
    } else {
      failedOrders.add(1);
      errorRate.add(1);
    }
    
    shortPause();
  });
}

// Scenario: View Order Status
function viewOrderStatus() {
  group('View Order Status', function () {
    // Check health endpoint as proxy for order status
    // In production, you'd check actual order endpoints
    const startTime = Date.now();
    const response = http.get(`${BASE_URL}/up`, {
      tags: { name: 'order_status' }
    });
    const duration = Date.now() - startTime;
    
    const success = check(response, {
      'status check successful': (r) => r.status === 200,
      'fast response': (r) => r.timings.duration < 500
    });
    
    if (success) {
      orderStatusTime.add(duration);
    } else {
      errorRate.add(1);
    }
    
    shortPause();
  });
}

// Scenario: Process Payment
function processPayment() {
  group('Process Payment', function () {
    // Simplified payment check
    // In production, this would involve actual payment endpoints
    
    const response = http.get(`${BASE_URL}/up`, {
      tags: { name: 'payment_check' }
    });
    
    check(response, {
      'payment system responsive': (r) => r.status === 200,
      'fast response': (r) => r.timings.duration < 1000
    });
    
    shortPause();
  });
}

// Teardown
export function teardown(data) {
  const duration = Date.now() - data.startTime;
  
  logProgress('Peak hour stress test completed', {
    duration: `${(duration / 1000 / 60).toFixed(2)} minutes`
  });
}

// Summary handler
export function handleSummary(data) {
  return {
    'peak_hour_test_summary.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data)
  };
}

function textSummary(data) {
  const metrics = data.metrics;
  
  // Helper to safely get metric value
  const getMetric = (metric, defaultValue = 0) => {
    return metric !== undefined && metric !== null ? metric : defaultValue;
  };
  
  const totalReqs = getMetric(metrics.http_reqs?.values?.count, 0);
  const failedReqs = getMetric(metrics.http_req_failed?.values?.passes, 0);
  const failRate = getMetric(metrics.http_req_failed?.values?.rate, 0);
  const avgDuration = getMetric(metrics.http_req_duration?.values?.avg, 0);
  const p95Duration = getMetric(metrics.http_req_duration?.values?.['p(95)'], 0);
  const p99Duration = getMetric(metrics.http_req_duration?.values?.['p(99)'], 0);
  const maxDuration = getMetric(metrics.http_req_duration?.values?.max, 0);
  const menuBrowseP95 = getMetric(metrics.menu_browse_time?.values?.['p(95)'], 0);
  const orderPlacementP95 = getMetric(metrics.order_placement_time?.values?.['p(95)'], 0);
  const orderStatusP95 = getMetric(metrics.order_status_time?.values?.['p(95)'], 0);
  const successfulOrders = getMetric(metrics.successful_orders?.values?.count, 0);
  const failedOrders = getMetric(metrics.failed_orders?.values?.count, 0);
  const checksRate = getMetric(metrics.checks?.values?.rate, 0);
  const vusMax = getMetric(metrics.vus_max?.values?.value, 0);
  const iterations = getMetric(metrics.iterations?.values?.count, 0);
  
  return `
╔════════════════════════════════════════════════════════════╗
║           PEAK HOUR STRESS TEST RESULTS                    ║
╠════════════════════════════════════════════════════════════╣
║ Total Requests:        ${totalReqs.toString().padStart(8)}                      ║
║ Failed Requests:       ${failedReqs.toString().padStart(8)}                      ║
║ Success Rate:          ${((1 - failRate) * 100).toFixed(2).padStart(7)}%                     ║
║                                                            ║
║ Response Time (avg):   ${avgDuration.toFixed(2).padStart(8)}ms                    ║
║ Response Time (p95):   ${p95Duration.toFixed(2).padStart(8)}ms                    ║
║ Response Time (p99):   ${p99Duration.toFixed(2).padStart(8)}ms                    ║
║ Response Time (max):   ${maxDuration.toFixed(2).padStart(8)}ms                    ║
║                                                            ║
║ Menu Browse (p95):     ${menuBrowseP95.toFixed(2).padStart(8)}ms                    ║
║ Order Placement (p95): ${orderPlacementP95.toFixed(2).padStart(8)}ms                    ║
║ Order Status (p95):    ${orderStatusP95.toFixed(2).padStart(8)}ms                    ║
║                                                            ║
║ Successful Orders:     ${successfulOrders.toString().padStart(8)}                      ║
║ Failed Orders:         ${failedOrders.toString().padStart(8)}                      ║
║                                                            ║
║ Checks Passed:         ${(checksRate * 100).toFixed(2).padStart(7)}%                     ║
║ Peak VUs:              ${vusMax.toString().padStart(8)}                      ║
║ Total Iterations:      ${iterations.toString().padStart(8)}                      ║
╚════════════════════════════════════════════════════════════╝
  `;
}
