require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]
  
  # System tests run in a separate thread, so transactional fixtures don't work
  # We need to manually clean up the database after each test
  self.use_transactional_tests = false
  
  setup do
    # Load fixtures before each test since transactional tests are disabled
    ActiveRecord::FixtureSet.reset_cache
    ActiveRecord::FixtureSet.create_fixtures(Rails.root.join('test', 'fixtures'), self.class.fixture_table_names)
  end
  
  teardown do
    # Clean up all test data after each test
    # Delete in reverse order of foreign key dependencies
    Ordraction.delete_all  # Must be first - references ordrparticipants
    Ordritem.delete_all
    Ordrparticipant.delete_all
    Ordr.delete_all
    
    Capybara.reset_sessions!
  end
end
