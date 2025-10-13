#!/usr/bin/env node

/**
 * Bundle Analyzer for ESBuild
 * Analyzes the JavaScript bundle to identify optimization opportunities
 */

import * as esbuild from "esbuild"
import path from "path"
import fs from "fs"
import { fileURLToPath } from 'url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const config = {
  absWorkingDir: path.join(process.cwd(), "app/javascript"),
  bundle: true,
  entryPoints: ["application.js"],
  minify: false, // Keep unminified for analysis
  outdir: path.join(process.cwd(), "tmp/bundle-analysis"),
  metafile: true, // Enable metafile for analysis
  write: false, // Don't write files, just analyze
  sourcemap: false,
  treeShaking: true,
  format: 'esm'
}

async function analyzeBundles() {
  console.log('🔍 Analyzing JavaScript bundle...\n')
  
  try {
    const result = await esbuild.build(config)
    
    if (!result.metafile) {
      throw new Error('Metafile not generated')
    }
    
    // Save metafile for external analysis tools
    const metafilePath = path.join(process.cwd(), 'tmp/bundle-analysis/metafile.json')
    fs.mkdirSync(path.dirname(metafilePath), { recursive: true })
    fs.writeFileSync(metafilePath, JSON.stringify(result.metafile, null, 2))
    
    console.log(`📊 Metafile saved to: ${metafilePath}`)
    
    // Analyze the metafile
    analyzeMetafile(result.metafile)
    
    // Generate recommendations
    generateRecommendations(result.metafile)
    
  } catch (error) {
    console.error('❌ Bundle analysis failed:', error)
    process.exit(1)
  }
}

function analyzeMetafile(metafile) {
  console.log('\n📈 Bundle Analysis Results\n')
  console.log('=' .repeat(50))
  
  // Analyze outputs
  const outputs = Object.entries(metafile.outputs)
  let totalSize = 0
  
  console.log('\n🎯 Output Files:')
  outputs.forEach(([file, info]) => {
    const sizeKB = (info.bytes / 1024).toFixed(2)
    totalSize += info.bytes
    console.log(`  ${file}: ${sizeKB} KB`)
  })
  
  console.log(`\n📦 Total Bundle Size: ${(totalSize / 1024).toFixed(2)} KB`)
  
  // Analyze inputs by size
  const inputs = Object.entries(metafile.inputs)
    .map(([file, info]) => ({
      file,
      bytes: info.bytes,
      sizeKB: (info.bytes / 1024).toFixed(2)
    }))
    .sort((a, b) => b.bytes - a.bytes)
  
  console.log('\n📁 Largest Input Files:')
  inputs.slice(0, 15).forEach((input, index) => {
    console.log(`  ${index + 1}. ${input.file}: ${input.sizeKB} KB`)
  })
  
  // Analyze by file type
  const fileTypes = {}
  inputs.forEach(input => {
    const ext = path.extname(input.file) || 'no-ext'
    if (!fileTypes[ext]) {
      fileTypes[ext] = { count: 0, totalSize: 0 }
    }
    fileTypes[ext].count++
    fileTypes[ext].totalSize += input.bytes
  })
  
  console.log('\n📊 File Types Analysis:')
  Object.entries(fileTypes)
    .sort((a, b) => b[1].totalSize - a[1].totalSize)
    .forEach(([ext, info]) => {
      console.log(`  ${ext}: ${info.count} files, ${(info.totalSize / 1024).toFixed(2)} KB`)
    })
  
  // Analyze node_modules vs app code
  let nodeModulesSize = 0
  let appCodeSize = 0
  
  inputs.forEach(input => {
    if (input.file.includes('node_modules')) {
      nodeModulesSize += input.bytes
    } else {
      appCodeSize += input.bytes
    }
  })
  
  console.log('\n🔍 Code Distribution:')
  console.log(`  App Code: ${(appCodeSize / 1024).toFixed(2)} KB (${((appCodeSize / totalSize) * 100).toFixed(1)}%)`)
  console.log(`  Dependencies: ${(nodeModulesSize / 1024).toFixed(2)} KB (${((nodeModulesSize / totalSize) * 100).toFixed(1)}%)`)
  
  // Find largest dependencies
  const dependencies = {}
  inputs.forEach(input => {
    if (input.file.includes('node_modules')) {
      const match = input.file.match(/node_modules\/([^\/]+)/)
      if (match) {
        const dep = match[1]
        if (!dependencies[dep]) {
          dependencies[dep] = 0
        }
        dependencies[dep] += input.bytes
      }
    }
  })
  
  console.log('\n📦 Largest Dependencies:')
  Object.entries(dependencies)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .forEach(([dep, size]) => {
      console.log(`  ${dep}: ${(size / 1024).toFixed(2)} KB`)
    })
}

function generateRecommendations(metafile) {
  console.log('\n💡 Optimization Recommendations\n')
  console.log('=' .repeat(50))
  
  const inputs = Object.entries(metafile.inputs)
  const totalSize = Object.values(metafile.outputs).reduce((sum, output) => sum + output.bytes, 0)
  
  // Check for large dependencies
  const largeDeps = []
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
  
  Object.entries(dependencies).forEach(([dep, size]) => {
    if (size > 50 * 1024) { // > 50KB
      largeDeps.push({ dep, size })
    }
  })
  
  console.log('🎯 High Impact Optimizations:')
  
  // Tree shaking opportunities
  if (largeDeps.some(d => d.dep === 'bootstrap')) {
    console.log('  ✂️  Bootstrap: Import only needed components instead of full library')
  }
  
  if (largeDeps.some(d => d.dep === 'tabulator-tables')) {
    console.log('  ✂️  Tabulator: Create custom build with only required modules')
  }
  
  if (largeDeps.some(d => d.dep === 'luxon')) {
    console.log('  ✂️  Luxon: Replace with native Date API where possible')
  }
  
  if (largeDeps.some(d => d.dep === 'jquery')) {
    console.log('  ✂️  jQuery: Audit usage and replace with vanilla JS where feasible')
  }
  
  // Code splitting opportunities
  const appFiles = inputs.filter(([file]) => !file.includes('node_modules'))
  const largeAppFiles = appFiles.filter(([, info]) => info.bytes > 10 * 1024) // > 10KB
  
  if (largeAppFiles.length > 0) {
    console.log('\n📦 Code Splitting Opportunities:')
    largeAppFiles.slice(0, 5).forEach(([file, info]) => {
      console.log(`  📄 ${file}: ${(info.bytes / 1024).toFixed(2)} KB - Consider lazy loading`)
    })
  }
  
  // Calculate potential savings
  let potentialSavings = 0
  
  // Estimate savings from tree shaking major libraries
  const bootstrapSize = dependencies['bootstrap'] || 0
  const tabulatorSize = dependencies['tabulator-tables'] || 0
  const luxonSize = dependencies['luxon'] || 0
  const jquerySize = dependencies['jquery'] || 0
  
  potentialSavings += bootstrapSize * 0.3 // 30% savings from tree shaking
  potentialSavings += tabulatorSize * 0.6 // 60% savings from custom build
  potentialSavings += luxonSize * 0.7 // 70% savings from native Date API
  potentialSavings += jquerySize * 0.5 // 50% savings from vanilla JS replacement
  
  console.log('\n📊 Estimated Savings Potential:')
  console.log(`  Current Size: ${(totalSize / 1024).toFixed(2)} KB`)
  console.log(`  Potential Savings: ${(potentialSavings / 1024).toFixed(2)} KB`)
  console.log(`  Optimized Size: ${((totalSize - potentialSavings) / 1024).toFixed(2)} KB`)
  console.log(`  Reduction: ${((potentialSavings / totalSize) * 100).toFixed(1)}%`)
  
  if ((potentialSavings / totalSize) >= 0.7) {
    console.log('  🎉 Target 70% reduction is achievable!')
  } else {
    console.log('  ⚠️  Additional optimizations needed for 70% target')
  }
  
  console.log('\n🚀 Next Steps:')
  console.log('  1. Implement tree shaking for major dependencies')
  console.log('  2. Set up code splitting for page-specific modules')
  console.log('  3. Replace heavy libraries with lighter alternatives')
  console.log('  4. Implement dynamic imports for non-critical features')
  
  console.log(`\n📋 Analysis complete! Check ${path.join(process.cwd(), 'tmp/bundle-analysis/')} for detailed files.`)
}

// Run the analysis
analyzeBundles().catch(console.error)
