// Smart Menu JavaScript Test Helper
// Provides utilities and setup for testing JavaScript modules

class TestHelper {
  constructor() {
    this.testResults = []
    this.currentSuite = null
    this.setupComplete = false
  }

  // Setup test environment
  async setup() {
    if (this.setupComplete) return

    // Create test DOM elements
    this.createTestDOM()
    
    // Mock global dependencies
    this.mockGlobalDependencies()
    
    // Setup test data
    this.setupTestData()
    
    this.setupComplete = true
    console.log('✅ Test environment setup complete')
  }

  // Create test DOM elements
  createTestDOM() {
    // Create test container
    const testContainer = document.createElement('div')
    testContainer.id = 'test-container'
    testContainer.style.display = 'none'
    document.body.appendChild(testContainer)

    // Create common test elements
    const testForm = document.createElement('form')
    testForm.id = 'test-form'
    testForm.innerHTML = `
      <select id="test-select" data-tom-select="true">
        <option value="1">Option 1</option>
        <option value="2">Option 2</option>
      </select>
      <input type="text" id="test-input" name="test_field">
      <button type="submit" id="test-submit">Submit</button>
    `
    testContainer.appendChild(testForm)

    // Create test table
    const testTable = document.createElement('table')
    testTable.id = 'test-table'
    testTable.setAttribute('data-tabulator', 'true')
    testContainer.appendChild(testTable)

    // Create test dropdown
    const testDropdown = document.createElement('div')
    testDropdown.innerHTML = `
      <a id="test-dropdown" data-bs-toggle="dropdown" href="#">Test Dropdown</a>
      <div class="dropdown-menu">
        <a class="dropdown-item" href="#">Item 1</a>
      </div>
    `
    testContainer.appendChild(testDropdown)
  }

  // Mock global dependencies
  mockGlobalDependencies() {
    // Mock TomSelect
    if (!window.TomSelect) {
      window.TomSelect = class MockTomSelect {
        constructor(element, options) {
          this.element = element
          this.options = options
          element.tomSelect = this
        }
        destroy() {
          delete this.element.tomSelect
        }
      }
    }

    // Mock Tabulator
    if (!window.Tabulator) {
      window.Tabulator = class MockTabulator {
        constructor(element, config) {
          this.element = element
          this.config = config
        }
        destroy() {}
        redraw() {}
      }
    }

    // Mock Bootstrap
    if (!window.bootstrap) {
      window.bootstrap = {
        Dropdown: class MockDropdown {
          constructor(element) {
            this.element = element
          }
          toggle() {}
          show() {}
          hide() {}
        },
        Tooltip: class MockTooltip {
          constructor(element) {
            this.element = element
          }
        }
      }
    }

    // Mock jQuery if needed
    if (!window.$) {
      window.$ = window.jQuery = function(selector) {
        return {
          ready: function(callback) { callback() },
          on: function() { return this },
          off: function() { return this },
          trigger: function() { return this }
        }
      }
    }
  }

  // Setup test data
  setupTestData() {
    this.testData = {
      restaurant: {
        id: 1,
        name: 'Test Restaurant',
        status: 'active'
      },
      menu: {
        id: 1,
        name: 'Test Menu',
        restaurant_id: 1
      },
      menuItem: {
        id: 1,
        name: 'Test Item',
        price: 10.99
      }
    }
  }

  // Test suite management
  describe(suiteName, callback) {
    this.currentSuite = suiteName
    console.log(`\n🧪 Testing: ${suiteName}`)
    console.log('=' .repeat(50))
    
    try {
      callback()
    } catch (error) {
      this.recordResult(suiteName, 'ERROR', error.message)
    }
    
    this.currentSuite = null
  }

  // Individual test
  it(testName, callback) {
    const fullTestName = this.currentSuite ? `${this.currentSuite} - ${testName}` : testName
    
    try {
      callback()
      this.recordResult(fullTestName, 'PASS')
      console.log(`  ✅ ${testName}`)
    } catch (error) {
      this.recordResult(fullTestName, 'FAIL', error.message)
      console.log(`  ❌ ${testName}: ${error.message}`)
    }
  }

  // Assertions
  expect(actual) {
    return {
      toBe: (expected) => {
        if (actual !== expected) {
          throw new Error(`Expected ${expected}, got ${actual}`)
        }
      },
      toEqual: (expected) => {
        if (JSON.stringify(actual) !== JSON.stringify(expected)) {
          throw new Error(`Expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`)
        }
      },
      toBeTruthy: () => {
        if (!actual) {
          throw new Error(`Expected truthy value, got ${actual}`)
        }
      },
      toBeFalsy: () => {
        if (actual) {
          throw new Error(`Expected falsy value, got ${actual}`)
        }
      },
      toContain: (expected) => {
        if (!actual.includes(expected)) {
          throw new Error(`Expected ${actual} to contain ${expected}`)
        }
      },
      toBeInstanceOf: (expectedClass) => {
        if (!(actual instanceof expectedClass)) {
          throw new Error(`Expected instance of ${expectedClass.name}, got ${actual.constructor.name}`)
        }
      }
    }
  }

  // Record test results
  recordResult(testName, status, message = null) {
    this.testResults.push({
      name: testName,
      status: status,
      message: message,
      timestamp: new Date()
    })
  }

  // Generate test report
  generateReport() {
    const passed = this.testResults.filter(r => r.status === 'PASS').length
    const failed = this.testResults.filter(r => r.status === 'FAIL').length
    const errors = this.testResults.filter(r => r.status === 'ERROR').length
    const total = this.testResults.length

    console.log('\n📊 Test Results')
    console.log('===============')
    console.log(`Total: ${total}`)
    console.log(`✅ Passed: ${passed}`)
    console.log(`❌ Failed: ${failed}`)
    console.log(`💥 Errors: ${errors}`)
    console.log(`Success Rate: ${((passed / total) * 100).toFixed(1)}%`)

    if (failed > 0 || errors > 0) {
      console.log('\n🔍 Failed Tests:')
      this.testResults
        .filter(r => r.status === 'FAIL' || r.status === 'ERROR')
        .forEach(result => {
          console.log(`  ${result.status === 'FAIL' ? '❌' : '💥'} ${result.name}: ${result.message}`)
        })
    }

    return {
      total,
      passed,
      failed,
      errors,
      successRate: (passed / total) * 100
    }
  }

  // Cleanup test environment
  cleanup() {
    const testContainer = document.getElementById('test-container')
    if (testContainer) {
      testContainer.remove()
    }
    
    this.testResults = []
    this.currentSuite = null
    this.setupComplete = false
    
    console.log('🧹 Test environment cleaned up')
  }

  // Utility methods for testing
  createMockElement(tag, attributes = {}) {
    const element = document.createElement(tag)
    Object.entries(attributes).forEach(([key, value]) => {
      if (key.startsWith('data-')) {
        element.setAttribute(key, value)
      } else {
        element[key] = value
      }
    })
    return element
  }

  simulateEvent(element, eventType, eventData = {}) {
    const event = new Event(eventType, { bubbles: true, cancelable: true })
    Object.assign(event, eventData)
    element.dispatchEvent(event)
  }

  waitFor(condition, timeout = 1000) {
    return new Promise((resolve, reject) => {
      const startTime = Date.now()
      
      const check = () => {
        if (condition()) {
          resolve()
        } else if (Date.now() - startTime > timeout) {
          reject(new Error('Timeout waiting for condition'))
        } else {
          setTimeout(check, 10)
        }
      }
      
      check()
    })
  }
}

// Create global test helper instance
window.testHelper = new TestHelper()

// Export for use in test files
if (typeof module !== 'undefined' && module.exports) {
  module.exports = TestHelper
}
