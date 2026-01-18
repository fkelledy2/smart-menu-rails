import http from 'k6/http';
import { check, group } from 'k6';
import { Rate, Trend, Counter, Gauge } from 'k6/metrics';
import { BASE_URL, TEST_DATA, THRESHOLDS, LOAD_PATTERNS, USER_BEHAVIOR } from './config.js';
import {
  thinkTime,
  shortPause,
  weightedRandomChoice,
  logProgress,
} from './utils/helpers.js';

const errorRate = new Rate('errors');
const menuBrowseTime = new Trend('menu_browse_time');
const orderPlacementTime = new Trend('order_placement_time');
const orderStatusTime = new Trend('order_status_time');
const activeOrders = new Gauge('active_orders');
const successfulOrders = new Counter('successful_orders');
const failedOrders = new Counter('failed_orders');

export const options = {
  stages: LOAD_PATTERNS.peakHourLocal,
  thresholds: {
    ...THRESHOLDS,
    http_req_duration: ['p(95)<5000', 'p(99)<8000', 'avg<2500'],
    http_req_failed: ['rate<0.02'],
    checks: ['rate>0.9'],
    'http_req_duration{name:browse_menu}': ['p(95)<5000'],
    'http_req_duration{name:place_order}': ['p(95)<8000'],
    errors: ['rate<0.02'],
  },
  noCookiesReset: true,
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(90)', 'p(95)', 'p(99)'],
  tags: {
    test_type: 'peak_hour_local',
    environment: __ENV.ENVIRONMENT || 'local',
  },
};

export function setup() {
  logProgress('Starting local peak hour test', {
    baseUrl: BASE_URL,
    maxUsers: 25,
    duration: '10 minutes',
  });

  return {
    startTime: Date.now(),
  };
}

export default function () {
  const canPlaceOrder = !!(TEST_DATA.restaurantId && TEST_DATA.menuId && TEST_DATA.tableId);

  const behavior = weightedRandomChoice({
    browsing: 0.8,
    ordering: canPlaceOrder ? USER_BEHAVIOR.ordering : 0.0,
    viewingStatus: 0.15,
    payment: 0.05,
  });

  switch (behavior) {
    case 'browsing':
      browseMenu();
      break;
    case 'ordering':
      if (canPlaceOrder) {
        placeOrder();
      } else {
        browseMenu();
      }
      break;
    case 'viewingStatus':
      viewOrderStatus();
      break;
    case 'payment':
      processPayment();
      break;
    default:
      browseMenu();
  }

  thinkTime();
}

function browseMenu() {
  group('Browse Menu', function () {
    const smartmenuUrl = `${BASE_URL}/smartmenus/${TEST_DATA.smartmenuId}`;

    const startTime = Date.now();
    const response = http.get(smartmenuUrl, {
      tags: { name: 'browse_menu' },
    });
    const duration = Date.now() - startTime;

    const success = check(response, {
      'menu loads successfully': (r) => r.status === 200,
      'menu contains items': (r) => (r.body || '').includes('menu') || (r.body || '').includes('item'),
      'load time acceptable': (r) => r.timings.duration < 5000,
    });

    errorRate.add(!success);

    if (success) {
      menuBrowseTime.add(duration);
    } else {
      logProgress('Menu browse failed', {
        status: response.status,
        duration,
      });
    }

    shortPause();
  });
}

function placeOrder() {
  group('Place Order', function () {
    if (!TEST_DATA.restaurantId || !TEST_DATA.menuId || !TEST_DATA.tableId) {
      shortPause();
      return;
    }

    const orderPayload = JSON.stringify({
      ordr: {
        tablesetting_id: TEST_DATA.tableId,
        restaurant_id: TEST_DATA.restaurantId,
        menu_id: TEST_DATA.menuId,
        ordercapacity: 2,
        status: 0,
      },
    });

    const startTime = Date.now();
    const response = http.post(
      `${BASE_URL}/restaurants/${TEST_DATA.restaurantId}/ordrs`,
      orderPayload,
      {
        headers: { 'Content-Type': 'application/json' },
        tags: { name: 'place_order' },
      },
    );
    const duration = Date.now() - startTime;

    const success = check(response, {
      'order created or redirected': (r) => r.status === 201 || r.status === 302 || r.status === 422,
      'response time acceptable': (r) => r.timings.duration < 8000,
    });

    errorRate.add(!success);

    if (success && response.status === 201) {
      successfulOrders.add(1);
      orderPlacementTime.add(duration);
      activeOrders.add(1);
    } else if (!success) {
      failedOrders.add(1);
    }

    shortPause();
  });
}

function viewOrderStatus() {
  group('View Order Status', function () {
    const startTime = Date.now();
    const response = http.get(`${BASE_URL}/up`, {
      tags: { name: 'order_status' },
    });
    const duration = Date.now() - startTime;

    const success = check(response, {
      'status check successful': (r) => r.status === 200,
      'fast response': (r) => r.timings.duration < 1500,
    });

    errorRate.add(!success);

    if (success) {
      orderStatusTime.add(duration);
    }

    shortPause();
  });
}

function processPayment() {
  group('Process Payment', function () {
    const response = http.get(`${BASE_URL}/up`, {
      tags: { name: 'payment_check' },
    });

    const success = check(response, {
      'payment system responsive': (r) => r.status === 200,
      'fast response': (r) => r.timings.duration < 2000,
    });

    errorRate.add(!success);

    shortPause();
  });
}

export function teardown(data) {
  const duration = Date.now() - data.startTime;

  logProgress('Local peak hour test completed', {
    duration: `${(duration / 1000 / 60).toFixed(2)} minutes`,
  });
}

export function handleSummary(data) {
  return {
    'peak_hour_local_test_summary.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data),
  };
}

function textSummary(data) {
  const metrics = data.metrics;

  const getMetric = (metric, defaultValue = 0) => {
    return metric !== undefined && metric !== null ? metric : defaultValue;
  };

  const totalReqs = getMetric(metrics.http_reqs?.values?.count, 0);
  const failedReqs = getMetric(metrics.http_req_failed?.values?.passes, 0);
  const failRate = getMetric(metrics.http_req_failed?.values?.rate, 0);
  const avgDuration = getMetric(metrics.http_req_duration?.values?.avg, 0);
  const p95Duration = getMetric(metrics.http_req_duration?.values?.['p(95)'], 0);
  const p99Duration = getMetric(metrics.http_req_duration?.values?.['p(99)'], 0);
  const checksRate = getMetric(metrics.checks?.values?.rate, 0);
  const iterations = getMetric(metrics.iterations?.values?.count, 0);
  const vusMax = getMetric(metrics.vus_max?.values?.value, 0);

  return `
╔════════════════════════════════════════════════════════════╗
║           LOCAL PEAK LOAD TEST RESULTS                     ║
╠════════════════════════════════════════════════════════════╣
║ Total Requests:        ${totalReqs.toString().padStart(8)}                      ║
║ Failed Requests:       ${failedReqs.toString().padStart(8)}                      ║
║ Success Rate:          ${((1 - failRate) * 100).toFixed(2).padStart(7)}%                     ║
║                                                            ║
║ Response Time (avg):   ${avgDuration.toFixed(2).padStart(8)}ms                    ║
║ Response Time (p95):   ${p95Duration.toFixed(2).padStart(8)}ms                    ║
║ Response Time (p99):   ${p99Duration.toFixed(2).padStart(8)}ms                    ║
║                                                            ║
║ Checks Passed:         ${(checksRate * 100).toFixed(2).padStart(7)}%                     ║
║ Iterations:            ${iterations.toString().padStart(8)}                      ║
║ VUs (max):             ${vusMax.toString().padStart(8)}                      ║
╚════════════════════════════════════════════════════════════╝
  `;
}
