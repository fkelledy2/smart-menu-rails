# frozen_string_literal: true

class AddJobIdempotencyKeyToCrmEmailSends < ActiveRecord::Migration[7.2]
  def change
    add_column :crm_email_sends, :job_idempotency_key, :string
    add_index  :crm_email_sends, :job_idempotency_key, unique: true,
                                                        where: 'job_idempotency_key IS NOT NULL',
                                                        name: 'index_crm_email_sends_on_job_idempotency_key'
  end
end
