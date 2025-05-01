class FeaturesPlanSerializer < ActiveModel::Serializer
  attributes :id, :featurePlanNote, :status
  has_one :plan
  has_one :feature
end
