class OrdrSplitItemAssignment < ApplicationRecord
  belongs_to :ordr_split_plan
  belongs_to :ordr_split_payment
  belongs_to :ordritem

  validates :ordritem_id, uniqueness: { scope: :ordr_split_plan_id }
end
