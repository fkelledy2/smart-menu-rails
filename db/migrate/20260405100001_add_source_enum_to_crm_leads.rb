# frozen_string_literal: true

# Adds a normalised source enum to crm_leads:
#   manual | city_discovery | website_inbound | other
#
# Step 1: backfill all NULL rows to 'manual'; also backfill rows where
#   discovered_restaurant_id IS NOT NULL to 'city_discovery'.
#   Any leftover non-enum values (e.g. 'calendly', 'referral', 'website')
#   are coerced to 'other' so the NOT NULL constraint is safe to add.
# Step 2: apply NOT NULL constraint.
# Step 3: add an index for source-filter queries.
class AddSourceEnumToCrmLeads < ActiveRecord::Migration[7.2]
  def up
    # Backfill: city_discovery when linked to a discovered restaurant
    execute <<~SQL
      UPDATE crm_leads
      SET source = 'city_discovery'
      WHERE discovered_restaurant_id IS NOT NULL
        AND (source IS NULL OR source NOT IN ('manual','city_discovery','website_inbound','other'))
    SQL

    # Backfill: coerce any remaining non-conforming/NULL values to 'manual'
    execute <<~SQL
      UPDATE crm_leads
      SET source = 'manual'
      WHERE source IS NULL OR source NOT IN ('manual','city_discovery','website_inbound','other')
    SQL

    change_column_null :crm_leads, :source, false
    change_column_default :crm_leads, :source, 'manual'

    add_index :crm_leads, :source, name: 'index_crm_leads_on_source'
  end

  def down
    remove_index :crm_leads, name: 'index_crm_leads_on_source'
    change_column_null :crm_leads, :source, true
    change_column_default :crm_leads, :source, nil
  end
end
