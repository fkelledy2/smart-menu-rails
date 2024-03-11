class MenuitemAllergynMapping < ApplicationRecord
  belongs_to :menuitem
  belongs_to :allergyn
end
