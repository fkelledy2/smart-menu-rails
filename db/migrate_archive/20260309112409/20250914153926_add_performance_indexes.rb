class AddPerformanceIndexes < ActiveRecord::Migration[7.1]
  def up
    # Indexes for inventories
    add_index_if_not_exists :inventories, :menuitem_id
    add_index_if_not_exists :inventories, :status
    add_index_if_not_exists :inventories, :archived

    # Indexes for menus
    add_index_if_not_exists :menus, :restaurant_id
    add_index_if_not_exists :menus, :status
    add_index_if_not_exists :menus, :archived

    # Indexes for menuitems
    add_index_if_not_exists :menuitems, :menusection_id
    add_index_if_not_exists :menuitems, :status
    add_index_if_not_exists :menuitems, :archived
    add_index_if_not_exists :menuitems, :sequence

    # Indexes for orders (ordrs table in database)
    if table_exists?(:ordrs)
      add_index_if_not_exists :ordrs, :restaurant_id
      add_index_if_not_exists :ordrs, :status
      add_index_if_not_exists :ordrs, :archived
      add_index_if_not_exists :ordrs, :created_at
      
      # Composite index for common query patterns
      add_index_if_not_exists :ordrs, [:restaurant_id, :status, :created_at], name: 'index_ordrs_on_restaurant_status_created'
    end

    # Indexes for order items (ordritems table)
    if table_exists?(:ordritems)
      add_index_if_not_exists :ordritems, :ordr_id
      add_index_if_not_exists :ordritems, :menuitem_id
      add_index_if_not_exists :ordritems, :status
    end

    # Indexes for polymorphic associations
    if table_exists?(:notifications)
      add_index_if_not_exists :notifications, [:recipient_type, :recipient_id]
    end

    # Indexes for join tables
    if table_exists?(:features_plans)
      add_index_if_not_exists :features_plans, [:plan_id, :feature_id], unique: true
    end
    
    if table_exists?(:menuavailabilities)
      add_index_if_not_exists :menuavailabilities, [:menu_id, :dayofweek], unique: true, name: 'index_menuavailabilities_on_menu_and_dayofweek'
    end
    
    if table_exists?(:menusectionlocales)
      add_index_if_not_exists :menusectionlocales, [:menusection_id, :locale], unique: true, name: 'index_menusectionlocales_on_menusection_and_locale'
    end

    # Basic indexes for menu and menuitem tables
    if table_exists?(:menus)
      add_index_if_not_exists :menus, :restaurant_id
    end
    
    if table_exists?(:menuitems)
      add_index_if_not_exists :menuitems, :menusection_id
    end
    
    # Expression index for case-insensitive search (if using PostgreSQL)
    if table_exists?(:menuitems) && !index_name_exists?(:menuitems, 'index_menuitems_on_lower_name')
      execute 'CREATE INDEX index_menuitems_on_lower_name ON menuitems (lower(name) varchar_pattern_ops)'
    end
  end

  def down
    # This is a simplified rollback - in a real scenario, you might want to be more specific
    # about which indexes to keep/remove
    remove_index_if_exists :inventories, :menuitem_id
    remove_index_if_exists :inventories, :status
    remove_index_if_exists :inventories, :archived

    remove_index_if_exists :menus, :restaurant_id
    remove_index_if_exists :menus, :status
    remove_index_if_exists :menus, :archived

    remove_index_if_exists :menuitems, :menusection_id
    remove_index_if_exists :menuitems, :status
    remove_index_if_exists :menuitems, :archived
    remove_index_if_exists :menuitems, :sequence

    remove_index_if_exists :ordrs, :restaurant_id
    remove_index_if_exists :ordrs, :status
    remove_index_if_exists :ordrs, :archived
    remove_index_if_exists :ordrs, :created_at
    
    remove_index_if_exists :ordrs, name: 'index_ordrs_on_restaurant_status_created'
    remove_index_if_exists :ordritems, :ordr_id
    remove_index_if_exists :ordritems, :menuitem_id
    remove_index_if_exists :ordritems, :status
    remove_index_if_exists :notifications, column: [:recipient_type, :recipient_id]
    remove_index_if_exists :features_plans, column: [:plan_id, :feature_id]
    remove_index_if_exists :menuavailabilities, name: 'index_menuavailabilities_on_menu_and_dayofweek'
    remove_index_if_exists :menusectionlocales, name: 'index_menusectionlocales_on_menusection_and_locale'
    remove_index_if_exists :menus, name: 'index_menus_on_restaurant_id_not_archived'
    remove_index_if_exists :menuitems, name: 'index_menuitems_on_menusection_id_not_archived'
    
    if index_name_exists?(:menuitems, 'index_menuitems_on_lower_name')
      remove_index :menuitems, name: 'index_menuitems_on_lower_name'
    end
  end

  private

  def add_index_if_not_exists(table, columns, **options)
    # Convert single column to array for consistent handling
    column_names = Array(columns)
    
    # Skip if any of the columns don't exist in the table
    unless column_names.all? { |col| column_exists?(table, col) }
      Rails.logger.warn "Skipping index on #{table}.#{column_names.join(',')} - column(s) not found"
      return false
    end

    index_name = options[:name] || "index_#{table}_on_#{column_names.join('_and_')}"

    unless index_name_exists?(table, index_name)
      add_index(table, columns, **options)
      true
    else
      false
    end
  end
  
  def column_exists?(table, column_name)
    return true if column_name.is_a?(Array)  # Skip array columns check for now
    
    connection = ActiveRecord::Base.connection
    table_name = connection.quote_table_name(table)
    column_name = column_name.to_s
    
    # Check if the column exists in the table
    connection.column_exists?(table_name, column_name)
  rescue => e
    Rails.logger.warn "Error checking if column #{column_name} exists in #{table}: #{e.message}"
    false
  end

  def remove_index_if_exists(table, column_or_options, options = {})
    index_name = if column_or_options.is_a?(Hash)
                   column_or_options[:name]
                 elsif options.is_a?(Hash) && options[:name]
                   options[:name]
                 elsif column_or_options.is_a?(Symbol) || column_or_options.is_a?(String)
                   "index_#{table}_on_#{column_or_options}"
                 elsif column_or_options.is_a?(Array)
                   "index_#{table}_on_#{column_or_options.join('_and_')}"
                 end

    # Convert symbol to string for comparison
    index_name = index_name.to_s if index_name
    
    # Check if index exists by name
    if index_name && index_name_exists?(table, index_name)
      remove_index(table, name: index_name)
    end
  rescue ArgumentError => e
    Rails.logger.warn "Could not remove index: #{e.message}"
  end
end
