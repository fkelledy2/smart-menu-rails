class MenulocaleSerializer < ActiveModel::Serializer
  attributes :id, :locale, :status, :name, :description
  has_one :menu
end
