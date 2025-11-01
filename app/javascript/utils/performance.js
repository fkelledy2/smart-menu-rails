/**
 * Performance monitoring and memory leak detection utilities
 * Provides comprehensive performance tracking for the Smart Menu application
 */

export class PerformanceMonitor {
  constructor() {
    this.metrics = new Map();
    this.memoryBaseline = null;
    this.observers = new Map();
    this.isEnabled = false;
  }

  /**
   * Initialize performance monitoring
   */
  init() {
    if (this.isEnabled) return;

    this.isEnabled = true;
    this.memoryBaseline = this.getMemoryUsage();

    // Set up performance observers
    this.setupPerformanceObservers();

    // Start periodic monitoring
    this.startPeriodicMonitoring();

    console.log('[Performance] Monitoring initialized');
  }

  /**
   * Set up performance observers for various metrics
   */
  setupPerformanceObservers() {
    // Navigation timing
    if ('PerformanceObserver' in window) {
      try {
        const navObserver = new PerformanceObserver((list) => {
          for (const entry of list.getEntries()) {
            this.recordMetric('navigation', {
              type: entry.entryType,
              name: entry.name,
              duration: entry.duration,
              startTime: entry.startTime,
            });
          }
        });
        navObserver.observe({ entryTypes: ['navigation'] });
        this.observers.set('navigation', navObserver);
      } catch (e) {
        console.warn('[Performance] Navigation observer not supported');
      }

      // Resource timing
      try {
        const resourceObserver = new PerformanceObserver((list) => {
          for (const entry of list.getEntries()) {
            if (entry.name.includes('javascript') || entry.name.includes('.js')) {
              this.recordMetric('resource', {
                name: entry.name,
                duration: entry.duration,
                transferSize: entry.transferSize,
                encodedBodySize: entry.encodedBodySize,
              });
            }
          }
        });
        resourceObserver.observe({ entryTypes: ['resource'] });
        this.observers.set('resource', resourceObserver);
      } catch (e) {
        console.warn('[Performance] Resource observer not supported');
      }

      // Long task detection
      try {
        const longTaskObserver = new PerformanceObserver((list) => {
          for (const entry of list.getEntries()) {
            this.recordMetric('longTask', {
              duration: entry.duration,
              startTime: entry.startTime,
              name: entry.name,
            });

            if (entry.duration > 50) {
              console.warn(`[Performance] Long task detected: ${entry.duration}ms`);
            }
          }
        });
        longTaskObserver.observe({ entryTypes: ['longtask'] });
        this.observers.set('longtask', longTaskObserver);
      } catch (e) {
        console.warn('[Performance] Long task observer not supported');
      }
    }
  }

  /**
   * Start periodic monitoring of memory and performance
   */
  startPeriodicMonitoring() {
    // Monitor every 30 seconds
    setInterval(() => {
      this.checkMemoryUsage();
      this.checkDOMNodes();
      this.checkEventListeners();
    }, 30000);

    // Monitor every 5 minutes
    setInterval(() => {
      this.generatePerformanceReport();
    }, 300000);
  }

  /**
   * Record a performance metric
   */
  recordMetric(category, data) {
    if (!this.metrics.has(category)) {
      this.metrics.set(category, []);
    }

    this.metrics.get(category).push({
      ...data,
      timestamp: Date.now(),
    });

    // Keep only last 100 entries per category
    const entries = this.metrics.get(category);
    if (entries.length > 100) {
      entries.splice(0, entries.length - 100);
    }
  }

  /**
   * Get current memory usage
   */
  getMemoryUsage() {
    if ('memory' in performance) {
      return {
        used: performance.memory.usedJSHeapSize,
        total: performance.memory.totalJSHeapSize,
        limit: performance.memory.jsHeapSizeLimit,
      };
    }
    return null;
  }

  /**
   * Check for memory leaks
   */
  checkMemoryUsage() {
    const current = this.getMemoryUsage();
    if (!current || !this.memoryBaseline) return;

    const growth = current.used - this.memoryBaseline.used;
    const growthPercent = (growth / this.memoryBaseline.used) * 100;

    this.recordMetric('memory', {
      used: current.used,
      total: current.total,
      growth: growth,
      growthPercent: growthPercent,
    });

    // Alert if memory growth is significant
    if (growthPercent > 50) {
      console.warn(`[Performance] Memory usage increased by ${growthPercent.toFixed(1)}%`);
      console.log('Memory details:', {
        baseline: this.memoryBaseline,
        current: current,
        growth: `${(growth / 1024 / 1024).toFixed(2)} MB`,
      });
    }
  }

  /**
   * Check DOM node count for potential leaks
   */
  checkDOMNodes() {
    const nodeCount = document.getElementsByTagName('*').length;

    this.recordMetric('dom', {
      nodeCount: nodeCount,
      bodyChildren: document.body.children.length,
    });

    // Alert if DOM nodes are growing excessively
    const domMetrics = this.metrics.get('dom') || [];
    if (domMetrics.length > 1) {
      const previous = domMetrics[domMetrics.length - 2];
      const growth = nodeCount - previous.nodeCount;

      if (growth > 100) {
        console.warn(`[Performance] DOM nodes increased by ${growth}`);
      }
    }
  }

  /**
   * Check for event listener leaks (approximation)
   */
  checkEventListeners() {
    // This is an approximation - actual listener count is hard to measure
    const elementsWithListeners = document.querySelectorAll('[data-event-listeners]').length;

    this.recordMetric('events', {
      elementsWithListeners: elementsWithListeners,
    });
  }

  /**
   * Measure component initialization time
   */
  measureComponentInit(componentName, initFunction) {
    const startTime = performance.now();

    const result = initFunction();

    const endTime = performance.now();
    const duration = endTime - startTime;

    this.recordMetric('componentInit', {
      component: componentName,
      duration: duration,
    });

    if (duration > 100) {
      console.warn(
        `[Performance] Slow component initialization: ${componentName} took ${duration.toFixed(2)}ms`
      );
    }

    return result;
  }

  /**
   * Measure async operation performance
   */
  async measureAsync(operationName, asyncFunction) {
    const startTime = performance.now();

    try {
      const result = await asyncFunction();
      const endTime = performance.now();
      const duration = endTime - startTime;

      this.recordMetric('asyncOperation', {
        operation: operationName,
        duration: duration,
        success: true,
      });

      return result;
    } catch (error) {
      const endTime = performance.now();
      const duration = endTime - startTime;

      this.recordMetric('asyncOperation', {
        operation: operationName,
        duration: duration,
        success: false,
        error: error.message,
      });

      throw error;
    }
  }

  /**
   * Generate comprehensive performance report
   */
  generatePerformanceReport() {
    const report = {
      timestamp: new Date().toISOString(),
      memory: this.getMemoryUsage(),
      metrics: {},
    };

    // Summarize each metric category
    for (const [category, entries] of this.metrics.entries()) {
      if (entries.length === 0) continue;

      const recent = entries.slice(-10); // Last 10 entries

      switch (category) {
        case 'memory':
          report.metrics.memory = {
            current: recent[recent.length - 1],
            trend: this.calculateTrend(recent, 'used'),
            averageGrowth: this.calculateAverage(recent, 'growthPercent'),
          };
          break;

        case 'componentInit':
          const durations = recent.map((e) => e.duration);
          report.metrics.componentInit = {
            count: recent.length,
            averageDuration: this.calculateAverage(recent, 'duration'),
            maxDuration: Math.max(...durations),
            slowComponents: recent.filter((e) => e.duration > 100),
          };
          break;

        case 'asyncOperation':
          const successRate = recent.filter((e) => e.success).length / recent.length;
          report.metrics.asyncOperations = {
            count: recent.length,
            successRate: successRate,
            averageDuration: this.calculateAverage(recent, 'duration'),
            failures: recent.filter((e) => !e.success),
          };
          break;

        case 'longTask':
          report.metrics.longTasks = {
            count: recent.length,
            totalDuration: recent.reduce((sum, e) => sum + e.duration, 0),
            averageDuration: this.calculateAverage(recent, 'duration'),
          };
          break;

        case 'dom':
          report.metrics.dom = {
            currentNodes: recent[recent.length - 1]?.nodeCount,
            trend: this.calculateTrend(recent, 'nodeCount'),
          };
          break;
      }
    }

    console.log('[Performance] Report:', report);

    // Store report for potential export
    this.recordMetric('report', report);

    return report;
  }

  /**
   * Calculate trend for a numeric field
   */
  calculateTrend(entries, field) {
    if (entries.length < 2) return 0;

    const first = entries[0][field];
    const last = entries[entries.length - 1][field];

    return ((last - first) / first) * 100;
  }

  /**
   * Calculate average for a numeric field
   */
  calculateAverage(entries, field) {
    if (entries.length === 0) return 0;

    const sum = entries.reduce((total, entry) => total + (entry[field] || 0), 0);
    return sum / entries.length;
  }

  /**
   * Export performance data
   */
  exportData() {
    const data = {
      timestamp: new Date().toISOString(),
      baseline: this.memoryBaseline,
      current: this.getMemoryUsage(),
      metrics: Object.fromEntries(this.metrics),
    };

    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);

    const a = document.createElement('a');
    a.href = url;
    a.download = `performance-data-${Date.now()}.json`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);

    URL.revokeObjectURL(url);
  }

  /**
   * Get performance summary
   */
  getSummary() {
    const current = this.getMemoryUsage();
    const memoryGrowth =
      current && this.memoryBaseline
        ? ((current.used - this.memoryBaseline.used) / this.memoryBaseline.used) * 100
        : 0;

    const componentInits = this.metrics.get('componentInit') || [];
    const avgInitTime =
      componentInits.length > 0 ? this.calculateAverage(componentInits, 'duration') : 0;

    const longTasks = this.metrics.get('longTask') || [];
    const domMetrics = this.metrics.get('dom') || [];
    const currentNodes = domMetrics.length > 0 ? domMetrics[domMetrics.length - 1].nodeCount : 0;

    return {
      memoryUsage: current,
      memoryGrowth: memoryGrowth,
      averageComponentInitTime: avgInitTime,
      longTasksCount: longTasks.length,
      domNodeCount: currentNodes,
      isHealthy: memoryGrowth < 25 && avgInitTime < 50 && longTasks.length < 5,
    };
  }

  /**
   * Clean up performance monitoring
   */
  destroy() {
    // Disconnect all observers
    this.observers.forEach((observer) => {
      observer.disconnect();
    });
    this.observers.clear();

    // Clear metrics
    this.metrics.clear();

    this.isEnabled = false;
    console.log('[Performance] Monitoring destroyed');
  }
}

// Create singleton instance
export const performanceMonitor = new PerformanceMonitor();

// Auto-initialize in development
if (process.env.NODE_ENV === 'development') {
  performanceMonitor.init();
}

// Global access for debugging
window.PerformanceMonitor = performanceMonitor;
