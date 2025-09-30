import { ComponentBase } from './ComponentBase.js';

/**
 * Centralized table management system
 * Eliminates 20+ duplicate Tabulator configurations across the app
 */
export class TableManager extends ComponentBase {
  static instances = new Map();
  static globalDefaults = {
    dataLoader: false,
    maxHeight: "100%",
    responsiveLayout: true,
    pagination: "local",
    paginationSize: 20,
    movableColumns: true,
    layout: "fitDataStretch",
    placeholder: "No data available",
    tooltips: true,
    history: true
  };

  constructor(container = document) {
    super(container);
    this.tables = new Map();
  }

  /**
   * Initialize all tables in the container
   */
  init() {
    if (!super.init()) {
      return this;
    }

    this.initializeTables();
    return this;
  }

  /**
   * Auto-initialize all tables with data attributes
   */
  initializeTables() {
    const tableElements = this.findAll('[data-tabulator]');
    
    tableElements.forEach(element => {
      this.initializeTable(element);
    });

    // Also initialize tables with specific IDs that follow patterns
    const commonTableSelectors = [
      '#restaurant-table', '#menu-table', '#menuitem-table', '#menusection-table',
      '#employee-table', '#inventory-table', '#tax-table', '#tip-table',
      '#testimonial-table', '#tag-table', '#size-table', '#allergyn-table',
      '#track-table', '#smartmenu-table', '#tablesetting-table'
    ];

    commonTableSelectors.forEach(selector => {
      const element = this.find(selector);
      if (element && !this.tables.has(element)) {
        this.initializeTable(element);
      }
    });
  }

  /**
   * Initialize a single table
   */
  initializeTable(element, userConfig = {}) {
    if (!element || this.tables.has(element)) {
      return null;
    }

    try {
      // Check if Tabulator is available
      if (typeof window.Tabulator !== 'function') {
        console.warn('Tabulator not yet loaded, skipping initialization for:', element);
        return null;
      }

      const config = this.buildTableConfig(element, userConfig);
      const table = new window.Tabulator(element, config);
      
      // Track the instance
      this.tables.set(element, table);
      TableManager.instances.set(element.id || element, table);

      // Set up event listeners
      this.setupTableEvents(table, element);

      // Emit initialization event
      this.emit('table:initialized', { element, table, config });

      return table;
    } catch (error) {
      console.error('Failed to initialize Tabulator:', error, element);
      return null;
    }
  }

  /**
   * Build table configuration from element attributes and defaults
   */
  buildTableConfig(element, userConfig = {}) {
    // Parse configuration from data attributes
    const dataConfig = element.dataset.tabulatorConfig 
      ? JSON.parse(element.dataset.tabulatorConfig) 
      : {};

    // Determine table type and apply type-specific defaults
    const tableType = this.detectTableType(element);
    const typeDefaults = this.getTypeDefaults(tableType);

    // Build columns configuration
    const columns = this.buildColumnsConfig(element, tableType);

    // Merge configurations: global defaults < type defaults < data config < user config
    const config = {
      ...TableManager.globalDefaults,
      ...typeDefaults,
      ...dataConfig,
      ...userConfig
    };

    // Add columns if configured
    if (columns.length > 0) {
      config.columns = columns;
    }

    // Apply data source configuration
    this.applyDataSourceConfig(element, config);

    return config;
  }

  /**
   * Detect table type from element attributes and ID
   */
  detectTableType(element) {
    // Check data attribute first
    if (element.dataset.tableType) {
      return element.dataset.tableType;
    }

    // Infer from ID or class
    const id = element.id.toLowerCase();
    const className = element.className.toLowerCase();

    if (id.includes('restaurant') || className.includes('restaurant')) return 'restaurant';
    if (id.includes('menu') || className.includes('menu')) return 'menu';
    if (id.includes('employee') || className.includes('employee')) return 'employee';
    if (id.includes('inventory') || className.includes('inventory')) return 'inventory';
    if (id.includes('order') || className.includes('order')) return 'order';
    if (id.includes('track') || className.includes('track')) return 'track';
    if (id.includes('testimonial') || className.includes('testimonial')) return 'testimonial';

    return 'generic';
  }

  /**
   * Get type-specific default configurations
   */
  getTypeDefaults(tableType) {
    const typeDefaults = {
      restaurant: {
        pagination: "local",
        paginationSize: 10,
        sortMode: "local",
        filterMode: "local"
      },
      menu: {
        pagination: "local",
        paginationSize: 15,
        groupBy: "status"
      },
      employee: {
        pagination: "local",
        paginationSize: 20
      },
      inventory: {
        pagination: "local",
        paginationSize: 25,
        sortMode: "local"
      },
      order: {
        pagination: "local",
        paginationSize: 10,
        sortMode: "local",
        initialSort: [{ column: "created_at", dir: "desc" }]
      },
      track: {
        height: "400px",
        pagination: false,
        maxHeight: "400px"
      },
      testimonial: {
        pagination: "local",
        paginationSize: 10
      },
      generic: {}
    };

    return typeDefaults[tableType] || typeDefaults.generic;
  }

  /**
   * Build columns configuration from data attributes or common patterns
   */
  buildColumnsConfig(element, tableType) {
    // Check for explicit column configuration
    if (element.dataset.tabulatorColumns) {
      try {
        return JSON.parse(element.dataset.tabulatorColumns);
      } catch (error) {
        console.warn('Invalid column configuration:', error);
      }
    }

    // Return empty array - let the server-side or existing JS handle columns
    // This allows for gradual migration
    return [];
  }

  /**
   * Apply data source configuration
   */
  applyDataSourceConfig(element, config) {
    // AJAX URL from data attribute
    if (element.dataset.ajaxUrl) {
      config.ajaxURL = element.dataset.ajaxUrl;
      config.ajaxConfig = "GET";
      config.ajaxContentType = "json";
    }

    // Progressive loading
    if (element.dataset.progressiveLoad === 'true') {
      config.progressiveLoad = "scroll";
      config.progressiveLoadDelay = 200;
    }

    // Pagination mode
    if (element.dataset.paginationMode) {
      config.pagination = element.dataset.paginationMode;
    }

    // Custom pagination size
    if (element.dataset.paginationSize) {
      config.paginationSize = parseInt(element.dataset.paginationSize);
    }
  }

  /**
   * Set up event listeners for table
   */
  setupTableEvents(table, element) {
    // Row selection events
    table.on("rowClick", (e, row) => {
      this.emit('table:row:click', { table, row, element, data: row.getData() });
    });

    table.on("rowDblClick", (e, row) => {
      this.emit('table:row:dblclick', { table, row, element, data: row.getData() });
    });

    // Data events
    table.on("dataLoaded", (data) => {
      this.emit('table:data:loaded', { table, element, data });
    });

    table.on("dataLoadError", (error) => {
      this.emit('table:data:error', { table, element, error });
      console.error('Table data load error:', error);
    });

    // Filter events
    table.on("dataFiltered", (filters, rows) => {
      this.emit('table:filtered', { table, element, filters, rows });
    });

    // Sort events
    table.on("dataSorted", (sorters, rows) => {
      this.emit('table:sorted', { table, element, sorters, rows });
    });
  }

  /**
   * Get table instance by element or selector
   */
  getTable(elementOrSelector) {
    let element;
    
    if (typeof elementOrSelector === 'string') {
      element = this.find(elementOrSelector);
    } else {
      element = elementOrSelector;
    }

    return this.tables.get(element) || TableManager.instances.get(element?.id || elementOrSelector);
  }

  /**
   * Destroy a specific table
   */
  destroyTable(elementOrSelector) {
    const table = this.getTable(elementOrSelector);
    if (table) {
      try {
        table.destroy();
      } catch (error) {
        console.warn('Error destroying table:', error);
      }

      // Clean up tracking
      if (typeof elementOrSelector === 'string') {
        const element = this.find(elementOrSelector);
        this.tables.delete(element);
        TableManager.instances.delete(elementOrSelector);
      } else {
        this.tables.delete(elementOrSelector);
        TableManager.instances.delete(elementOrSelector.id || elementOrSelector);
      }
    }
  }

  /**
   * Refresh a table's data
   */
  refreshTable(elementOrSelector) {
    const table = this.getTable(elementOrSelector);
    if (table) {
      table.replaceData();
    }
  }

  /**
   * Add data to a table
   */
  addTableData(elementOrSelector, data) {
    const table = this.getTable(elementOrSelector);
    if (table) {
      if (Array.isArray(data)) {
        table.addData(data);
      } else {
        table.addRow(data);
      }
    }
  }

  /**
   * Update table data
   */
  updateTableData(elementOrSelector, data) {
    const table = this.getTable(elementOrSelector);
    if (table) {
      table.updateData(data);
    }
  }

  /**
   * Clear table data
   */
  clearTableData(elementOrSelector) {
    const table = this.getTable(elementOrSelector);
    if (table) {
      table.clearData();
    }
  }

  /**
   * Apply filters to table
   */
  filterTable(elementOrSelector, filters) {
    const table = this.getTable(elementOrSelector);
    if (table) {
      table.setFilter(filters);
    }
  }

  /**
   * Clear all filters from table
   */
  clearTableFilters(elementOrSelector) {
    const table = this.getTable(elementOrSelector);
    if (table) {
      table.clearFilter();
    }
  }

  /**
   * Export table data
   */
  exportTable(elementOrSelector, format = 'csv', filename = 'data') {
    const table = this.getTable(elementOrSelector);
    if (table) {
      switch (format.toLowerCase()) {
        case 'csv':
          table.download("csv", `${filename}.csv`);
          break;
        case 'json':
          table.download("json", `${filename}.json`);
          break;
        case 'xlsx':
          table.download("xlsx", `${filename}.xlsx`);
          break;
        case 'pdf':
          table.download("pdf", `${filename}.pdf`);
          break;
        default:
          console.warn('Unsupported export format:', format);
      }
    }
  }

  /**
   * Clean up all tables
   */
  destroy() {
    this.tables.forEach((table, element) => {
      try {
        table.destroy();
      } catch (error) {
        console.warn('Error destroying table:', error);
      }
      
      // Clean up global tracking
      TableManager.instances.delete(element.id || element);
    });
    
    this.tables.clear();
    super.destroy();
  }

  /**
   * Static method to create a table
   */
  static createTable(elementOrSelector, userConfig = {}) {
    let element;
    
    if (typeof elementOrSelector === 'string') {
      element = document.querySelector(elementOrSelector);
    } else {
      element = elementOrSelector;
    }

    if (!element) {
      console.warn('Table element not found:', elementOrSelector);
      return null;
    }

    // Check if already initialized
    if (TableManager.instances.has(element.id || element)) {
      return TableManager.instances.get(element.id || element);
    }

    const manager = new TableManager(element.parentElement);
    return manager.initializeTable(element, userConfig);
  }

  /**
   * Static method to destroy a table
   */
  static destroyTable(elementOrSelector) {
    let element;
    
    if (typeof elementOrSelector === 'string') {
      element = document.querySelector(elementOrSelector);
    } else {
      element = elementOrSelector;
    }

    const table = TableManager.instances.get(element?.id || elementOrSelector);
    if (table) {
      table.destroy();
      TableManager.instances.delete(element?.id || elementOrSelector);
    }
  }

  /**
   * Static method to destroy all tables
   */
  static destroyAll() {
    TableManager.instances.forEach(table => {
      try {
        table.destroy();
      } catch (error) {
        console.warn('Error destroying table:', error);
      }
    });
    TableManager.instances.clear();
  }

  /**
   * Static method to get a table instance
   */
  static getTable(elementOrSelector) {
    if (typeof elementOrSelector === 'string') {
      const element = document.querySelector(elementOrSelector);
      return TableManager.instances.get(element?.id || elementOrSelector);
    }
    return TableManager.instances.get(elementOrSelector?.id || elementOrSelector);
  }
}
