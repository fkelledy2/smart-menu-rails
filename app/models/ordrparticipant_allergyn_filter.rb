class OrdrparticipantAllergynFilter < ApplicationRecord
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :ordrparticipant
  belongs_to :allergyn

  # IdentityCache configuration
  cache_index :id
  cache_index :ordrparticipant_id
  cache_index :allergyn_id

  # Cache associations
  cache_belongs_to :ordrparticipant
  cache_belongs_to :allergyn
end
