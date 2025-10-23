/**
 * k6 Load Testing Configuration
 * Shared configuration for all load tests
 */

// Base URL - can be overridden via environment variable
export const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

// Test data
export const TEST_DATA = {
  // Sample restaurant ID (update with actual test data)
  restaurantId: __ENV.RESTAURANT_ID || 'test-restaurant-id',
  
  // Sample menu ID
  menuId: __ENV.MENU_ID || 'test-menu-id',
  
  // Sample table ID
  tableId: __ENV.TABLE_ID || 'test-table-id',
  
  // Sample smartmenu ID
  smartmenuId: __ENV.SMARTMENU_ID || '8d95bbb1-f4c6-4034-97c8-2aafc663353b',
  
  // Test user credentials
  testUser: {
    email: __ENV.TEST_USER_EMAIL || 'test@example.com',
    password: __ENV.TEST_USER_PASSWORD || 'password123'
  }
};

// Performance thresholds
export const THRESHOLDS = {
  // HTTP request duration thresholds
  http_req_duration: [
    'p(95)<2000',  // 95% of requests should be below 2s
    'p(99)<3000',  // 99% of requests should be below 3s
    'avg<1000'     // Average should be below 1s
  ],
  
  // HTTP request failed rate
  http_req_failed: [
    'rate<0.01'    // Error rate should be below 1%
  ],
  
  // Checks (assertions) pass rate
  checks: [
    'rate>0.95'    // 95% of checks should pass
  ]
};

// Test stages for different load patterns
export const LOAD_PATTERNS = {
  // Baseline: Light load for establishing baseline metrics
  baseline: [
    { duration: '1m', target: 10 },   // Ramp up to 10 users
    { duration: '5m', target: 10 },   // Stay at 10 users
    { duration: '1m', target: 0 }     // Ramp down
  ],
  
  // Peak hour: Simulates restaurant rush hour
  peakHour: [
    { duration: '5m', target: 100 },  // Ramp up to 100 users
    { duration: '10m', target: 500 }, // Ramp up to 500 users
    { duration: '10m', target: 500 }, // Stay at 500 users
    { duration: '5m', target: 100 },  // Ramp down to 100
    { duration: '2m', target: 0 }     // Ramp down to 0
  ],
  
  // Spike test: Sudden traffic spike
  spike: [
    { duration: '2m', target: 50 },   // Baseline
    { duration: '10s', target: 1000 },// Sudden spike
    { duration: '2m', target: 1000 }, // Sustain spike
    { duration: '2m', target: 50 },   // Return to baseline
    { duration: '1m', target: 0 }     // Ramp down
  ],
  
  // Stress test: Find breaking point
  stress: [
    { duration: '2m', target: 100 },  // Warm up
    { duration: '5m', target: 500 },  // Ramp up
    { duration: '5m', target: 1000 }, // Continue ramping
    { duration: '5m', target: 1500 }, // Push further
    { duration: '5m', target: 2000 }, // Find breaking point
    { duration: '5m', target: 0 }     // Ramp down
  ],
  
  // Endurance test: Long-running stability test
  endurance: [
    { duration: '5m', target: 200 },  // Ramp up
    { duration: '2h', target: 200 },  // Sustain for 2 hours
    { duration: '5m', target: 0 }     // Ramp down
  ]
};

// HTTP request configuration
export const HTTP_CONFIG = {
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  },
  
  // Timeout settings
  timeout: '30s'
};

// Think time ranges (seconds)
export const THINK_TIME = {
  min: 2,
  max: 5
};

// Percentages for user behavior distribution
export const USER_BEHAVIOR = {
  browsing: 0.40,      // 40% browsing menus
  ordering: 0.30,      // 30% placing orders
  viewingStatus: 0.20, // 20% viewing order status
  payment: 0.10        // 10% payment processing
};

export default {
  BASE_URL,
  TEST_DATA,
  THRESHOLDS,
  LOAD_PATTERNS,
  HTTP_CONFIG,
  THINK_TIME,
  USER_BEHAVIOR
};
