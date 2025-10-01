// Tests for ApplicationManager and core system functionality

// Import test helper
// In a real environment, this would be loaded via script tag or module import

async function runApplicationManagerTests() {
  await testHelper.setup()

  testHelper.describe('ApplicationManager', () => {
    
    testHelper.it('should initialize with default properties', () => {
      const app = new ApplicationManager()
      
      testHelper.expect(app.modules).toBeInstanceOf(Map)
      testHelper.expect(app.isInitialized).toBe(false)
      testHelper.expect(app.globalFormManager).toBe(null)
      testHelper.expect(app.globalTableManager).toBe(null)
    })

    testHelper.it('should load core components', async () => {
      const app = new ApplicationManager()
      await app.loadCoreComponents()
      
      testHelper.expect(app.EventBus).toBeTruthy()
      testHelper.expect(app.AppEvents).toBeTruthy()
      testHelper.expect(app.FormManager).toBeTruthy()
      testHelper.expect(app.TableManager).toBeTruthy()
    })

    testHelper.it('should initialize global managers', async () => {
      const app = new ApplicationManager()
      await app.loadCoreComponents()
      app.initializeGlobalManagers()
      
      testHelper.expect(app.globalFormManager).toBeInstanceOf(app.FormManager)
      testHelper.expect(app.globalTableManager).toBeInstanceOf(app.TableManager)
    })

    testHelper.it('should detect page modules correctly', () => {
      const app = new ApplicationManager()
      
      // Mock page modules data attribute
      document.body.dataset.modules = 'restaurants,analytics'
      
      const modules = app.detectPageModules()
      testHelper.expect(modules).toContain('restaurants')
      testHelper.expect(modules).toContain('analytics')
      
      // Cleanup
      delete document.body.dataset.modules
    })

    testHelper.it('should load basic modules', async () => {
      const app = new ApplicationManager()
      await app.loadCoreComponents()
      
      const module = await app.loadModule('restaurants')
      testHelper.expect(module).toBeTruthy()
      testHelper.expect(module.name).toBe('Restaurant')
      testHelper.expect(app.modules.has('restaurants')).toBe(true)
    })

    testHelper.it('should handle unknown modules gracefully', async () => {
      const app = new ApplicationManager()
      await app.loadCoreComponents()
      
      const module = await app.loadModule('unknown_module')
      testHelper.expect(module).toBe(null)
    })

    testHelper.it('should refresh modules without errors', async () => {
      const app = new ApplicationManager()
      await app.loadCoreComponents()
      await app.loadModule('restaurants')
      
      // Should not throw
      app.refresh()
      testHelper.expect(app.modules.size).toBe(1)
    })

    testHelper.it('should destroy properly', async () => {
      const app = new ApplicationManager()
      await app.init()
      
      app.destroy()
      testHelper.expect(app.isInitialized).toBe(false)
    })
  })

  testHelper.describe('EventBus', () => {
    
    testHelper.it('should create basic EventBus with required methods', async () => {
      const app = new ApplicationManager()
      await app.loadCoreComponents()
      
      testHelper.expect(app.EventBus.on).toBeTruthy()
      testHelper.expect(app.EventBus.emit).toBeTruthy()
      testHelper.expect(app.EventBus.cleanup).toBeTruthy()
    })

    testHelper.it('should handle event registration and emission', async () => {
      const app = new ApplicationManager()
      await app.loadCoreComponents()
      
      let eventFired = false
      let eventData = null
      
      app.EventBus.on('test:event', (data) => {
        eventFired = true
        eventData = data
      })
      
      app.EventBus.emit('test:event', { detail: 'test data' })
      
      testHelper.expect(eventFired).toBe(true)
      testHelper.expect(eventData.detail).toBe('test data')
    })

    testHelper.it('should define standard app events', async () => {
      const app = new ApplicationManager()
      await app.loadCoreComponents()
      
      testHelper.expect(app.AppEvents.APP_READY).toBe('app:ready')
      testHelper.expect(app.AppEvents.COMPONENT_READY).toBe('component:ready')
      testHelper.expect(app.AppEvents.PAGE_LOAD).toBe('page:load')
    })
  })

  testHelper.describe('FormManager', () => {
    
    testHelper.it('should create basic FormManager', async () => {
      const app = new ApplicationManager()
      await app.loadCoreComponents()
      
      const formManager = new app.FormManager()
      testHelper.expect(formManager.init).toBeTruthy()
      testHelper.expect(formManager.destroy).toBeTruthy()
      testHelper.expect(formManager.isDestroyed).toBe(false)
    })

    testHelper.it('should initialize and return self', async () => {
      const app = new ApplicationManager()
      await app.loadCoreComponents()
      
      const formManager = new app.FormManager()
      const result = formManager.init()
      testHelper.expect(result).toBe(formManager)
    })

    testHelper.it('should handle destruction', async () => {
      const app = new ApplicationManager()
      await app.loadCoreComponents()
      
      const formManager = new app.FormManager()
      formManager.destroy()
      testHelper.expect(formManager.isDestroyed).toBe(true)
    })
  })

  testHelper.describe('TableManager', () => {
    
    testHelper.it('should create basic TableManager', async () => {
      const app = new ApplicationManager()
      await app.loadCoreComponents()
      
      const tableManager = new app.TableManager()
      testHelper.expect(tableManager.init).toBeTruthy()
      testHelper.expect(tableManager.destroy).toBeTruthy()
      testHelper.expect(tableManager.refreshTable).toBeTruthy()
      testHelper.expect(tableManager.getTable).toBeTruthy()
    })

    testHelper.it('should return null for table operations in basic mode', async () => {
      const app = new ApplicationManager()
      await app.loadCoreComponents()
      
      const tableManager = new app.TableManager()
      testHelper.expect(tableManager.getTable()).toBe(null)
      testHelper.expect(tableManager.initializeTable()).toBe(null)
    })
  })

  testHelper.describe('TomSelect Integration', () => {
    
    testHelper.it('should detect uninitialized TomSelect elements', () => {
      const selectElement = testHelper.createMockElement('select', {
        'data-tom-select': 'true',
        id: 'test-tom-select'
      })
      document.body.appendChild(selectElement)
      
      const elements = document.querySelectorAll(
        '[data-tom-select="true"]:not(.tomselected):not(.ts-hidden-accessible):not([data-tom-select-initialized])'
      )
      
      testHelper.expect(elements.length).toBe(1)
      testHelper.expect(elements[0]).toBe(selectElement)
      
      // Cleanup
      selectElement.remove()
    })

    testHelper.it('should skip already initialized TomSelect elements', () => {
      const selectElement = testHelper.createMockElement('select', {
        'data-tom-select': 'true',
        'data-tom-select-initialized': 'true',
        className: 'tomselected'
      })
      document.body.appendChild(selectElement)
      
      const elements = document.querySelectorAll(
        '[data-tom-select="true"]:not(.tomselected):not(.ts-hidden-accessible):not([data-tom-select-initialized])'
      )
      
      testHelper.expect(elements.length).toBe(0)
      
      // Cleanup
      selectElement.remove()
    })
  })

  testHelper.describe('Bootstrap Integration', () => {
    
    testHelper.it('should detect Bootstrap dropdown elements', () => {
      const dropdownElement = testHelper.createMockElement('a', {
        'data-bs-toggle': 'dropdown',
        id: 'test-dropdown'
      })
      document.body.appendChild(dropdownElement)
      
      const elements = document.querySelectorAll('[data-bs-toggle="dropdown"]')
      testHelper.expect(elements.length).toBe(1)
      testHelper.expect(elements[0]).toBe(dropdownElement)
      
      // Cleanup
      dropdownElement.remove()
    })
  })

  // Generate and display test results
  const results = testHelper.generateReport()
  testHelper.cleanup()
  
  return results
}

// Run tests if this file is executed directly
if (typeof window !== 'undefined' && window.testHelper) {
  // Browser environment
  document.addEventListener('DOMContentLoaded', () => {
    runApplicationManagerTests().then(results => {
      console.log('🎯 ApplicationManager tests completed')
    })
  })
} else if (typeof module !== 'undefined' && module.exports) {
  // Node.js environment
  module.exports = runApplicationManagerTests
}
