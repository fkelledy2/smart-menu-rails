/**
 * Analytics Module
 * Handles analytics dashboard functionality and reporting
 */

import { ComponentBase } from '../../components/ComponentBase.js';

export class AnalyticsModule extends ComponentBase {
  constructor(container = document) {
    super(container);
    this.name = 'Analytics';
    this.charts = new Map();
  }

  init() {
    console.log('[AnalyticsModule] Initializing analytics functionality');

    // Initialize analytics components
    this.initializeCharts();
    this.setupEventListeners();

    return this;
  }

  initializeCharts() {
    // Initialize any charts on the page
    const chartElements = this.container.querySelectorAll('[data-chart]');

    chartElements.forEach((element) => {
      const chartType = element.dataset.chart;
      this.createChart(element, chartType);
    });
  }

  async createChart(element, chartType) {
    try {
      // Dynamically import chart library only when needed
      const { Chart } = await import('chart.js/auto');

      const chart = new Chart(element, {
        type: chartType,
        data: this.getChartData(element),
        options: this.getChartOptions(chartType),
      });

      this.charts.set(element.id, chart);
      console.log(`[AnalyticsModule] Created ${chartType} chart`);
    } catch (error) {
      console.error('[AnalyticsModule] Failed to create chart:', error);
    }
  }

  getChartData(element) {
    // Get chart data from data attributes or API
    const data = element.dataset.chartData;
    return data ? JSON.parse(data) : { labels: [], datasets: [] };
  }

  getChartOptions(chartType) {
    // Return chart-specific options
    const baseOptions = {
      responsive: true,
      maintainAspectRatio: false,
    };

    switch (chartType) {
      case 'line':
        return {
          ...baseOptions,
          scales: {
            y: { beginAtZero: true },
          },
        };
      case 'bar':
        return {
          ...baseOptions,
          scales: {
            y: { beginAtZero: true },
          },
        };
      default:
        return baseOptions;
    }
  }

  setupEventListeners() {
    // Set up analytics-specific event listeners
    this.container.addEventListener('click', (event) => {
      if (event.target.matches('[data-analytics-action]')) {
        this.handleAnalyticsAction(event);
      }
    });
  }

  handleAnalyticsAction(event) {
    const action = event.target.dataset.analyticsAction;

    switch (action) {
      case 'refresh-chart':
        this.refreshChart(event.target.dataset.chartId);
        break;
      case 'export-data':
        this.exportData(event.target.dataset.exportType);
        break;
      default:
        console.warn(`[AnalyticsModule] Unknown action: ${action}`);
    }
  }

  refreshChart(chartId) {
    const chart = this.charts.get(chartId);
    if (chart) {
      // Refresh chart data
      chart.update();
      console.log(`[AnalyticsModule] Refreshed chart: ${chartId}`);
    }
  }

  exportData(exportType) {
    console.log(`[AnalyticsModule] Exporting data as: ${exportType}`);
    // Implement data export functionality
  }

  destroy() {
    // Clean up charts
    this.charts.forEach((chart) => chart.destroy());
    this.charts.clear();

    super.destroy();
  }
}

export default AnalyticsModule;
