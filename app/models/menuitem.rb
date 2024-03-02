class Menuitem < ApplicationRecord
  belongs_to :menusection
  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }
end
