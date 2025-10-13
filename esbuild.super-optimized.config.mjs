#!/usr/bin/env node

// Super-optimized Esbuild configuration for maximum bundle size reduction
// Target: 70%+ reduction through aggressive optimization

import * as esbuild from "esbuild"
import path from "path"
import rails from "esbuild-rails"
import chokidar from "chokidar"
import http from "http"
import { setTimeout } from "timers/promises"

const clients = []

// Super minimal entry points
const entryPoints = {
  'application': 'application-minimal.js'
}

const watchDirectories = [
  "./app/javascript/**/*.js",
  "./app/views/**/*.erb",
  "./app/assets/builds/**/*.css",
]

// Aggressive optimization configuration
const superOptimizedConfig = {
  absWorkingDir: path.join(process.cwd(), "app/javascript"),
  bundle: true,
  entryPoints: entryPoints,
  format: 'esm',
  splitting: true,
  outdir: path.join(process.cwd(), "app/assets/builds"),
  plugins: [rails()],
  minify: true, // Always minify for maximum reduction
  sourcemap: false, // No source maps for production
  treeShaking: true,
  metafile: true,
  
  // Target modern browsers for maximum optimization
  target: ['es2022'],
  platform: 'browser',
  
  // Aggressive dead code elimination
  define: {
    'process.env.NODE_ENV': '"production"',
    'global': 'globalThis',
    'DEBUG': 'false',
    'DEVELOPMENT': 'false'
  },
  
  // Mark large libraries as external (load via dynamic imports)
  external: [],
  
  // Drop everything possible in production
  drop: ['console', 'debugger'],
  dropLabels: ['DEV'],
  
  // Maximum minification
  minifyWhitespace: true,
  minifyIdentifiers: true,
  minifySyntax: true,
  
  // Remove all comments
  legalComments: 'none',
  
  // Advanced optimization flags
  pure: ['console.log', 'console.warn', 'console.info'],
  
  // Resolve extensions for better tree shaking
  resolveExtensions: ['.js', '.mjs'],
  
  // Optimize imports
  mainFields: ['module', 'main']
}

async function buildAndReload() {
  const port = parseInt(process.env.PORT)
  const context = await esbuild.context({
    ...superOptimizedConfig,
    minify: false, // Don't minify in development
    sourcemap: true, // Source maps in development
    banner: {
      js: ` (() => new EventSource("http://localhost:${port}").onmessage = () => location.reload())();`,
    }
  })

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
  
  if (result.metafile) {
    logDetailedBundleAnalysis(result.metafile)
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
          
          if (result.metafile) {
            logDetailedBundleAnalysis(result.metafile)
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

function logDetailedBundleAnalysis(metafile) {
  const outputs = Object.entries(metafile.outputs)
  const inputs = Object.entries(metafile.inputs)
  
  let totalSize = 0
  let jsSize = 0
  
  console.log('\\n📦 Super-Optimized Bundle Analysis:')
  console.log('=' .repeat(50))
  
  // Analyze outputs
  outputs.forEach(([file, info]) => {
    const sizeKB = (info.bytes / 1024).toFixed(2)
    totalSize += info.bytes
    
    if (file.endsWith('.js')) {
      jsSize += info.bytes
      const filename = path.basename(file)
      console.log(`  📄 ${filename}: ${sizeKB} KB`)
    }
  })
  
  console.log(`\\n📊 Total JavaScript: ${(jsSize / 1024).toFixed(2)} KB`)
  console.log(`📊 Total All Files: ${(totalSize / 1024).toFixed(2)} KB`)
  
  // Calculate reduction from original 2.2MB
  const originalSize = 2200 // KB
  const reduction = ((originalSize - (jsSize / 1024)) / originalSize * 100).toFixed(1)
  console.log(`🎯 JavaScript Size Reduction: ${reduction}%`)
  
  if (reduction >= 70) {
    console.log('🎉 TARGET 70% REDUCTION ACHIEVED!')
  } else {
    console.log(`⚠️  Need ${(70 - parseFloat(reduction)).toFixed(1)}% more reduction for target`)
  }
  
  // Analyze what's taking up space
  const dependencies = {}
  inputs.forEach(([file, info]) => {
    if (file.includes('node_modules')) {
      const match = file.match(/node_modules\/([^\/]+)/)
      if (match) {
        const dep = match[1]
        if (!dependencies[dep]) {
          dependencies[dep] = 0
        }
        dependencies[dep] += info.bytes
      }
    }
  })
  
  console.log('\\n📦 Remaining Dependencies:')
  Object.entries(dependencies)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .forEach(([dep, size]) => {
      console.log(`  ${dep}: ${(size / 1024).toFixed(2)} KB`)
    })
  
  // Show optimization suggestions
  console.log('\\n💡 Further Optimization Opportunities:')
  if (dependencies['tabulator-tables'] > 100 * 1024) {
    console.log('  ✂️  Tabulator: Still large - consider custom build')
  }
  if (dependencies['bootstrap'] > 50 * 1024) {
    console.log('  ✂️  Bootstrap: Import only specific components')
  }
  if (dependencies['luxon'] > 50 * 1024) {
    console.log('  ✂️  Luxon: Replace with native Date API')
  }
  
  console.log('\\n🚀 Bundle analysis complete!')
}

// Run the appropriate build
if (process.argv.includes("--reload")) {
  buildAndReload()
} else if (process.argv.includes("--watch")) {
  let context = await esbuild.context({
    ...superOptimizedConfig,
    minify: false,
    sourcemap: true,
    logLevel: 'info'
  })
  context.watch()
} else {
  // Production build
  const result = await esbuild.build(superOptimizedConfig)
  
  if (result.metafile) {
    logDetailedBundleAnalysis(result.metafile)
    
    // Save detailed analysis
    const analysisPath = path.join(process.cwd(), 'tmp/bundle-analysis/super-optimized-analysis.json')
    const fs = await import('fs')
    fs.default.mkdirSync(path.dirname(analysisPath), { recursive: true })
    fs.default.writeFileSync(analysisPath, JSON.stringify(result.metafile, null, 2))
    console.log(`\\n📋 Detailed analysis saved to: ${analysisPath}`)
  }
}
