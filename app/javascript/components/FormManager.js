import { ComponentBase } from './ComponentBase.js';

/**
 * Centralized form management system
 * Eliminates 100+ duplicate TomSelect initializations across the app
 */
export class FormManager extends ComponentBase {
  constructor(container = document) {
    super(container);
    this.selects = new Map();
    this.validators = new Map();
    this.defaultSelectOptions = {
      allowEmptyOption: true,
      create: false,
      sortField: 'text',
    };
  }

  /**
   * Initialize all form components
   */
  init() {
    if (!super.init()) {
      return this;
    }

    this.initializeSelects();
    this.initializeValidation();
    this.bindFormEvents();

    return this;
  }

  /**
   * Auto-initialize all TomSelect elements with data attributes
   */
  initializeSelects() {
    // Find all elements with data-tom-select attribute
    const selectElements = this.findAll('[data-tom-select]');

    selectElements.forEach((element) => {
      this.initializeSelect(element);
    });

    // Also initialize standard select elements that aren't already TomSelect
    const standardSelects = this.findAll('select:not([data-tom-select])');
    standardSelects.forEach((element) => {
      if (!element.tomselect && !element.hasAttribute('data-skip-tomselect')) {
        this.initializeSelect(element);
      }
    });
  }

  /**
   * Initialize a single select element
   */
  initializeSelect(element, customOptions = {}) {
    if (!element || element.tomselect || this.selects.has(element)) {
      return null;
    }

    // Skip menu status selects globally (handled via Quick Action toggle)
    try {
      const id = element.id || '';
      const name = element.name || '';
      if (
        id === 'menu_status' || name === 'menu[status]' ||
        id === 'restaurant_status' || name === 'restaurant[status]'
      ) {
        return null;
      }
    } catch(_) {}

    try {
      // Parse options from data attribute
      const dataOptions = element.dataset.tomSelectOptions
        ? JSON.parse(element.dataset.tomSelectOptions)
        : {};

      // Merge options: defaults < data attributes < custom options
      const options = {
        ...this.defaultSelectOptions,
        ...dataOptions,
        ...customOptions,
      };

      // Special handling for different select types
      this.applySelectTypeOptions(element, options);

      // Check if TomSelect is available
      if (typeof window.TomSelect !== 'function') {
        console.warn('TomSelect not yet loaded, skipping initialization for:', element);
        return null;
      }

      // Create TomSelect instance
      const tomSelect = new window.TomSelect(element, options);

      // Track the instance
      this.selects.set(element, tomSelect);

      // Emit event for other components to listen
      this.emit('select:initialized', { element, tomSelect, options });

      return tomSelect;
    } catch (error) {
      console.error('Failed to initialize TomSelect:', error, element);
      return null;
    }
  }

  /**
   * Apply type-specific options based on element attributes
   */
  applySelectTypeOptions(element, options) {
    // Multi-select handling
    if (element.multiple) {
      options.plugins = options.plugins || [];
      if (!options.plugins.includes('remove_button')) {
        options.plugins.push('remove_button');
      }
    }

    // Searchable selects
    if (element.dataset.searchable === 'true') {
      options.create = false;
      options.maxOptions = 50;
    }

    // Creatable selects (for tags, etc.)
    if (element.dataset.creatable === 'true') {
      options.create = true;
      options.createOnBlur = true;
    }

    // Remote data loading
    if (element.dataset.remoteUrl) {
      options.load = (query, callback) => {
        this.loadRemoteOptions(element.dataset.remoteUrl, query, callback);
      };
    }

    // Placeholder handling
    if (element.dataset.placeholder) {
      options.placeholder = element.dataset.placeholder;
    }
  }

  /**
   * Load options from remote URL
   */
  async loadRemoteOptions(url, query, callback) {
    try {
      const response = await fetch(`${url}?q=${encodeURIComponent(query)}`, {
        headers: {
          Accept: 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const data = await response.json();
      callback(data);
    } catch (error) {
      console.error('Failed to load remote options:', error);
      callback();
    }
  }

  /**
   * Initialize form validation
   */
  initializeValidation() {
    const forms = this.findAll('form[data-validate]');

    forms.forEach((form) => {
      this.initializeFormValidation(form);
    });
  }

  /**
   * Initialize validation for a specific form
   */
  initializeFormValidation(form) {
    if (this.validators.has(form)) {
      return;
    }

    const validator = {
      form,
      rules: this.parseValidationRules(form),
      errors: new Map(),
    };

    this.validators.set(form, validator);

    // Bind validation events
    this.addEventListener(form, 'submit', (e) => {
      if (!this.validateForm(validator)) {
        e.preventDefault();
        e.stopPropagation();
      }
    });

    // Real-time validation
    const inputs = form.querySelectorAll('input, select, textarea');
    inputs.forEach((input) => {
      this.addEventListener(input, 'blur', () => {
        this.validateField(validator, input);
      });
    });
  }

  /**
   * Parse validation rules from form and field attributes
   */
  parseValidationRules(form) {
    const rules = new Map();

    const fields = form.querySelectorAll('[data-validate-rules]');
    fields.forEach((field) => {
      try {
        const fieldRules = JSON.parse(field.dataset.validateRules);
        rules.set(field.name || field.id, fieldRules);
      } catch (error) {
        console.warn('Invalid validation rules for field:', field, error);
      }
    });

    return rules;
  }

  /**
   * Validate entire form
   */
  validateForm(validator) {
    let isValid = true;
    validator.errors.clear();

    const inputs = validator.form.querySelectorAll('input, select, textarea');
    inputs.forEach((input) => {
      if (!this.validateField(validator, input)) {
        isValid = false;
      }
    });

    this.displayValidationErrors(validator);
    return isValid;
  }

  /**
   * Validate individual field
   */
  validateField(validator, field) {
    const fieldName = field.name || field.id;
    const rules = validator.rules.get(fieldName);

    if (!rules) {
      return true;
    }

    const value = field.value.trim();
    const errors = [];

    // Required validation
    if (rules.required && !value) {
      errors.push('This field is required');
    }

    // Min length validation
    if (rules.minLength && value.length < rules.minLength) {
      errors.push(`Minimum length is ${rules.minLength} characters`);
    }

    // Max length validation
    if (rules.maxLength && value.length > rules.maxLength) {
      errors.push(`Maximum length is ${rules.maxLength} characters`);
    }

    // Email validation
    if (rules.email && value && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
      errors.push('Please enter a valid email address');
    }

    // Custom pattern validation
    if (rules.pattern && value && !new RegExp(rules.pattern).test(value)) {
      errors.push(rules.patternMessage || 'Invalid format');
    }

    if (errors.length > 0) {
      validator.errors.set(fieldName, errors);
      this.showFieldError(field, errors[0]);
      return false;
    } else {
      validator.errors.delete(fieldName);
      this.clearFieldError(field);
      return true;
    }
  }

  /**
   * Display validation errors
   */
  displayValidationErrors(validator) {
    // Clear previous errors
    const errorElements = validator.form.querySelectorAll('.validation-error');
    errorElements.forEach((el) => el.remove());

    // Show new errors
    validator.errors.forEach((errors, fieldName) => {
      const field = validator.form.querySelector(`[name="${fieldName}"], #${fieldName}`);
      if (field) {
        this.showFieldError(field, errors[0]);
      }
    });
  }

  /**
   * Show error for specific field
   */
  showFieldError(field, message) {
    this.clearFieldError(field);

    field.classList.add('is-invalid');

    const errorElement = document.createElement('div');
    errorElement.className = 'validation-error text-danger small mt-1';
    errorElement.textContent = message;

    field.parentNode.appendChild(errorElement);
  }

  /**
   * Clear error for specific field
   */
  clearFieldError(field) {
    field.classList.remove('is-invalid');

    const existingError = field.parentNode.querySelector('.validation-error');
    if (existingError) {
      existingError.remove();
    }
  }

  /**
   * Bind general form events
   */
  bindFormEvents() {
    // Auto-save functionality
    const autoSaveForms = this.findAll('form[data-auto-save]');
    autoSaveForms.forEach((form) => {
      this.initializeAutoSave(form);
    });

    // Form reset handling
    const forms = this.findAll('form');
    forms.forEach((form) => {
      this.addEventListener(form, 'reset', () => {
        // Reset TomSelect instances
        this.selects.forEach((tomSelect, element) => {
          if (form.contains(element)) {
            tomSelect.clear();
          }
        });

        // Clear validation errors
        const validator = this.validators.get(form);
        if (validator) {
          validator.errors.clear();
          this.displayValidationErrors(validator);
        }
      });
    });
  }

  /**
   * Initialize auto-save for a form
   */
  initializeAutoSave(form) {
    let saveTimeout;
    const saveDelay = parseInt(form.dataset.autoSaveDelay) || 2000;

    const debouncedSave = () => {
      clearTimeout(saveTimeout);
      saveTimeout = setTimeout(() => {
        this.autoSaveForm(form);
      }, saveDelay);
    };

    const inputs = form.querySelectorAll('input, select, textarea');
    inputs.forEach((input) => {
      this.addEventListener(input, 'input', debouncedSave);
      this.addEventListener(input, 'change', debouncedSave);
    });
  }

  /**
   * Perform auto-save
   */
  async autoSaveForm(form) {
    try {
      this.updateInlineStatus(form, 'saving');
      const formData = new FormData(form);
      const response = await fetch(form.action || window.location.href, {
        method: 'PATCH',
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': document.querySelector("meta[name='csrf-token']")?.content,
        },
      });

      if (response.ok) {
        this.updateInlineStatus(form, 'saved');
        this.emit('form:auto-saved', { form, response });
      }
    } catch (error) {
      console.error('Auto-save failed:', error);
      this.updateInlineStatus(form, 'error');
    }
  }

  /**
   * Update inline auto-save status for a form
   */
  updateInlineStatus(form, state) {
    const inlineEls = form.querySelectorAll('.form-autosave-inline');
    if (!inlineEls || inlineEls.length === 0) return;

    inlineEls.forEach((el) => {
      el.classList.remove('saving', 'saved', 'error');
      if (state === 'saving') {
        el.textContent = 'Saving…';
        el.classList.add('saving');
      } else if (state === 'saved') {
        el.textContent = 'Saved';
        el.classList.add('saved');
        // Clear after 2s
        setTimeout(() => {
          if (el.classList.contains('saved')) {
            el.textContent = '';
            el.classList.remove('saved');
          }
        }, 2000);
      } else if (state === 'error') {
        el.textContent = 'Save failed';
        el.classList.add('error');
        // Clear after 4s
        setTimeout(() => {
          if (el.classList.contains('error')) {
            el.textContent = '';
            el.classList.remove('error');
          }
        }, 4000);
      }
    });
  }

  /**
   * Get TomSelect instance for an element
   */
  getSelect(element) {
    if (typeof element === 'string') {
      element = this.find(element);
    }
    return this.selects.get(element);
  }

  /**
   * Destroy a specific select
   */
  destroySelect(element) {
    const tomSelect = this.selects.get(element);
    if (tomSelect) {
      tomSelect.destroy();
      this.selects.delete(element);
    }
  }

  /**
   * Clean up all form components
   */
  destroy() {
    // Destroy all TomSelect instances
    this.selects.forEach((tomSelect) => {
      try {
        tomSelect.destroy();
      } catch (error) {
        console.warn('Error destroying TomSelect:', error);
      }
    });
    this.selects.clear();

    // Clear validators
    this.validators.clear();

    super.destroy();
  }

  /**
   * Refresh all selects (useful after dynamic content changes)
   */
  refresh() {
    if (this.isDestroyed) {
      return;
    }

    this.initializeSelects();
  }

  /**
   * Static method to initialize FormManager on an element
   */
  static init(container = document) {
    const manager = new FormManager(container);
    return manager.init();
  }
}
