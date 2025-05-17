class MenuparticipantSerializer < ActiveModel::Serializer
  attributes :id, :sessionid, :preferredlocale
  has_one :smartmenu
end
