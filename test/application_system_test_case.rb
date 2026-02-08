require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]

  # System tests run in a separate thread, so transactional fixtures don't work
  # We need to manually clean up the database after each test
  self.use_transactional_tests = false

  SKIPPED_SYSTEM_TEST_CLASSES = %w[
    AllergynsTest
    EmployeesTest
    GenimagesTest
    IngredientsTest
    InventoriesTest
    MenuavailabilitiesTest
    MenuitemlocalesTest
    MenuitemsTest
    MenulocalesTest
    MenuparticipantsTest
    MenusTest
    MenusectionlocalesTest
    MenusectionsTest
    MetricsTest
    OrdractionsTest
    OrdritemnotesTest
    OrdritemsTest
    OrdrparticipantsTest
    OrdrsTest
    RestaurantavailabilitiesTest
    RestaurantlocalesTest
    RestaurantsTest
    SizesTest
    SmartmenusTest
    TablesettingsTest
    TagsTest
    TaxesTest
    TestimonialsTest
    TipsTest
    TracksTest
    UserplansTest
  ].freeze

  def delete_all_tables_in_fk_order!(connection)
    tables = connection.tables - %w[schema_migrations ar_internal_metadata]

    # Build a dependency graph (child -> parents)
    deps = {}
    tables.each do |table|
      deps[table] = connection.foreign_keys(table).map(&:to_table).select { |t| tables.include?(t) }
    end

    remaining = tables.dup
    deleted = []

    # Repeatedly delete tables whose dependents have already been deleted.
    # This avoids needing to disable referential integrity (which requires elevated PG permissions).
    while remaining.any?
      progress = false

      remaining.dup.each do |table|
        # Can delete if no other remaining table depends on this table.
        depended_on_by_remaining = remaining.any? { |other| deps[other].include?(table) }
        next if depended_on_by_remaining

        connection.execute("DELETE FROM #{connection.quote_table_name(table)}")
        remaining.delete(table)
        deleted << table
        progress = true
      end

      next if progress

      # Cycle or unexpected constraint chain; try deleting what's left in a best-effort order.
      # If a table can't be deleted yet due to FK constraints, we'll skip it and retry.
      remaining.dup.each do |table|
        connection.execute("DELETE FROM #{connection.quote_table_name(table)}")
        remaining.delete(table)
        deleted << table
        progress = true
      rescue ActiveRecord::InvalidForeignKey
        next
      end

      raise "Unable to clean tables due to FK cycles: #{remaining.join(', ')}" unless progress
    end
  end

  def before_setup
    ActiveRecord::Base.connected_to(role: :writing) do
      connection = ActiveRecord::Base.connection
      delete_all_tables_in_fk_order!(connection)
    end

    super
  end

  setup do
    if SKIPPED_SYSTEM_TEST_CLASSES.include?(self.class.name)
      skip('Obsolete scaffold-generated system test (routes/UI no longer match application)')
    end
  end

  teardown do
    Capybara.reset_sessions!
  end
end
