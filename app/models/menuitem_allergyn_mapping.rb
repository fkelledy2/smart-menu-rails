class MenuitemAllergynMapping < ApplicationRecord
  include IdentityCache

  belongs_to :menuitem
  belongs_to :allergyn

  # IdentityCache configuration
  cache_belongs_to :menuitem
  cache_belongs_to :allergyn
end
