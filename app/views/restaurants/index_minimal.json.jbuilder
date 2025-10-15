# Minimal restaurants index for table display - optimized for performance
json.array! @restaurants, partial: 'restaurants/restaurant_minimal', as: :restaurant
