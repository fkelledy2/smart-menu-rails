// Enhanced Module Loader with performance monitoring and caching
class ModuleLoader {
  constructor() {
    this.loadedModules = new Map()
    this.loadingPromises = new Map()
    this.performanceMetrics = new Map()
  }

  async load(moduleName) {
    const startTime = performance.now()
    
    if (this.loadedModules.has(moduleName)) {
      return this.loadedModules.get(moduleName)
    }

    if (this.loadingPromises.has(moduleName)) {
      return this.loadingPromises.get(moduleName)
    }

    const loadPromise = this.dynamicImport(moduleName)
    this.loadingPromises.set(moduleName, loadPromise)

    try {
      const module = await loadPromise
      this.loadedModules.set(moduleName, module)
      this.loadingPromises.delete(moduleName)
      
      const loadTime = performance.now() - startTime
      this.performanceMetrics.set(moduleName, loadTime)
      
      console.log(`[ModuleLoader] Loaded ${moduleName} in ${loadTime.toFixed(2)}ms`)
      
      return module
    } catch (error) {
      this.loadingPromises.delete(moduleName)
      console.error(`[ModuleLoader] Failed to load ${moduleName}:`, error)
      throw error
    }
  }

  async dynamicImport(moduleName) {
    // Map module names to their bundle paths
    const moduleMap = {
      'admin': () => import('../bundles/admin.js'),
      'analytics': () => import('../bundles/analytics.js'),
      'ocr': () => import('../bundles/ocr.js'),
      'customer': () => import('../bundles/customer.js'),
      
      // Individual modules
      'restaurants': () => import('../modules/restaurants/RestaurantModule.js'),
      'menus': () => import('../modules/menus/MenuModule.js'),
      'employees': () => import('../modules/employees/EmployeeModule.js'),
      'orders': () => import('../modules/orders/OrderModule.js')
    }

    const importFn = moduleMap[moduleName]
    if (!importFn) {
      throw new Error(`Unknown module: ${moduleName}`)
    }

    return importFn()
  }

  getPerformanceMetrics() {
    return Object.fromEntries(this.performanceMetrics)
  }

  clearCache() {
    this.loadedModules.clear()
    this.performanceMetrics.clear()
  }
}

export const moduleLoader = new ModuleLoader()
export { ModuleLoader }