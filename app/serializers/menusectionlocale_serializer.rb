class MenusectionlocaleSerializer < ActiveModel::Serializer
  attributes :id, :locale, :status, :name, :description
  has_one :menusection
end
