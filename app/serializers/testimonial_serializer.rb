class TestimonialSerializer < ActiveModel::Serializer
  attributes :id, :testimonial
  has_one :user
  has_one :restaurant
end
