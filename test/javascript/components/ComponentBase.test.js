import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ComponentBase } from '../../../app/javascript/components/ComponentBase.js';

describe('ComponentBase', () => {
  let component;
  let container;

  beforeEach(() => {
    // Create a fresh container for each test
    container = document.createElement('div');
    container.innerHTML = `
      <div class="test-element" id="test-1">Test 1</div>
      <div class="test-element" id="test-2">Test 2</div>
      <button class="test-button">Click me</button>
    `;
    document.body.appendChild(container);
    
    component = new ComponentBase(container);
  });

  describe('constructor', () => {
    it('should initialize with default container', () => {
      const defaultComponent = new ComponentBase();
      expect(defaultComponent.container).toBe(document);
    });

    it('should initialize with custom container', () => {
      expect(component.container).toBe(container);
    });

    it('should initialize empty event listeners array', () => {
      expect(component.eventListeners).toEqual([]);
    });

    it('should initialize empty child components map', () => {
      expect(component.childComponents).toBeInstanceOf(Map);
      expect(component.childComponents.size).toBe(0);
    });

    it('should set isInitialized to false', () => {
      expect(component.isInitialized).toBe(false);
    });

    it('should set isDestroyed to false', () => {
      expect(component.isDestroyed).toBe(false);
    });
  });

  describe('init()', () => {
    it('should set isInitialized to true', () => {
      component.init();
      expect(component.isInitialized).toBe(true);
    });

    it('should return this for method chaining', () => {
      const result = component.init();
      expect(result).toBe(component);
    });

    it('should not reinitialize if already initialized', () => {
      component.init();
      const firstInit = component.isInitialized;
      component.init();
      expect(component.isInitialized).toBe(firstInit);
    });

    it('should not initialize if destroyed', () => {
      component.init();
      component.destroy();
      const result = component.init();
      expect(result).toBe(component);
      expect(component.isInitialized).toBe(false);
    });
  });

  describe('destroy()', () => {
    it('should set isDestroyed to true', () => {
      component.destroy();
      expect(component.isDestroyed).toBe(true);
    });

    it('should set isInitialized to false', () => {
      component.init();
      component.destroy();
      expect(component.isInitialized).toBe(false);
    });

    it('should not destroy twice', () => {
      component.destroy();
      const firstDestroyed = component.isDestroyed;
      component.destroy();
      expect(component.isDestroyed).toBe(firstDestroyed);
    });

    it('should destroy all child components', () => {
      const child1 = new ComponentBase();
      const child2 = new ComponentBase();
      child1.destroy = vi.fn();
      child2.destroy = vi.fn();
      
      component.addChildComponent('child1', child1);
      component.addChildComponent('child2', child2);
      
      component.destroy();
      
      expect(child1.destroy).toHaveBeenCalled();
      expect(child2.destroy).toHaveBeenCalled();
    });

    it('should clear child components map', () => {
      const child = new ComponentBase();
      component.addChildComponent('child', child);
      
      component.destroy();
      
      expect(component.childComponents.size).toBe(0);
    });

    it('should remove all event listeners', () => {
      const button = container.querySelector('.test-button');
      const handler = vi.fn();
      
      component.addEventListener(button, 'click', handler);
      component.destroy();
      
      button.click();
      expect(handler).not.toHaveBeenCalled();
    });
  });

  describe('addEventListener()', () => {
    it('should add event listener to element', () => {
      const button = container.querySelector('.test-button');
      const handler = vi.fn();
      
      component.addEventListener(button, 'click', handler);
      button.click();
      
      expect(handler).toHaveBeenCalledTimes(1);
    });

    it('should track event listener for cleanup', () => {
      const button = container.querySelector('.test-button');
      const handler = vi.fn();
      
      component.addEventListener(button, 'click', handler);
      
      expect(component.eventListeners).toHaveLength(1);
      expect(component.eventListeners[0]).toMatchObject({
        element: button,
        event: 'click',
        handler
      });
    });

    it('should not add listener if component is destroyed', () => {
      const button = container.querySelector('.test-button');
      const handler = vi.fn();
      
      component.destroy();
      component.addEventListener(button, 'click', handler);
      
      expect(component.eventListeners).toHaveLength(0);
    });

    it('should support event options', () => {
      const button = container.querySelector('.test-button');
      const handler = vi.fn();
      
      component.addEventListener(button, 'click', handler, { once: true });
      button.click();
      button.click();
      
      expect(handler).toHaveBeenCalledTimes(1);
    });
  });

  describe('removeEventListener()', () => {
    it('should remove event listener from element', () => {
      const button = container.querySelector('.test-button');
      const handler = vi.fn();
      
      component.addEventListener(button, 'click', handler);
      component.removeEventListener(button, 'click', handler);
      button.click();
      
      expect(handler).not.toHaveBeenCalled();
    });

    it('should remove listener from tracking array', () => {
      const button = container.querySelector('.test-button');
      const handler = vi.fn();
      
      component.addEventListener(button, 'click', handler);
      component.removeEventListener(button, 'click', handler);
      
      expect(component.eventListeners).toHaveLength(0);
    });
  });

  describe('removeAllEventListeners()', () => {
    it('should remove all tracked event listeners', () => {
      const button = container.querySelector('.test-button');
      const div = container.querySelector('.test-element');
      const handler1 = vi.fn();
      const handler2 = vi.fn();
      
      component.addEventListener(button, 'click', handler1);
      component.addEventListener(div, 'mouseover', handler2);
      
      component.removeAllEventListeners();
      
      button.click();
      div.dispatchEvent(new Event('mouseover'));
      
      expect(handler1).not.toHaveBeenCalled();
      expect(handler2).not.toHaveBeenCalled();
    });

    it('should clear event listeners array', () => {
      const button = container.querySelector('.test-button');
      component.addEventListener(button, 'click', vi.fn());
      
      component.removeAllEventListeners();
      
      expect(component.eventListeners).toHaveLength(0);
    });
  });

  describe('addChildComponent()', () => {
    it('should add child component to map', () => {
      const child = new ComponentBase();
      component.addChildComponent('child', child);
      
      expect(component.childComponents.get('child')).toBe(child);
    });

    it('should not add child if component is destroyed', () => {
      const child = new ComponentBase();
      component.destroy();
      component.addChildComponent('child', child);
      
      expect(component.childComponents.size).toBe(0);
    });
  });

  describe('removeChildComponent()', () => {
    it('should remove child component from map', () => {
      const child = new ComponentBase();
      component.addChildComponent('child', child);
      component.removeChildComponent('child');
      
      expect(component.childComponents.has('child')).toBe(false);
    });

    it('should destroy child component', () => {
      const child = new ComponentBase();
      child.destroy = vi.fn();
      
      component.addChildComponent('child', child);
      component.removeChildComponent('child');
      
      expect(child.destroy).toHaveBeenCalled();
    });

    it('should handle removing non-existent child', () => {
      expect(() => {
        component.removeChildComponent('nonexistent');
      }).not.toThrow();
    });
  });

  describe('find()', () => {
    it('should find element by selector', () => {
      const element = component.find('#test-1');
      expect(element).toBeTruthy();
      expect(element.id).toBe('test-1');
    });

    it('should return null if element not found', () => {
      const element = component.find('#nonexistent');
      expect(element).toBeNull();
    });

    it('should search within container only', () => {
      const outsideElement = document.createElement('div');
      outsideElement.id = 'outside';
      document.body.appendChild(outsideElement);
      
      const element = component.find('#outside');
      expect(element).toBeNull();
      
      outsideElement.remove();
    });
  });

  describe('findAll()', () => {
    it('should find all elements by selector', () => {
      const elements = component.findAll('.test-element');
      expect(elements).toHaveLength(2);
    });

    it('should return empty NodeList if no elements found', () => {
      const elements = component.findAll('.nonexistent');
      expect(elements).toHaveLength(0);
    });

    it('should search within container only', () => {
      const outsideElement = document.createElement('div');
      outsideElement.className = 'test-element';
      document.body.appendChild(outsideElement);
      
      const elements = component.findAll('.test-element');
      expect(elements).toHaveLength(2); // Should not include outside element
      
      outsideElement.remove();
    });
  });

  describe('isReady()', () => {
    it('should return false when not initialized', () => {
      expect(component.isReady()).toBe(false);
    });

    it('should return true when initialized', () => {
      component.init();
      expect(component.isReady()).toBe(true);
    });

    it('should return false when destroyed', () => {
      component.init();
      component.destroy();
      expect(component.isReady()).toBe(false);
    });
  });

  describe('emit()', () => {
    it('should emit custom event', () => {
      const handler = vi.fn();
      container.addEventListener('test-event', handler);
      
      component.emit('test-event');
      
      expect(handler).toHaveBeenCalled();
    });

    it('should include detail data in event', () => {
      const handler = vi.fn();
      container.addEventListener('test-event', handler);
      
      component.emit('test-event', { foo: 'bar' });
      
      expect(handler).toHaveBeenCalled();
      const event = handler.mock.calls[0][0];
      expect(event.detail.foo).toBe('bar');
    });

    it('should include component reference in event detail', () => {
      const handler = vi.fn();
      container.addEventListener('test-event', handler);
      
      component.emit('test-event');
      
      const event = handler.mock.calls[0][0];
      expect(event.detail.component).toBe(component);
    });

    it('should not emit if component is destroyed', () => {
      const handler = vi.fn();
      container.addEventListener('test-event', handler);
      
      component.destroy();
      component.emit('test-event');
      
      expect(handler).not.toHaveBeenCalled();
    });

    it('should create bubbling event', () => {
      const parentHandler = vi.fn();
      document.body.addEventListener('test-event', parentHandler);
      
      component.emit('test-event');
      
      expect(parentHandler).toHaveBeenCalled();
      
      document.body.removeEventListener('test-event', parentHandler);
    });
  });

  describe('on()', () => {
    it('should listen for custom events', () => {
      const handler = vi.fn();
      component.on('test-event', handler);
      
      component.emit('test-event');
      
      expect(handler).toHaveBeenCalled();
    });

    it('should track event listener', () => {
      const handler = vi.fn();
      component.on('test-event', handler);
      
      expect(component.eventListeners).toHaveLength(1);
    });
  });

  describe('once()', () => {
    it('should listen for event only once', () => {
      const handler = vi.fn();
      component.once('test-event', handler);
      
      component.emit('test-event');
      component.emit('test-event');
      
      expect(handler).toHaveBeenCalledTimes(1);
    });

    it('should remove listener after first call', () => {
      const handler = vi.fn();
      component.once('test-event', handler);
      
      component.emit('test-event');
      
      // The listener should be removed from tracking
      // (Note: It's removed during the handler execution)
      expect(component.eventListeners).toHaveLength(0);
    });
  });
});
