json.id track.id
json.externalid track.externalid
json.sequence track.sequence
json.name track.name
json.description track.description
json.artist track.artist
json.image track.image
json.status track.status
json.restaurant_id track.restaurant_id
json.created_at track.created_at
json.updated_at track.updated_at
json.url restaurant_track_url(track.restaurant, track, format: :json)
