class MenuitemlocaleSerializer < ActiveModel::Serializer
  attributes :id, :locale, :status, :name, :description
  has_one :menuitem
end
