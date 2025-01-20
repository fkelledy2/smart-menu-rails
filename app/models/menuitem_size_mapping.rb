class MenuitemSizeMapping < ApplicationRecord
  belongs_to :menuitem
  belongs_to :size

  def sizeName
      size.name
  end
end
