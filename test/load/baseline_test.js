/**
 * Baseline Load Test
 * 
 * Purpose: Establish baseline performance metrics with light load
 * Duration: ~7 minutes
 * Users: 10 concurrent
 * 
 * Run: k6 run test/load/baseline_test.js
 */

import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';
import { BASE_URL, TEST_DATA, THRESHOLDS, LOAD_PATTERNS } from './config.js';
import { 
  thinkTime, 
  shortPause, 
  isSuccessful,
  parseJSON,
  logProgress 
} from './utils/helpers.js';

// Custom metrics
const errorRate = new Rate('errors');
const menuLoadTime = new Trend('menu_load_time');
const orderCreationTime = new Trend('order_creation_time');
const successfulRequests = new Counter('successful_requests');

// Test configuration
export const options = {
  stages: LOAD_PATTERNS.baseline,
  thresholds: THRESHOLDS,
  
  // Additional options
  userAgent: 'k6-load-test/1.0',
  insecureSkipTLSVerify: true, // For local testing
  
  // Tags for filtering results
  tags: {
    test_type: 'baseline',
    environment: __ENV.ENVIRONMENT || 'local'
  }
};

// Setup function - runs once before test
export function setup() {
  logProgress('Starting baseline load test', {
    baseUrl: BASE_URL,
    users: 10,
    duration: '7 minutes'
  });
  
  return {
    startTime: Date.now()
  };
}

// Main test function - runs for each virtual user
export default function (data) {
  // Scenario 1: Browse SmartMenu
  group('Browse SmartMenu', function () {
    const smartmenuUrl = `${BASE_URL}/smartmenus/${TEST_DATA.smartmenuId}`;
    
    const response = http.get(smartmenuUrl, {
      tags: { name: 'browse_smartmenu' }
    });
    
    const success = check(response, {
      'smartmenu page loads': (r) => r.status === 200,
      'page contains menu items': (r) => r.body && (r.body.includes('menu-item') || r.body.includes('menuitem')),
      'response time < 2s': (r) => r.timings.duration < 2000
    });
    
    if (success) {
      successfulRequests.add(1);
      menuLoadTime.add(response.timings.duration);
    } else {
      errorRate.add(1);
      logProgress('Failed to load smartmenu', {
        status: response.status,
        url: smartmenuUrl
      });
    }
    
    thinkTime();
  });
  
  // Scenario 2: View Restaurant Menu (if logged in as staff)
  group('View Restaurant Menu', function () {
    if (TEST_DATA.restaurantId && TEST_DATA.menuId) {
      const menuUrl = `${BASE_URL}/restaurants/${TEST_DATA.restaurantId}/menus/${TEST_DATA.menuId}`;
      
      const response = http.get(menuUrl, {
        tags: { name: 'view_restaurant_menu' }
      });
      
      const success = check(response, {
        'menu page loads': (r) => r.status === 200 || r.status === 302,
        'response time < 1s': (r) => r.timings.duration < 1000
      });
      
      if (success) {
        successfulRequests.add(1);
      } else {
        errorRate.add(1);
      }
    }
    
    shortPause();
  });
  
  // Scenario 3: Health Check
  group('Health Check', function () {
    const healthUrl = `${BASE_URL}/up`;
    
    const response = http.get(healthUrl, {
      tags: { name: 'health_check' }
    });
    
    check(response, {
      'health check passes': (r) => r.status === 200,
      'response time < 100ms': (r) => r.timings.duration < 100
    });
    
    shortPause();
  });
  
  // Simulate user reading/browsing time
  thinkTime();
}

// Teardown function - runs once after test
export function teardown(data) {
  const duration = Date.now() - data.startTime;
  
  logProgress('Baseline load test completed', {
    duration: `${(duration / 1000 / 60).toFixed(2)} minutes`
  });
}

// Handle summary data
export function handleSummary(data) {
  const summary = {
    'baseline_test_summary.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data)
  };
  
  return summary;
}

// Text summary helper
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
  const checksRate = getMetric(metrics.checks?.values?.rate, 0);
  const iterations = getMetric(metrics.iterations?.values?.count, 0);
  const vusMax = getMetric(metrics.vus_max?.values?.value, 0);
  
  return `
╔════════════════════════════════════════════════════════════╗
║           BASELINE LOAD TEST RESULTS                       ║
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
