class MenuitemTagMapping < ApplicationRecord
  belongs_to :menuitem
  belongs_to :tag
end
