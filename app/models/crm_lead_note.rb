# frozen_string_literal: true

class CrmLeadNote < ApplicationRecord
  belongs_to :crm_lead, counter_cache: :notes_count
  belongs_to :author, class_name: 'User'

  validates :body, presence: true
end
