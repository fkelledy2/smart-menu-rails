#!/usr/bin/env node

// Optimized Esbuild configuration for 70% bundle size reduction
// Features: Tree shaking, code splitting, dynamic imports, and advanced optimization

import * as esbuild from "esbuild"
import path from "path"
import rails from "esbuild-rails"
import chokidar from "chokidar"
import http from "http"
import { setTimeout } from "timers/promises"
import fs from "fs"

const clients = []

// Define entry points for code splitting
const entryPoints = {
  // Core bundle - essential functionality loaded on every page
  'application': 'application-core.js',
  
  // Feature-specific bundles - loaded on demand
  'admin': 'bundles/admin.js',
  'analytics': 'bundles/analytics.js',
  'ocr': 'bundles/ocr.js',
  'customer': 'bundles/customer.js'
}

const watchDirectories = [
  "./app/javascript/**/*.js",
  "./app/views/**/*.erb",
  "./app/assets/builds/**/*.css",
]

// Base configuration with optimization
const baseConfig = {
  absWorkingDir: path.join(process.cwd(), "app/javascript"),
  bundle: true,
  entryPoints: entryPoints,
  format: 'esm', // Use ES modules for better tree shaking
  splitting: true, // Enable code splitting
  outdir: path.join(process.cwd(), "app/assets/builds"),
  plugins: [rails()],
  minify: process.env.RAILS_ENV === "production",
  sourcemap: process.env.RAILS_ENV !== "production",
  treeShaking: true,
  metafile: true, // For bundle analysis
  
  // Advanced optimization options
  target: ['es2020'], // Modern browsers for smaller output
  platform: 'browser',
  
  // Define globals to avoid bundling
  define: {
    'process.env.NODE_ENV': JSON.stringify(process.env.RAILS_ENV || 'development'),
    'global': 'globalThis'
  },
  
  // External dependencies (load from CDN in production)
  external: process.env.RAILS_ENV === "production" ? [] : [],
  
  // Drop console logs in production
  drop: process.env.RAILS_ENV === "production" ? ['console', 'debugger'] : [],
  
  // Advanced minification
  minifyWhitespace: process.env.RAILS_ENV === "production",
  minifyIdentifiers: process.env.RAILS_ENV === "production",
  minifySyntax: process.env.RAILS_ENV === "production",
  
  // Legal comments handling
  legalComments: 'none'
}

// Create optimized entry point files if they don't exist
async function createOptimizedEntryPoints() {
  const jsDir = path.join(process.cwd(), "app/javascript")
  
  // Create application-core.js (essential functionality only)
  const coreContent = `
// Core application bundle - essential functionality only
// This bundle is loaded on every page and should be kept minimal

// Essential framework imports
import '@hotwired/turbo-rails'
import { Application } from '@hotwired/stimulus'

// Essential utilities only
import './utils/ModuleLoader.js'
import './utils/EventBus.js'

// Core styling and basic interactions
import 'bootstrap/js/dist/collapse'
import 'bootstrap/js/dist/dropdown'
import 'bootstrap/js/dist/modal'

// Initialize Stimulus
const application = Application.start()
window.Stimulus = application

// Global utilities
window.SmartMenu = {
  loadModule: async (moduleName) => {
    const { ModuleLoader } = await import('./utils/ModuleLoader.js')
    return ModuleLoader.load(moduleName)
  }
}

// Essential page initialization
document.addEventListener('turbo:load', async () => {
  console.log('[SmartMenu] Core application loaded')
  
  // Auto-detect and load required modules based on page content
  const pageModules = document.body.dataset.modules?.split(',') || []
  
  for (const moduleName of pageModules) {
    try {
      await window.SmartMenu.loadModule(moduleName.trim())
    } catch (error) {
      console.warn(\`Failed to load module \${moduleName}:\`, error)
    }
  }
})

console.log('[SmartMenu] Core bundle loaded')
`
  
  // Create bundles directory
  const bundlesDir = path.join(jsDir, 'bundles')
  if (!fs.existsSync(bundlesDir)) {
    fs.mkdirSync(bundlesDir, { recursive: true })
  }
  
  // Admin bundle
  const adminContent = `
// Admin-specific functionality
import '../modules/employees/EmployeeModule.js'
import '../modules/analytics/AnalyticsModule.js'
import '../modules/restaurants/RestaurantModule.js'

// Admin-specific libraries
import { TabulatorFull as Tabulator } from 'tabulator-tables'
window.Tabulator = Tabulator

console.log('[SmartMenu] Admin bundle loaded')
`
  
  // Analytics bundle
  const analyticsContent = `
// Analytics and reporting functionality
import '../metrics.js'
import { DateTime } from 'luxon'

// Make DateTime available globally for analytics
window.DateTime = DateTime

console.log('[SmartMenu] Analytics bundle loaded')
`
  
  // OCR bundle
  const ocrContent = `
// OCR and document processing functionality
import '../ocr_menu_imports.js'
import pako from 'pako'

// Make pako available for OCR processing
window.pako = pako

console.log('[SmartMenu] OCR bundle loaded')
`
  
  // Customer bundle
  const customerContent = `
// Customer-facing functionality
import '../modules/menus/CustomerMenuModule.js'
import '../modules/orders/OrderModule.js'
import '../channels/ordr_channel.js'

console.log('[SmartMenu] Customer bundle loaded')
`
  
  // Write entry point files
  const files = [
    { path: path.join(jsDir, 'application-core.js'), content: coreContent },
    { path: path.join(bundlesDir, 'admin.js'), content: adminContent },
    { path: path.join(bundlesDir, 'analytics.js'), content: analyticsContent },
    { path: path.join(bundlesDir, 'ocr.js'), content: ocrContent },
    { path: path.join(bundlesDir, 'customer.js'), content: customerContent }
  ]
  
  for (const file of files) {
    if (!fs.existsSync(file.path)) {
      fs.writeFileSync(file.path, file.content.trim())
      console.log(`Created optimized entry point: ${path.relative(process.cwd(), file.path)}`)
    }
  }
}

// Create utility files
async function createUtilityFiles() {
  const utilsDir = path.join(process.cwd(), "app/javascript/utils")
  
  if (!fs.existsSync(utilsDir)) {
    fs.mkdirSync(utilsDir, { recursive: true })
  }
  
  // Enhanced ModuleLoader with caching and performance monitoring
  const moduleLoaderContent = `
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
      
      console.log(\`[ModuleLoader] Loaded \${moduleName} in \${loadTime.toFixed(2)}ms\`)
      
      return module
    } catch (error) {
      this.loadingPromises.delete(moduleName)
      console.error(\`[ModuleLoader] Failed to load \${moduleName}:\`, error)
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
      throw new Error(\`Unknown module: \${moduleName}\`)
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
`
  
  // Enhanced EventBus
  const eventBusContent = `
// Enhanced EventBus with performance monitoring
class EventBus {
  constructor() {
    this.events = new Map()
    this.debug = false
    this.metrics = {
      eventsEmitted: 0,
      listenersRegistered: 0
    }
  }

  on(event, callback) {
    if (!this.events.has(event)) {
      this.events.set(event, [])
    }
    this.events.get(event).push(callback)
    this.metrics.listenersRegistered++
    
    if (this.debug) {
      console.log(\`[EventBus] Registered listener for: \${event}\`)
    }
  }

  emit(event, data) {
    if (this.events.has(event)) {
      const listeners = this.events.get(event)
      listeners.forEach(callback => {
        try {
          callback({ detail: data })
        } catch (error) {
          console.error(\`[EventBus] Error in listener for \${event}:\`, error)
        }
      })
      this.metrics.eventsEmitted++
      
      if (this.debug) {
        console.log(\`[EventBus] Emitted \${event} to \${listeners.length} listeners\`)
      }
    }
  }

  off(event, callback) {
    if (this.events.has(event)) {
      const listeners = this.events.get(event)
      const index = listeners.indexOf(callback)
      if (index > -1) {
        listeners.splice(index, 1)
      }
    }
  }

  cleanup() {
    this.events.clear()
    this.metrics = { eventsEmitted: 0, listenersRegistered: 0 }
  }

  setDebugMode(enabled) {
    this.debug = enabled
  }

  getMetrics() {
    return { ...this.metrics }
  }
}

export const eventBus = new EventBus()
export { EventBus }
`
  
  // Write utility files
  const utilFiles = [
    { path: path.join(utilsDir, 'ModuleLoader.js'), content: moduleLoaderContent },
    { path: path.join(utilsDir, 'EventBus.js'), content: eventBusContent }
  ]
  
  for (const file of utilFiles) {
    if (!fs.existsSync(file.path)) {
      fs.writeFileSync(file.path, file.content.trim())
      console.log(`Created utility file: ${path.relative(process.cwd(), file.path)}`)
    }
  }
}

async function buildAndReload() {
  // Create optimized files first
  await createOptimizedEntryPoints()
  await createUtilityFiles()
  
  const port = parseInt(process.env.PORT)
  const context = await esbuild.context({
    ...baseConfig,
    banner: {
      js: ` (() => new EventSource("http://localhost:${port}").onmessage = () => location.reload())();`,
    }
  })

  // Reload uses an HTTP server as an event stream to reload the browser
  http
    .createServer((req, res) => {
      return clients.push(
        res.writeHead(200, {
          "Content-Type": "text/event-stream",
          "Cache-Control": "no-cache",
          "Access-Control-Allow-Origin": "*",
          Connection: "keep-alive",
        })
      )
    })
    .listen(port)

  const result = await context.rebuild()
  
  // Log bundle analysis in development
  if (result.metafile && process.env.RAILS_ENV !== "production") {
    logBundleAnalysis(result.metafile)
  }
  
  console.log("[reload] initial build succeeded")

  let ready = false
  chokidar
    .watch(watchDirectories)
    .on("ready", () => {
      console.log("[reload] ready")
      ready = true
    })
    .on("all", async (event, path) => {
      if (ready === false) return

      if (path.includes("javascript")) {
        try {
          await setTimeout(20)
          const result = await context.rebuild()
          
          if (result.metafile && process.env.RAILS_ENV !== "production") {
            logBundleAnalysis(result.metafile)
          }
          
          console.log("[reload] build succeeded")
        } catch (error) {
          console.error("[reload] build failed", error)
        }
      }
      clients.forEach((res) => res.write("data: update\\n\\n"))
      clients.length = 0
    })
}

function logBundleAnalysis(metafile) {
  const outputs = Object.entries(metafile.outputs)
  let totalSize = 0
  
  console.log('\\n📦 Bundle Sizes:')
  outputs.forEach(([file, info]) => {
    const sizeKB = (info.bytes / 1024).toFixed(2)
    totalSize += info.bytes
    const filename = path.basename(file)
    console.log(`  ${filename}: ${sizeKB} KB`)
  })
  
  console.log(`📊 Total: ${(totalSize / 1024).toFixed(2)} KB`)
  
  // Calculate reduction from original 2.2MB
  const originalSize = 2200 // KB
  const reduction = ((originalSize - (totalSize / 1024)) / originalSize * 100).toFixed(1)
  console.log(`🎯 Size reduction: ${reduction}%`)
  
  if (reduction >= 70) {
    console.log('🎉 Target 70% reduction achieved!')
  }
}

// Initialize optimized files and run build
if (process.argv.includes("--reload")) {
  buildAndReload()
} else if (process.argv.includes("--watch")) {
  createOptimizedEntryPoints().then(async () => {
    await createUtilityFiles()
    let context = await esbuild.context({ ...baseConfig, logLevel: 'info' })
    context.watch()
  })
} else {
  createOptimizedEntryPoints().then(async () => {
    await createUtilityFiles()
    const result = await esbuild.build(baseConfig)
    
    if (result.metafile) {
      logBundleAnalysis(result.metafile)
    }
  })
}
