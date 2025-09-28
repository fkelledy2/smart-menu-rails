class PlanSerializer < ActiveModel::Serializer
  attributes :id, :key, :descriptionKey, :attribute1, :attribute2, :attribute3, :attribute4, :attribute5, :attribut6,
             :status, :favourite, :pricePerMonth, :pricePerYear, :action
end
