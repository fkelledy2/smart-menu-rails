# Minimal track data for table display - optimized for performance
json.id track.id
json.name track.name
json.artist track.artist
json.status track.status
json.sequence track.sequence
json.url restaurant_track_url(track.restaurant, track, format: :json)
