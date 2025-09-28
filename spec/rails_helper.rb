# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
# Resolve to project_root/config/environment.rb (spec folder is directly under project root)
require File.expand_path('../config/environment', __dir__)
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
require 'devise'

# Require supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern option
# on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Rails.root.glob('spec/support/**/*.rb').each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = Rails.root.join('spec', 'fixtures', 'fixtures').to_s

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # Include FactoryBot methods like build/create
  config.include FactoryBot::Syntax::Methods

  # Devise helpers for request specs
  config.include Devise::Test::IntegrationHelpers, type: :request

  # Devise helpers for controller specs
  config.include Devise::Test::ControllerHelpers, type: :controller

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
