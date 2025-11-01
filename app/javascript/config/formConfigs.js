/**
 * Centralized form configurations
 * Eliminates duplicate TomSelect initializations and form validation rules
 */

// Common TomSelect configurations
export const SelectConfigs = {
  default: {
    allowEmptyOption: true,
    create: false,
    sortField: 'text',
  },

  searchable: {
    allowEmptyOption: true,
    create: false,
    sortField: 'text',
    maxOptions: 50,
  },

  creatable: {
    allowEmptyOption: true,
    create: true,
    createOnBlur: true,
    sortField: 'text',
  },

  multiSelect: {
    allowEmptyOption: true,
    create: false,
    plugins: ['remove_button'],
    sortField: 'text',
  },

  tags: {
    allowEmptyOption: true,
    create: true,
    createOnBlur: true,
    plugins: ['remove_button'],
    sortField: 'text',
  },
};

// Form field configurations by entity
export const FORM_FIELD_CONFIGS = {
  restaurant: {
    selects: [
      {
        selector: '#restaurant_status',
        config: SelectConfigs.default,
        validation: { required: true },
      },
      {
        selector: '#restaurant_wifiEncryptionType',
        config: SelectConfigs.default,
      },
      {
        selector: '#restaurant_displayImages',
        config: SelectConfigs.default,
      },
      {
        selector: '#restaurant_displayImagesInPopup',
        config: SelectConfigs.default,
      },
      {
        selector: '#restaurant_allowOrdering',
        config: SelectConfigs.default,
      },
      {
        selector: '#restaurant_inventoryTracking',
        config: SelectConfigs.default,
      },
      {
        selector: '#restaurant_country',
        config: SelectConfigs.searchable,
        validation: { required: true },
      },
      {
        selector: '#restaurant_currency',
        config: SelectConfigs.searchable,
        validation: { required: true },
      },
    ],
    validation: {
      name: {
        required: true,
        minLength: 2,
        maxLength: 100,
      },
      address1: {
        required: true,
        minLength: 5,
        maxLength: 200,
      },
      city: {
        required: true,
        minLength: 2,
        maxLength: 100,
      },
      email: {
        email: true,
        maxLength: 255,
      },
      phone: {
        pattern: '^[+]?[0-9\\s\\-\\(\\)]+$',
        patternMessage: 'Please enter a valid phone number',
      },
      website: {
        pattern: '^https?:\\/\\/.+',
        patternMessage: 'Please enter a valid URL starting with http:// or https://',
      },
    },
  },

  menu: {
    selects: [
      {
        selector: '#menu_status',
        config: SelectConfigs.default,
        validation: { required: true },
      },
      {
        selector: '#menu_displayImages',
        config: SelectConfigs.default,
      },
      {
        selector: '#menu_allowOrdering',
        config: SelectConfigs.default,
      },
      {
        selector: '#menu_restaurant_id',
        config: SelectConfigs.searchable,
        validation: { required: true },
      },
    ],
    validation: {
      name: {
        required: true,
        minLength: 2,
        maxLength: 100,
      },
      description: {
        maxLength: 500,
      },
    },
  },

  menuitem: {
    selects: [
      {
        selector: '#menuitem_status',
        config: SelectConfigs.default,
        validation: { required: true },
      },
      {
        selector: '#menuitem_itemtype',
        config: SelectConfigs.default,
        validation: { required: true },
      },
      {
        selector: '#menuitem_menusection_id',
        config: SelectConfigs.searchable,
        validation: { required: true },
      },
      {
        selector: '#menuitem_allergyns',
        config: SelectConfigs.multiSelect,
      },
      {
        selector: '#menuitem_ingredients',
        config: SelectConfigs.multiSelect,
      },
      {
        selector: '#menuitem_tags',
        config: SelectConfigs.tags,
      },
    ],
    validation: {
      name: {
        required: true,
        minLength: 2,
        maxLength: 100,
      },
      description: {
        maxLength: 500,
      },
      price: {
        required: true,
        pattern: '^\\d+(\\.\\d{1,2})?$',
        patternMessage: 'Please enter a valid price (e.g., 12.99)',
      },
      preptime: {
        pattern: '^\\d+$',
        patternMessage: 'Please enter preparation time in minutes',
      },
      calories: {
        pattern: '^\\d+$',
        patternMessage: 'Please enter a valid number of calories',
      },
    },
  },

  menusection: {
    selects: [
      {
        selector: '#menusection_status',
        config: SelectConfigs.default,
        validation: { required: true },
      },
      {
        selector: '#menusection_menu_id',
        config: SelectConfigs.searchable,
        validation: { required: true },
      },
    ],
    validation: {
      name: {
        required: true,
        minLength: 2,
        maxLength: 100,
      },
      description: {
        maxLength: 500,
      },
      sequence: {
        required: true,
        pattern: '^\\d+$',
        patternMessage: 'Please enter a valid sequence number',
      },
    },
  },

  employee: {
    selects: [
      {
        selector: '#employee_role',
        config: SelectConfigs.default,
        validation: { required: true },
      },
      {
        selector: '#employee_restaurant_id',
        config: SelectConfigs.searchable,
        validation: { required: true },
      },
    ],
    validation: {
      name: {
        required: true,
        minLength: 2,
        maxLength: 100,
      },
      email: {
        required: true,
        email: true,
        maxLength: 255,
      },
      phone: {
        pattern: '^[+]?[0-9\\s\\-\\(\\)]+$',
        patternMessage: 'Please enter a valid phone number',
      },
    },
  },

  order: {
    selects: [
      {
        selector: '#order_status',
        config: SelectConfigs.default,
        validation: { required: true },
      },
      {
        selector: '#order_restaurant_id',
        config: SelectConfigs.searchable,
        validation: { required: true },
      },
    ],
    validation: {
      customer_name: {
        minLength: 2,
        maxLength: 100,
      },
      customer_email: {
        email: true,
        maxLength: 255,
      },
      customer_phone: {
        pattern: '^[+]?[0-9\\s\\-\\(\\)]+$',
        patternMessage: 'Please enter a valid phone number',
      },
      table_number: {
        pattern: '^\\d+$',
        patternMessage: 'Please enter a valid table number',
      },
    },
  },

  inventory: {
    selects: [
      {
        selector: '#inventory_menuitem_id',
        config: SelectConfigs.searchable,
        validation: { required: true },
      },
      {
        selector: '#inventory_unit',
        config: SelectConfigs.default,
        validation: { required: true },
      },
    ],
    validation: {
      current_stock: {
        required: true,
        pattern: '^\\d+(\\.\\d+)?$',
        patternMessage: 'Please enter a valid stock quantity',
      },
      minimum_stock: {
        required: true,
        pattern: '^\\d+(\\.\\d+)?$',
        patternMessage: 'Please enter a valid minimum stock quantity',
      },
    },
  },
};

// Auto-save configurations
export const AUTO_SAVE_CONFIGS = {
  default: {
    delay: 2000,
    fields: ['input[type="text"]', 'input[type="email"]', 'textarea', 'select'],
  },

  quick: {
    delay: 1000,
    fields: ['input[type="text"]', 'input[type="email"]'],
  },

  slow: {
    delay: 5000,
    fields: ['textarea'],
  },
};

// Validation message templates
export const VALIDATION_MESSAGES = {
  required: 'This field is required',
  email: 'Please enter a valid email address',
  minLength: 'Minimum length is {minLength} characters',
  maxLength: 'Maximum length is {maxLength} characters',
  pattern: 'Invalid format',
  number: 'Please enter a valid number',
  url: 'Please enter a valid URL',
};

// Helper function to get form config
export function getFormConfig(entityType) {
  return FORM_FIELD_CONFIGS[entityType] || { selects: [], validation: {} };
}

// Helper function to get select config
export function getSelectConfig(configName) {
  return SelectConfigs[configName] || SelectConfigs.default;
}

// Helper function to merge validation rules
export function mergeValidationRules(baseRules, customRules) {
  return { ...baseRules, ...customRules };
}

// Helper function to format validation message
export function formatValidationMessage(template, params) {
  let message = VALIDATION_MESSAGES[template] || template;

  Object.keys(params).forEach((key) => {
    message = message.replace(`{${key}}`, params[key]);
  });

  return message;
}
