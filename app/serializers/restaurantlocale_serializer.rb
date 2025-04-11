class RestaurantlocaleSerializer < ActiveModel::Serializer
  attributes :id, :locale, :status
  has_one :restaurant
end
