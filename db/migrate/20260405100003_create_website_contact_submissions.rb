# frozen_string_literal: true

class CreateWebsiteContactSubmissions < ActiveRecord::Migration[7.2]
  def change
    create_table :website_contact_submissions do |t|
      # Contact details
      t.string   :name,              null: false
      t.string   :email,             null: false
      t.string   :phone
      t.string   :company_name
      t.string   :restaurant_name
      t.string   :website            # honeypot field — should always be blank

      # Message
      t.text     :message,           null: false

      # Tracking metadata
      t.datetime :submitted_at,      null: false
      t.string   :ip_address
      t.string   :user_agent
      t.string   :referrer
      t.string   :utm_source
      t.string   :utm_medium
      t.string   :utm_campaign

      # Processing state
      t.string   :processing_status, null: false, default: 'pending'
      t.text     :error_message
      t.datetime :processed_at

      # Link to resulting lead (nullify on lead deletion, not cascade delete)
      t.references :crm_lead, null: true, foreign_key: { on_delete: :nullify }

      t.timestamps
    end

    add_index :website_contact_submissions, :email,
              name: 'index_website_contact_submissions_on_email'
    add_index :website_contact_submissions, :processing_status,
              name: 'index_website_contact_submissions_on_processing_status'
  end
end
