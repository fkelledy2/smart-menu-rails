/**
 * DOM manipulation utilities
 * Provides jQuery-like functionality with modern JavaScript
 */

/**
 * Find element(s) with optional context
 */
export function $(selector, context = document) {
  if (typeof selector === 'string') {
    return context.querySelector(selector);
  }
  return selector; // Already an element
}

export function $$(selector, context = document) {
  if (typeof selector === 'string') {
    return Array.from(context.querySelectorAll(selector));
  }
  return Array.isArray(selector) ? selector : [selector];
}

/**
 * Check if element exists
 */
export function exists(selector, context = document) {
  return $(selector, context) !== null;
}

/**
 * Wait for element to exist
 */
export function waitForElement(selector, timeout = 5000) {
  return new Promise((resolve, reject) => {
    const element = $(selector);
    if (element) {
      resolve(element);
      return;
    }

    const observer = new MutationObserver((mutations, obs) => {
      const element = $(selector);
      if (element) {
        obs.disconnect();
        resolve(element);
      }
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true
    });

    setTimeout(() => {
      observer.disconnect();
      reject(new Error(`Element ${selector} not found within ${timeout}ms`));
    }, timeout);
  });
}

/**
 * Add class(es) to element(s)
 */
export function addClass(elements, className) {
  $$(elements).forEach(el => {
    if (className.includes(' ')) {
      el.classList.add(...className.split(' '));
    } else {
      el.classList.add(className);
    }
  });
}

/**
 * Remove class(es) from element(s)
 */
export function removeClass(elements, className) {
  $$(elements).forEach(el => {
    if (className.includes(' ')) {
      el.classList.remove(...className.split(' '));
    } else {
      el.classList.remove(className);
    }
  });
}

/**
 * Toggle class on element(s)
 */
export function toggleClass(elements, className) {
  $$(elements).forEach(el => {
    el.classList.toggle(className);
  });
}

/**
 * Check if element has class
 */
export function hasClass(element, className) {
  return $(element).classList.contains(className);
}

/**
 * Show element(s)
 */
export function show(elements) {
  $$(elements).forEach(el => {
    el.style.display = '';
    el.removeAttribute('hidden');
  });
}

/**
 * Hide element(s)
 */
export function hide(elements) {
  $$(elements).forEach(el => {
    el.style.display = 'none';
  });
}

/**
 * Toggle visibility of element(s)
 */
export function toggle(elements) {
  $$(elements).forEach(el => {
    if (el.style.display === 'none') {
      show(el);
    } else {
      hide(el);
    }
  });
}

/**
 * Get/set element text content
 */
export function text(element, content = null) {
  const el = $(element);
  if (content === null) {
    return el.textContent;
  }
  el.textContent = content;
  return el;
}

/**
 * Get/set element HTML content
 */
export function html(element, content = null) {
  const el = $(element);
  if (content === null) {
    return el.innerHTML;
  }
  el.innerHTML = content;
  return el;
}

/**
 * Get/set element value
 */
export function val(element, value = null) {
  const el = $(element);
  if (value === null) {
    return el.value;
  }
  el.value = value;
  return el;
}

/**
 * Get/set element attribute
 */
export function attr(element, name, value = null) {
  const el = $(element);
  if (value === null) {
    return el.getAttribute(name);
  }
  el.setAttribute(name, value);
  return el;
}

/**
 * Remove attribute from element
 */
export function removeAttr(element, name) {
  $(element).removeAttribute(name);
}

/**
 * Get/set element data attribute
 */
export function data(element, name, value = null) {
  const el = $(element);
  if (value === null) {
    return el.dataset[name];
  }
  el.dataset[name] = value;
  return el;
}

/**
 * Create element with optional attributes and content
 */
export function createElement(tag, attributes = {}, content = '') {
  const element = document.createElement(tag);
  
  Object.keys(attributes).forEach(key => {
    if (key === 'className') {
      element.className = attributes[key];
    } else if (key === 'textContent') {
      element.textContent = attributes[key];
    } else if (key === 'innerHTML') {
      element.innerHTML = attributes[key];
    } else {
      element.setAttribute(key, attributes[key]);
    }
  });
  
  if (content) {
    if (typeof content === 'string') {
      element.innerHTML = content;
    } else {
      element.appendChild(content);
    }
  }
  
  return element;
}

/**
 * Append element(s) to parent
 */
export function append(parent, children) {
  const parentEl = $(parent);
  $$(children).forEach(child => {
    parentEl.appendChild(child);
  });
}

/**
 * Prepend element(s) to parent
 */
export function prepend(parent, children) {
  const parentEl = $(parent);
  $$(children).forEach(child => {
    parentEl.insertBefore(child, parentEl.firstChild);
  });
}

/**
 * Remove element(s) from DOM
 */
export function remove(elements) {
  $$(elements).forEach(el => {
    if (el.parentNode) {
      el.parentNode.removeChild(el);
    }
  });
}

/**
 * Get element's offset position
 */
export function offset(element) {
  const el = $(element);
  const rect = el.getBoundingClientRect();
  return {
    top: rect.top + window.pageYOffset,
    left: rect.left + window.pageXOffset,
    width: rect.width,
    height: rect.height
  };
}

/**
 * Get element's position relative to parent
 */
export function position(element) {
  const el = $(element);
  return {
    top: el.offsetTop,
    left: el.offsetLeft,
    width: el.offsetWidth,
    height: el.offsetHeight
  };
}

/**
 * Scroll to element
 */
export function scrollTo(element, options = {}) {
  const el = $(element);
  const defaultOptions = {
    behavior: 'smooth',
    block: 'start',
    inline: 'nearest'
  };
  
  el.scrollIntoView({ ...defaultOptions, ...options });
}

/**
 * Check if element is visible in viewport
 */
export function isInViewport(element) {
  const el = $(element);
  const rect = el.getBoundingClientRect();
  
  return (
    rect.top >= 0 &&
    rect.left >= 0 &&
    rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
    rect.right <= (window.innerWidth || document.documentElement.clientWidth)
  );
}

/**
 * Debounce function calls
 */
export function debounce(func, wait, immediate = false) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      timeout = null;
      if (!immediate) func(...args);
    };
    const callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) func(...args);
  };
}

/**
 * Throttle function calls
 */
export function throttle(func, limit) {
  let inThrottle;
  return function(...args) {
    if (!inThrottle) {
      func.apply(this, args);
      inThrottle = true;
      setTimeout(() => inThrottle = false, limit);
    }
  };
}

/**
 * Get form data as object
 */
export function getFormData(form) {
  const formData = new FormData($(form));
  const data = {};
  
  for (let [key, value] of formData.entries()) {
    if (data[key]) {
      if (Array.isArray(data[key])) {
        data[key].push(value);
      } else {
        data[key] = [data[key], value];
      }
    } else {
      data[key] = value;
    }
  }
  
  return data;
}

/**
 * Set form data from object
 */
export function setFormData(form, data) {
  const formEl = $(form);
  
  Object.keys(data).forEach(key => {
    const field = formEl.querySelector(`[name="${key}"]`);
    if (field) {
      if (field.type === 'checkbox' || field.type === 'radio') {
        field.checked = field.value === data[key];
      } else {
        field.value = data[key];
      }
    }
  });
}

/**
 * Animate element with CSS transitions
 */
export function animate(element, properties, duration = 300) {
  return new Promise((resolve) => {
    const el = $(element);
    const originalTransition = el.style.transition;
    
    el.style.transition = `all ${duration}ms ease`;
    
    Object.keys(properties).forEach(prop => {
      el.style[prop] = properties[prop];
    });
    
    setTimeout(() => {
      el.style.transition = originalTransition;
      resolve(el);
    }, duration);
  });
}

/**
 * Fade in element
 */
export function fadeIn(element, duration = 300) {
  const el = $(element);
  el.style.opacity = '0';
  el.style.display = '';
  
  return animate(el, { opacity: '1' }, duration);
}

/**
 * Fade out element
 */
export function fadeOut(element, duration = 300) {
  const el = $(element);
  
  return animate(el, { opacity: '0' }, duration).then(() => {
    el.style.display = 'none';
    return el;
  });
}

/**
 * Slide down element
 */
export function slideDown(element, duration = 300) {
  const el = $(element);
  const height = el.scrollHeight;
  
  el.style.height = '0';
  el.style.overflow = 'hidden';
  el.style.display = '';
  
  return animate(el, { height: `${height}px` }, duration).then(() => {
    el.style.height = '';
    el.style.overflow = '';
    return el;
  });
}

/**
 * Slide up element
 */
export function slideUp(element, duration = 300) {
  const el = $(element);
  
  return animate(el, { height: '0' }, duration).then(() => {
    el.style.display = 'none';
    el.style.height = '';
    return el;
  });
}
