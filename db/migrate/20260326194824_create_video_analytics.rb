# frozen_string_literal: true

class CreateVideoAnalytics < ActiveRecord::Migration[7.2]
  def change
    create_table :video_analytics do |t|
      t.string  :video_id, null: false
      t.string  :session_id
      t.string  :event_type, null: false
      t.integer :timestamp_seconds
      t.inet    :ip_address
      t.text    :user_agent
      t.string  :referrer

      t.datetime :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :video_analytics, %i[video_id created_at]
    add_index :video_analytics, :event_type
  end
end
