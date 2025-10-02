/**
 * Centralized table configurations
 * Eliminates duplicate column definitions across files
 */

// Common formatters used across tables
export const TableFormatters = {
  editLink: (cell) => {
    const id = cell.getValue();
    const rowData = cell.getRow().getData();
    const tableElement = cell.getTable().element;
    const entityName = tableElement.dataset.entity || 'items';
    const name = rowData.name || rowData.title || id;
    
    // Check for nested route data attributes
    const menuId = tableElement.dataset.menu || tableElement.dataset.bsMenu;
    const menusectionId = tableElement.dataset.menusection || tableElement.dataset.bsMenusection;
    const restaurantId = tableElement.dataset.restaurant || tableElement.dataset.bsRestaurant;
    
    // Build nested route URLs
    if (menuId && menusectionId && entityName === 'menuitems') {
      // Menuitems use full nested routes: menus > menusections > menuitems
      return `<a class='link-dark' href='/menus/${menuId}/menusections/${menusectionId}/${entityName}/${id}/edit'>${name}</a>`;
    } else if (menuId && ['menusections', 'menuavailabilities', 'menuparticipants'].includes(entityName)) {
      // Other menu resources use menu-based nested routes
      return `<a class='link-dark' href='/menus/${menuId}/${entityName}/${id}/edit'>${name}</a>`;
    } else if (restaurantId && ['employees', 'taxes', 'tips', 'sizes', 'allergyns', 'tablesettings', 'restaurantlocales', 'restaurantavailabilities', 'inventories', 'ordrs'].includes(entityName)) {
      return `<a class='link-dark' href='/restaurants/${restaurantId}/${entityName}/${id}/edit'>${name}</a>`;
    } else {
      // Fallback to old route format
      return `<a class='link-dark' href='/${entityName}/${id}/edit'>${name}</a>`;
    }
  },
  
  status: (cell) => {
    const status = cell.getValue();
    return status ? status.toUpperCase() : '';
  },
  
  currency: (cell) => {
    const value = cell.getValue();
    const symbol = cell.getTable().element.dataset.currencySymbol || '$';
    return value ? `${symbol}${parseFloat(value).toFixed(2)}` : '';
  },

  boolean: (cell) => {
    const value = cell.getValue();
    return value ? '✓' : '✗';
  },

  date: (cell) => {
    const value = cell.getValue();
    if (!value) return '';
    const date = new Date(value);
    return date.toLocaleDateString();
  },

  datetime: (cell) => {
    const value = cell.getValue();
    if (!value) return '';
    const date = new Date(value);
    return date.toLocaleString();
  },

  truncate: (cell, formatterParams) => {
    const value = cell.getValue();
    const maxLength = formatterParams.maxLength || 50;
    if (!value || value.length <= maxLength) return value;
    return value.substring(0, maxLength) + '...';
  },

  actions: (cell, formatterParams) => {
    const rowData = cell.getRow().getData();
    const id = rowData.id;
    const actions = formatterParams.actions || ['edit', 'delete'];
    const tableElement = cell.getTable().element;
    const entityName = formatterParams.entity || 'items';
    
    // Check for nested route data attributes
    const menuId = tableElement.dataset.menu || tableElement.dataset.bsMenu;
    const menusectionId = tableElement.dataset.menusection || tableElement.dataset.bsMenusection;
    const restaurantId = tableElement.dataset.restaurant || tableElement.dataset.bsRestaurant;
    
    let html = '<div class="btn-group btn-group-sm">';
    
    if (actions.includes('edit')) {
      let editUrl;
      // Build nested route URLs
      if (menuId && menusectionId && entityName === 'menuitems') {
        // Menuitems use full nested routes: menus > menusections > menuitems
        editUrl = `/menus/${menuId}/menusections/${menusectionId}/${entityName}/${id}/edit`;
      } else if (menuId && ['menusections', 'menuavailabilities', 'menuparticipants'].includes(entityName)) {
        // Other menu resources use menu-based nested routes
        editUrl = `/menus/${menuId}/${entityName}/${id}/edit`;
      } else if (restaurantId && ['employees', 'taxes', 'tips', 'sizes', 'allergyns', 'tablesettings', 'restaurantlocales', 'restaurantavailabilities', 'inventories', 'ordrs'].includes(entityName)) {
        editUrl = `/restaurants/${restaurantId}/${entityName}/${id}/edit`;
      } else {
        // Fallback to old route format
        editUrl = `/${entityName}/${id}/edit`;
      }
      html += `<a href="${editUrl}" class="btn btn-outline-primary btn-sm">Edit</a>`;
    }
    
    if (actions.includes('delete')) {
      html += `<button class="btn btn-outline-danger btn-sm" onclick="deleteItem(${id})">Delete</button>`;
    }
    
    html += '</div>';
    return html;
  }
};

// Common column definitions
export const CommonColumns = {
  id: {
    title: "ID",
    field: "id",
    width: 80,
    sorter: "number"
  },
  
  name: {
    title: "Name",
    field: "name",
    formatter: TableFormatters.editLink,
    headerFilter: "input"
  },
  
  status: {
    title: "Status",
    field: "status",
    formatter: TableFormatters.status,
    headerFilter: "select",
    headerFilterParams: {
      values: { "": "All", "active": "Active", "inactive": "Inactive", "draft": "Draft" }
    }
  },
  
  created_at: {
    title: "Created",
    field: "created_at",
    formatter: TableFormatters.date,
    sorter: "date",
    width: 120
  },
  
  updated_at: {
    title: "Updated",
    field: "updated_at",
    formatter: TableFormatters.date,
    sorter: "date",
    width: 120
  },
  
  actions: {
    title: "Actions",
    formatter: TableFormatters.actions,
    width: 120,
    hozAlign: "center",
    headerSort: false
  }
};

// Restaurant table configuration
export const RESTAURANT_TABLE_CONFIG = {
  ajaxURL: "/restaurants.json",
  columns: [
    CommonColumns.name,
    {
      title: "Address",
      field: "address1",
      headerFilter: "input",
      formatter: TableFormatters.truncate,
      formatterParams: { maxLength: 40 }
    },
    {
      title: "City",
      field: "city",
      headerFilter: "input",
      width: 120
    },
    CommonColumns.status,
    CommonColumns.created_at,
    {
      ...CommonColumns.actions,
      formatterParams: { entity: "restaurants", actions: ["edit", "delete"] }
    }
  ]
};

// Menu table configuration
export const MENU_TABLE_CONFIG = {
  ajaxURL: "/menus.json",
  columns: [
    CommonColumns.name,
    {
      title: "Restaurant",
      field: "restaurant.name",
      headerFilter: "input"
    },
    {
      title: "Description",
      field: "description",
      formatter: TableFormatters.truncate,
      formatterParams: { maxLength: 50 }
    },
    CommonColumns.status,
    {
      title: "Items",
      field: "menuitem_count",
      hozAlign: "right",
      sorter: "number",
      width: 80
    },
    CommonColumns.created_at,
    {
      ...CommonColumns.actions,
      formatterParams: { entity: "menus", actions: ["edit", "delete"] }
    }
  ]
};

// Menu item table configuration
export const MENUITEM_TABLE_CONFIG = {
  columns: [
    CommonColumns.name,
    {
      title: "Description",
      field: "description",
      formatter: TableFormatters.truncate,
      formatterParams: { maxLength: 60 }
    },
    {
      title: "Price",
      field: "price",
      formatter: TableFormatters.currency,
      hozAlign: "right",
      sorter: "number",
      width: 100
    },
    {
      title: "Category",
      field: "menusection.name",
      headerFilter: "input",
      width: 120
    },
    CommonColumns.status,
    {
      title: "Sequence",
      field: "sequence",
      hozAlign: "center",
      sorter: "number",
      width: 80
    },
    {
      ...CommonColumns.actions,
      formatterParams: { entity: "menuitems", actions: ["edit", "delete"] }
    }
  ]
};

// Employee table configuration
export const EMPLOYEE_TABLE_CONFIG = {
  columns: [
    {
      title: "Name",
      field: "name",
      formatter: TableFormatters.editLink,
      headerFilter: "input"
    },
    {
      title: "Email",
      field: "email",
      headerFilter: "input",
      width: 200
    },
    {
      title: "Role",
      field: "role",
      headerFilter: "select",
      headerFilterParams: {
        values: { "": "All", "manager": "Manager", "staff": "Staff", "admin": "Admin" }
      },
      width: 100
    },
    {
      title: "Active",
      field: "active",
      formatter: TableFormatters.boolean,
      hozAlign: "center",
      width: 80
    },
    CommonColumns.created_at,
    {
      ...CommonColumns.actions,
      formatterParams: { entity: "employees", actions: ["edit", "delete"] }
    }
  ]
};

// Order table configuration
export const ORDER_TABLE_CONFIG = {
  columns: [
    {
      title: "Order #",
      field: "id",
      formatter: TableFormatters.editLink,
      width: 100
    },
    {
      title: "Customer",
      field: "customer_name",
      headerFilter: "input"
    },
    {
      title: "Table",
      field: "table_number",
      hozAlign: "center",
      width: 80
    },
    {
      title: "Total",
      field: "total_amount",
      formatter: TableFormatters.currency,
      hozAlign: "right",
      sorter: "number",
      width: 100
    },
    {
      title: "Status",
      field: "status",
      formatter: TableFormatters.status,
      headerFilter: "select",
      headerFilterParams: {
        values: { 
          "": "All", 
          "pending": "Pending", 
          "confirmed": "Confirmed", 
          "preparing": "Preparing",
          "ready": "Ready",
          "delivered": "Delivered",
          "cancelled": "Cancelled"
        }
      }
    },
    {
      title: "Created",
      field: "created_at",
      formatter: TableFormatters.datetime,
      sorter: "datetime",
      width: 150
    },
    {
      ...CommonColumns.actions,
      formatterParams: { entity: "orders", actions: ["edit", "delete"] }
    }
  ]
};

// Inventory table configuration
export const INVENTORY_TABLE_CONFIG = {
  columns: [
    {
      title: "Item",
      field: "menuitem.name",
      formatter: TableFormatters.editLink,
      headerFilter: "input"
    },
    {
      title: "Current Stock",
      field: "current_stock",
      hozAlign: "right",
      sorter: "number",
      width: 120
    },
    {
      title: "Min Stock",
      field: "minimum_stock",
      hozAlign: "right",
      sorter: "number",
      width: 100
    },
    {
      title: "Unit",
      field: "unit",
      width: 80
    },
    {
      title: "Low Stock",
      field: "is_low_stock",
      formatter: (cell) => {
        const isLow = cell.getValue();
        return isLow ? '<span class="badge bg-warning">Low</span>' : '<span class="badge bg-success">OK</span>';
      },
      hozAlign: "center",
      width: 100
    },
    CommonColumns.updated_at,
    {
      ...CommonColumns.actions,
      formatterParams: { entity: "inventories", actions: ["edit"] }
    }
  ]
};

// Export all configurations
export const TABLE_CONFIGS = {
  restaurant: RESTAURANT_TABLE_CONFIG,
  menu: MENU_TABLE_CONFIG,
  menuitem: MENUITEM_TABLE_CONFIG,
  employee: EMPLOYEE_TABLE_CONFIG,
  order: ORDER_TABLE_CONFIG,
  inventory: INVENTORY_TABLE_CONFIG
};

// Helper function to get config by table type
export function getTableConfig(tableType) {
  return TABLE_CONFIGS[tableType] || {};
}

// Helper function to merge configs
export function mergeTableConfig(baseConfig, customConfig) {
  return {
    ...baseConfig,
    ...customConfig,
    columns: [
      ...(baseConfig.columns || []),
      ...(customConfig.columns || [])
    ]
  };
}
