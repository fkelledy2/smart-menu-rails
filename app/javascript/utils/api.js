/**
 * API request utilities
 * Provides consistent interface for making HTTP requests
 */

/**
 * Get CSRF token from meta tag
 */
function getCSRFToken() {
  const token = document.querySelector("meta[name='csrf-token']");
  return token ? token.content : null;
}

/**
 * Default request options
 */
const DEFAULT_OPTIONS = {
  headers: {
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
  },
  credentials: 'same-origin',
};

/**
 * Add CSRF token to headers if available
 */
function addCSRFToken(options) {
  const token = getCSRFToken();
  if (token) {
    options.headers = {
      ...options.headers,
      'X-CSRF-Token': token,
    };
  }
  return options;
}

/**
 * Handle response based on content type
 */
async function handleResponse(response) {
  const contentType = response.headers.get('content-type');

  if (!response.ok) {
    let errorMessage = `HTTP ${response.status}: ${response.statusText}`;

    try {
      if (contentType && contentType.includes('application/json')) {
        const errorData = await response.json();
        errorMessage = errorData.message || errorData.error || errorMessage;
      } else {
        errorMessage = (await response.text()) || errorMessage;
      }
    } catch (e) {
      // Use default error message if parsing fails
    }

    throw new Error(errorMessage);
  }

  if (contentType && contentType.includes('application/json')) {
    return response.json();
  }

  return response.text();
}

/**
 * Make a GET request
 */
export async function get(url, options = {}) {
  const requestOptions = {
    ...DEFAULT_OPTIONS,
    ...options,
    method: 'GET',
  };

  const response = await fetch(url, addCSRFToken(requestOptions));
  return handleResponse(response);
}

/**
 * Make a POST request
 */
export async function post(url, data = null, options = {}) {
  const requestOptions = {
    ...DEFAULT_OPTIONS,
    ...options,
    method: 'POST',
  };

  if (data) {
    if (data instanceof FormData) {
      // Remove Content-Type header for FormData (browser will set it with boundary)
      delete requestOptions.headers['Content-Type'];
      requestOptions.body = data;
    } else {
      requestOptions.body = JSON.stringify(data);
    }
  }

  const response = await fetch(url, addCSRFToken(requestOptions));
  return handleResponse(response);
}

/**
 * Make a PUT request
 */
export async function put(url, data = null, options = {}) {
  const requestOptions = {
    ...DEFAULT_OPTIONS,
    ...options,
    method: 'PUT',
  };

  if (data) {
    if (data instanceof FormData) {
      delete requestOptions.headers['Content-Type'];
      requestOptions.body = data;
    } else {
      requestOptions.body = JSON.stringify(data);
    }
  }

  const response = await fetch(url, addCSRFToken(requestOptions));
  return handleResponse(response);
}

/**
 * Make a PATCH request
 */
export async function patch(url, data = null, options = {}) {
  const requestOptions = {
    ...DEFAULT_OPTIONS,
    ...options,
    method: 'PATCH',
  };

  if (data) {
    if (data instanceof FormData) {
      delete requestOptions.headers['Content-Type'];
      requestOptions.body = data;
    } else {
      requestOptions.body = JSON.stringify(data);
    }
  }

  const response = await fetch(url, addCSRFToken(requestOptions));
  return handleResponse(response);
}

/**
 * Make a DELETE request
 */
export async function del(url, options = {}) {
  const requestOptions = {
    ...DEFAULT_OPTIONS,
    ...options,
    method: 'DELETE',
  };

  const response = await fetch(url, addCSRFToken(requestOptions));
  return handleResponse(response);
}

/**
 * Upload file with progress tracking
 */
export function uploadFile(url, file, options = {}) {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    const formData = new FormData();

    formData.append('file', file);

    // Add additional form data if provided
    if (options.data) {
      Object.keys(options.data).forEach((key) => {
        formData.append(key, options.data[key]);
      });
    }

    // Set up progress tracking
    if (options.onProgress) {
      xhr.upload.addEventListener('progress', (e) => {
        if (e.lengthComputable) {
          const percentComplete = (e.loaded / e.total) * 100;
          options.onProgress(percentComplete, e.loaded, e.total);
        }
      });
    }

    // Set up completion handlers
    xhr.addEventListener('load', () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          const response = JSON.parse(xhr.responseText);
          resolve(response);
        } catch (e) {
          resolve(xhr.responseText);
        }
      } else {
        reject(new Error(`Upload failed: ${xhr.status} ${xhr.statusText}`));
      }
    });

    xhr.addEventListener('error', () => {
      reject(new Error('Upload failed: Network error'));
    });

    xhr.addEventListener('abort', () => {
      reject(new Error('Upload aborted'));
    });

    // Set headers
    const token = getCSRFToken();
    if (token) {
      xhr.setRequestHeader('X-CSRF-Token', token);
    }
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');

    // Start upload
    xhr.open('POST', url);
    xhr.send(formData);

    // Return xhr for potential cancellation
    return xhr;
  });
}

/**
 * Make multiple requests in parallel
 */
export async function parallel(requests) {
  const promises = requests.map(({ method, url, data, options }) => {
    switch (method.toLowerCase()) {
      case 'get':
        return get(url, options);
      case 'post':
        return post(url, data, options);
      case 'put':
        return put(url, data, options);
      case 'patch':
        return patch(url, data, options);
      case 'delete':
        return del(url, options);
      default:
        throw new Error(`Unsupported method: ${method}`);
    }
  });

  return Promise.all(promises);
}

/**
 * Make requests in sequence
 */
export async function sequence(requests) {
  const results = [];

  for (const { method, url, data, options } of requests) {
    let result;

    switch (method.toLowerCase()) {
      case 'get':
        result = await get(url, options);
        break;
      case 'post':
        result = await post(url, data, options);
        break;
      case 'put':
        result = await put(url, data, options);
        break;
      case 'patch':
        result = await patch(url, data, options);
        break;
      case 'delete':
        result = await del(url, options);
        break;
      default:
        throw new Error(`Unsupported method: ${method}`);
    }

    results.push(result);
  }

  return results;
}

/**
 * Request with retry logic
 */
export async function withRetry(requestFn, maxRetries = 3, delay = 1000) {
  let lastError;

  for (let i = 0; i <= maxRetries; i++) {
    try {
      return await requestFn();
    } catch (error) {
      lastError = error;

      if (i < maxRetries) {
        await new Promise((resolve) => setTimeout(resolve, delay * Math.pow(2, i)));
      }
    }
  }

  throw lastError;
}

/**
 * Request with timeout
 */
export async function withTimeout(requestFn, timeout = 10000) {
  const timeoutPromise = new Promise((_, reject) => {
    setTimeout(() => reject(new Error('Request timeout')), timeout);
  });

  return Promise.race([requestFn(), timeoutPromise]);
}

/**
 * Cache for GET requests
 */
const requestCache = new Map();

/**
 * Make a cached GET request
 */
export async function getCached(url, options = {}) {
  const cacheKey = `${url}${JSON.stringify(options)}`;
  const cached = requestCache.get(cacheKey);

  if (cached && Date.now() - cached.timestamp < (options.cacheTime || 300000)) {
    return cached.data;
  }

  const data = await get(url, options);
  requestCache.set(cacheKey, { data, timestamp: Date.now() });

  return data;
}

/**
 * Clear request cache
 */
export function clearCache(pattern = null) {
  if (pattern) {
    const regex = new RegExp(pattern);
    for (const key of requestCache.keys()) {
      if (regex.test(key)) {
        requestCache.delete(key);
      }
    }
  } else {
    requestCache.clear();
  }
}

/**
 * Create an API client for a specific base URL
 */
export function createClient(baseURL, defaultOptions = {}) {
  const client = {
    get: (path, options = {}) => get(`${baseURL}${path}`, { ...defaultOptions, ...options }),
    post: (path, data, options = {}) =>
      post(`${baseURL}${path}`, data, { ...defaultOptions, ...options }),
    put: (path, data, options = {}) =>
      put(`${baseURL}${path}`, data, { ...defaultOptions, ...options }),
    patch: (path, data, options = {}) =>
      patch(`${baseURL}${path}`, data, { ...defaultOptions, ...options }),
    delete: (path, options = {}) => del(`${baseURL}${path}`, { ...defaultOptions, ...options }),
  };

  return client;
}

// Export legacy functions for backward compatibility
export { del as delete };

// Global error handler
window.addEventListener('unhandledrejection', (event) => {
  if (event.reason && event.reason.message && event.reason.message.includes('HTTP')) {
    console.error('API Error:', event.reason.message);
    // You can emit an event here for global error handling
    document.dispatchEvent(
      new CustomEvent('api:error', {
        detail: { error: event.reason },
      })
    );
  }
});
