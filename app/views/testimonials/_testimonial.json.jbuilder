  json.id testimonial.id
  json.status testimonial.status
  json.testimonial testimonial.testimonial
  json.first_name testimonial.user.first_name
  json.restaurant_name testimonial.restaurant.name
  json.created_at testimonial.created_at
  json.updated_at testimonial.updated_at
  json.url testimonial_url(testimonial, format: :json)
