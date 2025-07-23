class DwOrdersMv < ApplicationRecord
  self.table_name = 'dw_orders_mv'

  # If the materialized view does not have a primary key, disable it:
  self.primary_key = nil

  # Optionally: set readonly if you do not want to allow modifications
  def readonly?
    true
  end
end
