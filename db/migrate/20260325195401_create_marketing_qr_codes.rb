# frozen_string_literal: true

class CreateMarketingQrCodes < ActiveRecord::Migration[7.2]
  def change
    create_table :marketing_qr_codes do |t|
      t.string  :token,              null: false
      t.integer :status,             null: false, default: 0
      t.string  :holding_url
      t.bigint  :restaurant_id
      t.bigint  :menu_id
      t.bigint  :tablesetting_id
      t.bigint  :smartmenu_id
      t.bigint  :created_by_user_id, null: false
      t.string  :name
      t.string  :campaign

      t.timestamps null: false
    end

    add_index :marketing_qr_codes, :token,              unique: true
    add_index :marketing_qr_codes, :status
    add_index :marketing_qr_codes, :restaurant_id
    add_index :marketing_qr_codes, :created_by_user_id

    add_foreign_key :marketing_qr_codes, :restaurants,   column: :restaurant_id,   on_delete: :nullify
    add_foreign_key :marketing_qr_codes, :menus,         column: :menu_id,         on_delete: :nullify
    add_foreign_key :marketing_qr_codes, :tablesettings, column: :tablesetting_id, on_delete: :nullify
    add_foreign_key :marketing_qr_codes, :smartmenus,    column: :smartmenu_id,    on_delete: :nullify
    add_foreign_key :marketing_qr_codes, :users,         column: :created_by_user_id
  end
end
