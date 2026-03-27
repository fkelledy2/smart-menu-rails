# frozen_string_literal: true

class CrmEmailSend < ApplicationRecord
  belongs_to :crm_lead
  belongs_to :sender, class_name: 'User'

  validates :to_email, presence: true
  validates :subject,  presence: true
end
