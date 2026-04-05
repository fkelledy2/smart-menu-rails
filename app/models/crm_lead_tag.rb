# frozen_string_literal: true

class CrmLeadTag < ApplicationRecord
  VALID_TAGS = %w[unsolicited inbound].freeze

  belongs_to :crm_lead

  validates :tag, presence: true, inclusion: { in: VALID_TAGS }
  validates :crm_lead_id, uniqueness: { scope: :tag, message: 'already has this tag' }
end
