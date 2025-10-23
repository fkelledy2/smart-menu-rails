/**
 * k6 Load Testing Helper Functions
 * Shared utilities for load tests
 */

import { sleep } from 'k6';
import { THINK_TIME } from '../config.js';

/**
 * Generate random integer between min and max (inclusive)
 */
export function randomIntBetween(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

/**
 * Generate random float between min and max
 */
export function randomFloatBetween(min, max) {
  return Math.random() * (max - min) + min;
}

/**
 * Simulate user think time
 */
export function thinkTime() {
  sleep(randomFloatBetween(THINK_TIME.min, THINK_TIME.max));
}

/**
 * Short pause between actions
 */
export function shortPause() {
  sleep(randomFloatBetween(0.5, 1.5));
}

/**
 * Select random item from array
 */
export function randomItem(array) {
  return array[randomIntBetween(0, array.length - 1)];
}

/**
 * Generate random email for testing
 */
export function randomEmail() {
  const timestamp = Date.now();
  const random = randomIntBetween(1000, 9999);
  return `test_${timestamp}_${random}@loadtest.com`;
}

/**
 * Generate random name
 */
export function randomName() {
  const firstNames = ['John', 'Jane', 'Bob', 'Alice', 'Charlie', 'Diana', 'Eve', 'Frank'];
  const lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis'];
  return `${randomItem(firstNames)} ${randomItem(lastNames)}`;
}

/**
 * Generate random phone number
 */
export function randomPhone() {
  return `+1${randomIntBetween(200, 999)}${randomIntBetween(100, 999)}${randomIntBetween(1000, 9999)}`;
}

/**
 * Get CSRF token from HTML response
 */
export function extractCSRFToken(htmlResponse) {
  const match = htmlResponse.match(/name="csrf-token" content="([^"]+)"/);
  return match ? match[1] : null;
}

/**
 * Parse JSON response safely
 */
export function parseJSON(response) {
  try {
    return JSON.parse(response.body);
  } catch (e) {
    console.error('Failed to parse JSON:', e);
    return null;
  }
}

/**
 * Check if response is successful (2xx status code)
 */
export function isSuccessful(response) {
  return response.status >= 200 && response.status < 300;
}

/**
 * Format duration in milliseconds to human-readable string
 */
export function formatDuration(ms) {
  if (ms < 1000) {
    return `${ms.toFixed(0)}ms`;
  } else if (ms < 60000) {
    return `${(ms / 1000).toFixed(2)}s`;
  } else {
    return `${(ms / 60000).toFixed(2)}m`;
  }
}

/**
 * Generate weighted random choice based on probabilities
 * @param {Object} weights - Object with choices as keys and probabilities as values
 * @returns {string} - Selected choice
 */
export function weightedRandomChoice(weights) {
  const random = Math.random();
  let cumulative = 0;
  
  for (const [choice, weight] of Object.entries(weights)) {
    cumulative += weight;
    if (random < cumulative) {
      return choice;
    }
  }
  
  // Fallback to first choice
  return Object.keys(weights)[0];
}

/**
 * Create a summary of test results
 */
export function createSummary(data) {
  const summary = {
    'Total Requests': data.metrics.http_reqs.values.count,
    'Failed Requests': data.metrics.http_req_failed.values.passes,
    'Request Duration (avg)': formatDuration(data.metrics.http_req_duration.values.avg),
    'Request Duration (p95)': formatDuration(data.metrics.http_req_duration.values['p(95)']),
    'Request Duration (p99)': formatDuration(data.metrics.http_req_duration.values['p(99)']),
    'Checks Passed': `${(data.metrics.checks.values.rate * 100).toFixed(2)}%`,
    'VUs': data.metrics.vus.values.value,
    'Iterations': data.metrics.iterations.values.count
  };
  
  return summary;
}

/**
 * Log test progress
 */
export function logProgress(message, data = {}) {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${message}`, JSON.stringify(data));
}

/**
 * Validate response against expected structure
 */
export function validateResponse(response, expectedKeys = []) {
  if (!isSuccessful(response)) {
    return false;
  }
  
  const data = parseJSON(response);
  if (!data) {
    return false;
  }
  
  // Check if all expected keys are present
  return expectedKeys.every(key => key in data);
}

/**
 * Generate random order items
 */
export function generateOrderItems(count = 3) {
  const items = [];
  for (let i = 0; i < count; i++) {
    items.push({
      menuitem_id: randomIntBetween(1, 100),
      quantity: randomIntBetween(1, 3),
      price: randomFloatBetween(5.00, 25.00).toFixed(2)
    });
  }
  return items;
}

/**
 * Calculate order total
 */
export function calculateOrderTotal(items) {
  return items.reduce((total, item) => {
    return total + (parseFloat(item.price) * item.quantity);
  }, 0).toFixed(2);
}

export default {
  randomIntBetween,
  randomFloatBetween,
  thinkTime,
  shortPause,
  randomItem,
  randomEmail,
  randomName,
  randomPhone,
  extractCSRFToken,
  parseJSON,
  isSuccessful,
  formatDuration,
  weightedRandomChoice,
  createSummary,
  logProgress,
  validateResponse,
  generateOrderItems,
  calculateOrderTotal
};
