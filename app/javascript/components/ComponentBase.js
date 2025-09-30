/**
 * Base class for all JavaScript components
 * Provides common functionality and lifecycle management
 */
export class ComponentBase {
  constructor(container = document) {
    this.container = container;
    this.eventListeners = [];
    this.childComponents = new Map();
    this.isInitialized = false;
    this.isDestroyed = false;
  }

  /**
   * Initialize the component
   * Override this method in subclasses
   */
  init() {
    if (this.isInitialized || this.isDestroyed) {
      return this;
    }
    
    this.isInitialized = true;
    return this;
  }

  /**
   * Destroy the component and clean up resources
   */
  destroy() {
    if (this.isDestroyed) {
      return;
    }

    // Clean up child components
    this.childComponents.forEach(component => {
      if (component && typeof component.destroy === 'function') {
        component.destroy();
      }
    });
    this.childComponents.clear();

    // Remove event listeners
    this.removeAllEventListeners();

    // Mark as destroyed
    this.isDestroyed = true;
    this.isInitialized = false;
  }

  /**
   * Add an event listener and track it for cleanup
   */
  addEventListener(element, event, handler, options = {}) {
    if (this.isDestroyed) {
      console.warn('Cannot add event listener to destroyed component');
      return;
    }

    element.addEventListener(event, handler, options);
    this.eventListeners.push({ element, event, handler, options });
  }

  /**
   * Remove a specific event listener
   */
  removeEventListener(element, event, handler) {
    element.removeEventListener(event, handler);
    
    const index = this.eventListeners.findIndex(
      listener => listener.element === element && 
                 listener.event === event && 
                 listener.handler === handler
    );
    
    if (index > -1) {
      this.eventListeners.splice(index, 1);
    }
  }

  /**
   * Remove all tracked event listeners
   */
  removeAllEventListeners() {
    this.eventListeners.forEach(({ element, event, handler }) => {
      element.removeEventListener(event, handler);
    });
    this.eventListeners = [];
  }

  /**
   * Add a child component for lifecycle management
   */
  addChildComponent(name, component) {
    if (this.isDestroyed) {
      console.warn('Cannot add child component to destroyed component');
      return;
    }

    this.childComponents.set(name, component);
  }

  /**
   * Remove and destroy a child component
   */
  removeChildComponent(name) {
    const component = this.childComponents.get(name);
    if (component && typeof component.destroy === 'function') {
      component.destroy();
    }
    this.childComponents.delete(name);
  }

  /**
   * Find elements within the component's container
   */
  find(selector) {
    return this.container.querySelector(selector);
  }

  /**
   * Find all elements within the component's container
   */
  findAll(selector) {
    return this.container.querySelectorAll(selector);
  }

  /**
   * Check if component is ready (initialized and not destroyed)
   */
  isReady() {
    return this.isInitialized && !this.isDestroyed;
  }

  /**
   * Emit a custom event from this component
   */
  emit(eventName, detail = {}) {
    if (this.isDestroyed) {
      return;
    }

    const event = new CustomEvent(eventName, {
      detail: { ...detail, component: this },
      bubbles: true,
      cancelable: true
    });

    this.container.dispatchEvent(event);
  }

  /**
   * Listen for custom events on this component
   */
  on(eventName, handler, options = {}) {
    this.addEventListener(this.container, eventName, handler, options);
  }

  /**
   * Listen for custom events once
   */
  once(eventName, handler, options = {}) {
    const onceHandler = (event) => {
      handler(event);
      this.removeEventListener(this.container, eventName, onceHandler);
    };
    
    this.addEventListener(this.container, eventName, onceHandler, options);
  }
}
