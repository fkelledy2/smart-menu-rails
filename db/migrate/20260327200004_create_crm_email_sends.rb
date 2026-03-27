# frozen_string_literal: true

class CreateCrmEmailSends < ActiveRecord::Migration[7.2]
  def change
    create_table :crm_email_sends do |t|
      t.references :crm_lead, null: false, foreign_key: true
      t.references :sender,   null: false, foreign_key: { to_table: :users }
      t.string :to_email,     null: false
      t.string :subject,      null: false
      t.text   :body_html
      t.text   :body_text
      t.string :mailer_message_id
      t.datetime :sent_at

      t.timestamps
    end
  end
end
