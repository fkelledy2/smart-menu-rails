// Smart Menu API JavaScript Client
// Generated from OpenAPI specification

class SmartMenuAPI {
  constructor(baseURL = 'http://localhost:3000', apiKey = null) {
    this.baseURL = baseURL;
    this.apiKey = apiKey;
  }
  
  async request(method, path, data = null) {
    const url = `${this.baseURL}${path}`;
    const headers = {
      'Content-Type': 'application/json',
    };
    
    if (this.apiKey) {
      headers['X-API-Key'] = this.apiKey;
    }
    
    const options = {
      method,
      headers,
    };
    
    if (data) {
      options.body = JSON.stringify(data);
    }
    
    const response = await fetch(url, options);
    
    if (!response.ok) {
      throw new Error(`API request failed: ${response.status} ${response.statusText}`);
    }
    
    return response.json();
  }
  
  // Analytics endpoints
  async trackEvent(event, properties = {}) {
    return this.request('POST', '/api/v1/analytics/track', { event, properties });
  }
  
  async trackAnonymousEvent(event, properties = {}) {
    return this.request('POST', '/api/v1/analytics/track_anonymous', { event, properties });
  }
  
  // Vision API endpoints
  async analyzeImage(imageFile, features = 'labels,text') {
    const formData = new FormData();
    formData.append('image', imageFile);
    formData.append('features', features);
    
    const response = await fetch(`${this.baseURL}/api/v1/vision/analyze`, {
      method: 'POST',
      body: formData,
    });
    
    if (!response.ok) {
      throw new Error(`Vision API request failed: ${response.status} ${response.statusText}`);
    }
    
    return response.json();
  }
}

// Export for Node.js and browser
if (typeof module !== 'undefined' && module.exports) {
  module.exports = SmartMenuAPI;
} else {
  window.SmartMenuAPI = SmartMenuAPI;
}
