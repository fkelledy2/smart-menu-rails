class AddCityToCrmLeads < ActiveRecord::Migration[7.2]
  def change
    add_column :crm_leads, :city, :string
  end
end
