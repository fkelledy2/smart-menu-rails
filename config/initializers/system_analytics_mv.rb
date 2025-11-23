# Ensure the system_analytics_mv relation exists in all environments (tests rely on it)
# Creates an empty VIEW with the expected columns if missing.

Rails.application.config.to_prepare do
  begin
    conn = ActiveRecord::Base.connection
    # Use data_source_exists? which works for tables and views
    unless conn.data_source_exists?('system_analytics_mv')
      conn.execute(<<~SQL)
        CREATE VIEW system_analytics_mv AS
        SELECT
          CURRENT_DATE::date AS date,
          date_trunc('month', CURRENT_DATE)::date AS month,
          0::integer AS new_restaurants,
          0::integer AS new_users,
          0::integer AS new_menus,
          0::integer AS new_menuitems,
          0::integer AS total_orders,
          0::numeric AS total_revenue,
          0::integer AS active_restaurants
        WHERE false;
      SQL
      Rails.logger.info('[Init] Created stub VIEW system_analytics_mv for analytics tests')
    end
  rescue StandardError => e
    Rails.logger.warn("[Init] Could not ensure system_analytics_mv view exists: #{e.class}: #{e.message}")
  end
end
