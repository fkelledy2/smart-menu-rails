import '@testing-library/jest-dom';
import { expect, afterEach, vi } from 'vitest';

// Cleanup after each test
afterEach(() => {
  // Clear all mocks
  vi.clearAllMocks();
  // Clear the document body
  document.body.innerHTML = '';
});

// Mock window.Rails if needed
global.Rails = {
  ajax: vi.fn(),
  fire: vi.fn()
};

// Mock ActionCable consumer
global.App = {
  cable: {
    subscriptions: {
      create: vi.fn()
    }
  }
};

// Mock console methods to reduce noise in tests
global.console = {
  ...console,
  error: vi.fn(),
  warn: vi.fn()
};

// Mock TomSelect (will be used by FormManager tests)
global.TomSelect = vi.fn().mockImplementation(() => ({
  destroy: vi.fn(),
  clear: vi.fn(),
  setValue: vi.fn(),
  getValue: vi.fn(() => ''),
  addOption: vi.fn(),
  removeOption: vi.fn(),
  refreshOptions: vi.fn(),
  on: vi.fn(),
  off: vi.fn()
}));

// Mock Tabulator (will be used by TableManager tests)
global.Tabulator = vi.fn().mockImplementation(() => ({
  destroy: vi.fn(),
  setData: vi.fn(),
  getData: vi.fn(() => []),
  getSelectedData: vi.fn(() => []),
  clearData: vi.fn(),
  redraw: vi.fn(),
  on: vi.fn(),
  off: vi.fn()
}));
