class Genimage < ApplicationRecord
  belongs_to :restaurant
  belongs_to :menu, optional: true
  belongs_to :menusection, optional: true
  belongs_to :menuitem, optional: true
end
