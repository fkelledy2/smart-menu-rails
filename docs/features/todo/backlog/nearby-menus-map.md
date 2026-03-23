# Nearby Menus Map Feature

## Overview
Create an interactive marketing page showing restaurants and their menus on a map, allowing potential customers to discover nearby dining options and explore menus before visiting.

## Business Value
- **Customer Acquisition**: Helps potential customers discover restaurants in their area
- **Marketing**: Showcases restaurant variety and availability to drive traffic
- **Competitive Advantage**: Visual restaurant discovery differentiates from competitors
- **Data Insights**: Collects location-based analytics for restaurant optimization

## User Stories

### Potential Customer
- As a potential customer, I want to see restaurants near me on a map so I can discover new dining options
- As a potential customer, I want to filter restaurants by cuisine type, price range, and ratings
- As a potential customer, I want to preview menus before deciding where to dine
- As a potential customer, I want to see restaurant details like hours, photos, and contact information

### Restaurant Owner
- As a restaurant owner, I want my restaurant to appear on the map to attract new customers
- As a restaurant owner, I want to control what information is displayed (menu preview, photos, etc.)
- As a restaurant owner, I want to see analytics about how many people view my restaurant on the map
- As a restaurant owner, I want to highlight special offers or events on the map

### Marketing Manager
- As a marketing manager, I want to promote featured restaurants on the map
- As a marketing manager, I want to track user engagement and conversion metrics
- As a marketing manager, I want to A/B test different map features and layouts

## Technical Requirements

### Data Model Changes

#### RestaurantLocation Model (New)
```ruby
create_table :restaurant_locations do |t|
  t.references :restaurant, null: false, foreign_key: true
  t.decimal :latitude, precision: 10, scale: 6, null: false
  t.decimal :longitude, precision: 10, scale: 6, null: false
  t.string :address, null: false
  t.string :city
  t.string :state
  t.string :postal_code
  t.string :country
  t.boolean :visible_on_map, default: true
  t.datetime :verified_at
  t.timestamps
  
  t.index :restaurant_id
  t.index [:latitude, :longitude]
  t.index :visible_on_map
end
```

#### MapAnalytics Model (New)
```ruby
create_table :map_analytics do |t|
  t.references :restaurant, foreign_key: true
  t.string :event_type  # 'view', 'click', 'menu_preview', 'directions'
  t.string :session_id
  t.string :ip_address
  jsonb :metadata
  t.datetime :created_at
  
  t.index :restaurant_id
  t.index :event_type
  t.index :created_at
end
```

#### Restaurant Model Enhancements
```ruby
# Add fields for map display
add_column :restaurants, :map_featured, :boolean, default: false
add_column :restaurants, :map_description, :text
add_column :restaurants, :cuisine_tags, :string, array: true
add_column :restaurants, :price_range, :integer  # 1: $, 2: $$, 3: $$$, 4: $$$$
add_column :restaurants, :map_order_count, :integer, default: 0
```

### Map Integration

#### Map Provider Options
1. **Google Maps API** (Primary)
   - Rich features and documentation
   - Places API for restaurant search
   - Street View integration
   - Cost: $200/month free tier, then $7/1000 requests

2. **Mapbox** (Alternative)
   - Customizable styling
   - Affordable pricing
   - Good performance
   - Cost: $200/month free tier, then $5/1000 requests

3. **OpenStreetMap** (Free)
   - No cost
   - Community-driven
   - Limited features
   - Self-hosting required

#### Initial Implementation: Google Maps
```ruby
# config/initializers/google_maps.rb
Rails.application.config.google_maps_api_key = ENV['GOOGLE_MAPS_API_KEY']

# app/services/geocoding_service.rb
class GeocodingService
  def self.geocode_address(address)
    client = GoogleMaps::Client.new(key: Rails.application.config.google_maps_api_key)
    result = client.geocode(address)
    
    {
      latitude: result.first[:geometry][:location][:lat],
      longitude: result.first[:geometry][:location][:lng],
      formatted_address: result.first[:formatted_address]
    }
  rescue => e
    Rails.logger.error "Geocoding failed: #{e.message}"
    nil
  end
end
```

### API Changes

#### Map Data Endpoints
```ruby
# GET /api/v1/restaurants/nearby
# Query parameters: lat, lng, radius, cuisine, price_range, featured
{
  "restaurants": [
    {
      "id": 123,
      "name": "The Steakhouse",
      "latitude": 40.7128,
      "longitude": -74.0060,
      "address": "123 Main St, New York, NY",
      "distance": 0.5,
      "cuisine_tags": ["steakhouse", "american"],
      "price_range": 3,
      "rating": 4.5,
      "review_count": 128,
      "hours": {
        "monday": "11:00-22:00",
        "tuesday": "11:00-22:00",
        # ...
      },
      "featured_menu_items": [
        {
          "name": "Ribeye Steak",
          "price": 45.00,
          "description": "12oz prime ribeye"
        }
      ],
      "photos": [
        "https://example.com/photo1.jpg"
      ],
      "map_featured": true,
      "smartmenu_url": "https://mellow.menu/s/the-steakhouse"
    }
  ],
  "total_count": 25,
  "search_radius": 5.0
}

# GET /api/v1/restaurants/:id/map_preview
# Response: Restaurant details for map popup

# POST /api/v1/map_analytics
# Track user interactions
{
  "restaurant_id": 123,
  "event_type": "menu_preview",
  "metadata": {
    "source": "map_popup",
    "user_location": "40.7128,-74.0060"
  }
}
```

### UI/UX Requirements

#### Map Interface
- Full-screen interactive map
- Restaurant markers with custom icons
- Cluster markers for dense areas
- Search by location or address
- Filter sidebar with options
- Responsive design for mobile

#### Restaurant Popup
- Restaurant name and rating
- Cuisine type and price range
- Featured menu items (3-5 items)
- Photo gallery
- Hours of operation
- Quick actions: View Menu, Get Directions, Call

#### Filter Options
- Cuisine type (multi-select)
- Price range ($ to $$$$)
- Distance radius
- Rating threshold
- Currently open
- Featured restaurants
- Dietary restrictions

#### Search Functionality
- Address search with autocomplete
- "Near me" location detection
- Search by restaurant name
- Recent searches

### Frontend Implementation

#### React Component Structure
```jsx
// components/RestaurantMap.jsx
const RestaurantMap = () => {
  const [restaurants, setRestaurants] = useState([]);
  const [filters, setFilters] = useState({});
  const [userLocation, setUserLocation] = useState(null);
  const [selectedRestaurant, setSelectedRestaurant] = useState(null);
  
  return (
    <div className="restaurant-map">
      <FilterPanel filters={filters} onChange={setFilters} />
      <GoogleMap
        restaurants={restaurants}
        onRestaurantClick={setSelectedRestaurant}
        userLocation={userLocation}
      />
      <RestaurantPopup restaurant={selectedRestaurant} />
    </div>
  );
};

// components/RestaurantMarker.jsx
const RestaurantMarker = ({ restaurant, onClick }) => {
  const iconUrl = getMarkerIcon(restaurant.cuisine_tags[0]);
  
  return (
    <Marker
      position={{ lat: restaurant.latitude, lng: restaurant.longitude }}
      icon={{ url: iconUrl, scaledSize: { width: 32, height: 32 } }}
      onClick={() => onClick(restaurant)}
    />
  );
};
```

#### Map Styling
```javascript
// Custom map styles
const mapStyles = [
  {
    featureType: "poi",
    elementType: "labels",
    stylers: [{ visibility: "off" }]
  },
  {
    featureType: "transit",
    elementType: "labels",
    stylers: [{ visibility: "off" }]
  }
];
```

### Business Logic

#### Location-Based Search
```ruby
class NearbyRestaurantsService
  def self.find_nearby(lat, lng, radius = 5, filters = {})
    restaurants = Restaurant.joins(:restaurant_location)
      .where(restaurant_locations: { visible_on_map: true })
      .where("ST_DWithin(restaurant_locations.coordinates, ST_MakePoint(?, ?), ?)", 
             lng, lat, radius * 1609.34)  # Convert miles to meters
    
    # Apply filters
    restaurants = filter_by_cuisine(restaurants, filters[:cuisine])
    restaurants = filter_by_price_range(restaurants, filters[:price_range])
    restaurants = filter_by_rating(restaurants, filters[:min_rating])
    
    # Calculate distances and sort
    restaurants = restaurants.select(
      "restaurants.*",
      "ST_Distance(restaurant_locations.coordinates, ST_MakePoint(?, ?)) as distance",
      "restaurant_locations.latitude",
      "restaurant_locations.longitude"
    ).order('distance ASC')
    
    # Format results
    restaurants.map { |r| format_restaurant_for_map(r) }
  end
  
  private
  
  def self.filter_by_cuisine(restaurants, cuisines)
    return restaurants if cuisines.blank?
    restaurants.where("cuisine_tags && ?", Array(cuisines))
  end
  
  def self.filter_by_price_range(restaurants, price_ranges)
    return restaurants if price_ranges.blank?
    restaurants.where(price_range: price_ranges)
  end
  
  def self.filter_by_rating(restaurants, min_rating)
    return restaurants if min_rating.blank?
    restaurants.where("average_rating >= ?", min_rating)
  end
  
  def self.format_restaurant_for_map(restaurant)
    {
      id: restaurant.id,
      name: restaurant.name,
      latitude: restaurant.latitude,
      longitude: restaurant.longitude,
      distance: (restaurant.distance / 1609.34).round(2),  # Convert to miles
      # ... other fields
    }
  end
end
```

#### Analytics Tracking
```ruby
class MapAnalyticsService
  def self.track_event(restaurant, event_type, metadata = {})
    MapAnalytics.create!(
      restaurant: restaurant,
      event_type: event_type,
      session_id: metadata[:session_id],
      ip_address: metadata[:ip_address],
      metadata: metadata.except(:session_id, :ip_address)
    )
    
    # Update restaurant stats
    restaurant.increment!(:map_order_count) if event_type == 'menu_preview'
  end
end
```

### Implementation Phases

#### Phase 1: Basic Map
1. Google Maps integration
2. Restaurant location data
3. Basic marker display
4. Simple search functionality

#### Phase 2: Enhanced Features
1. Filter system
2. Restaurant popups
3. Menu previews
4. Analytics tracking

#### Phase 3: Advanced Features
1. Clustering for dense areas
2. Custom map styling
3. Featured restaurants
4. Mobile optimization

#### Phase 4: Analytics & Marketing
1. Detailed analytics dashboard
2. A/B testing capabilities
3. Promotional features
4. Performance optimization

### Testing Requirements

#### Unit Tests
- Geocoding service
- Location-based queries
- Analytics tracking
- Filter logic

#### Integration Tests
- API endpoints
- Database queries
- External API integration
- Data formatting

#### System Tests
- Complete map interactions
- Search functionality
- Filter combinations
- Mobile responsiveness

### Performance Considerations
- Efficient spatial queries (PostGIS)
- Restaurant data caching
- Lazy loading for map data
- Image optimization for photos
- CDN for static assets

### Security Considerations
- API rate limiting
- Location data privacy
- Input validation for search
- Secure API key management

### Dependencies
- Google Maps API key
- PostGIS for spatial queries
- Redis for caching
- Image storage (AWS S3)

### Cost Analysis
- Google Maps API: ~$200/month for moderate traffic
- Additional server resources for spatial queries
- Image storage and CDN costs
- Development and maintenance time

### Rollout Strategy
1. Internal testing with sample data
2. Beta launch in limited geographic area
3. Gradual rollout with performance monitoring
4. Marketing campaign to drive traffic
5. Continuous optimization based on analytics
