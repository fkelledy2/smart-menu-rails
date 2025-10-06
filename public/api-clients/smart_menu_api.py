"""
Smart Menu API Python Client
Generated from OpenAPI specification
"""

import requests
import json
from typing import Dict, Any, Optional

class SmartMenuAPI:
    def __init__(self, base_url: str = "http://localhost:3000", api_key: Optional[str] = None):
        self.base_url = base_url
        self.api_key = api_key
        self.session = requests.Session()
        
        if api_key:
            self.session.headers.update({"X-API-Key": api_key})
    
    def _request(self, method: str, path: str, data: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        url = f"{self.base_url}{path}"
        
        if method.upper() == "GET":
            response = self.session.get(url, params=data)
        elif method.upper() == "POST":
            response = self.session.post(url, json=data)
        elif method.upper() == "PUT":
            response = self.session.put(url, json=data)
        elif method.upper() == "PATCH":
            response = self.session.patch(url, json=data)
        elif method.upper() == "DELETE":
            response = self.session.delete(url)
        else:
            raise ValueError(f"Unsupported HTTP method: {method}")
        
        response.raise_for_status()
        return response.json()
    
    def track_event(self, event: str, properties: Dict[str, Any] = None) -> Dict[str, Any]:
        """Track an analytics event"""
        data = {"event": event}
        if properties:
            data["properties"] = properties
        return self._request("POST", "/api/v1/analytics/track", data)
    
    def track_anonymous_event(self, event: str, properties: Dict[str, Any] = None) -> Dict[str, Any]:
        """Track an anonymous analytics event"""
        data = {"event": event}
        if properties:
            data["properties"] = properties
        return self._request("POST", "/api/v1/analytics/track_anonymous", data)
    
    def analyze_image(self, image_path: str, features: str = "labels,text") -> Dict[str, Any]:
        """Analyze an image using Google Vision API"""
        url = f"{self.base_url}/api/v1/vision/analyze"
        
        with open(image_path, 'rb') as image_file:
            files = {'image': image_file}
            data = {'features': features}
            response = requests.post(url, files=files, data=data)
        
        response.raise_for_status()
        return response.json()

# Example usage
if __name__ == "__main__":
    api = SmartMenuAPI()
    
    # Track an event
    result = api.track_anonymous_event("page_viewed", {"page": "/menu/123"})
    print("Event tracked:", result)
