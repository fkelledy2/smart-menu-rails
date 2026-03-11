class Ordritemnote < ApplicationRecord
  belongs_to :ordritem, touch: true
end
