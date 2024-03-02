class Menusection < ApplicationRecord
  belongs_to :menu
  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }
end
