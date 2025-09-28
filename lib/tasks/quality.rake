# Quality assurance tasks for Smart Menu Rails application
# Run these tasks before committing code or deploying

namespace :quality do
  desc 'Run all quality checks (security, style, tests)'
  task all: %i[security style test] do
    puts "\n🎉 All quality checks passed!"
  end

  desc 'Run security checks (Brakeman + Bundler Audit)'
  task security: :environment do
    puts "\n🔒 Running security checks..."

    puts "\n📦 Checking for vulnerable dependencies..."
    system('bundle exec bundler-audit update') || abort('Failed to update bundler-audit database')
    system('bundle exec bundler-audit check') || abort('❌ Bundler audit found vulnerabilities!')

    puts "\n🛡️  Running Brakeman security scan..."
    system('bundle exec brakeman --config-file config/brakeman.yml') || abort('❌ Brakeman found security issues!')

    puts '✅ Security checks passed!'
  end

  desc 'Run code style checks (RuboCop)'
  task style: :environment do
    puts "\n✨ Running code style checks..."

    puts "\n📏 Running RuboCop..."
    system('bundle exec rubocop') || abort('❌ RuboCop found style violations!')

    puts '✅ Code style checks passed!'
  end

  desc 'Run test suite with coverage'
  task test: :environment do
    puts "\n🧪 Running test suite..."

    # Set test environment
    ENV['RAILS_ENV'] = 'test'

    puts "\n🗄️  Setting up test database..."
    system('bundle exec rails db:test:prepare') || abort('❌ Failed to prepare test database!')

    puts "\n🏃 Running Minitest suite..."
    system('bundle exec rails test') || abort('❌ Tests failed!')

    # Run RSpec if available
    if system('bundle show rspec-rails > /dev/null 2>&1')
      puts "\n🏃 Running RSpec suite..."
      system('bundle exec rspec') || abort('❌ RSpec tests failed!')
    end

    puts '✅ All tests passed!'
  end

  desc 'Run performance checks (Bullet N+1 detection)'
  task performance: :environment do
    puts "\n⚡ Running performance checks..."

    ENV['RAILS_ENV'] = 'test'

    puts "\n🎯 Running Bullet N+1 query detection..."
    if File.exist?('test/performance/bullet_test.rb')
      system('bundle exec rails test test/performance/bullet_test.rb') || abort('❌ Bullet tests failed!')
    else
      puts 'ℹ️  No Bullet performance tests found'
    end

    puts '✅ Performance checks completed!'
  end

  desc 'Auto-fix code style issues where possible'
  task fix: :environment do
    puts "\n🔧 Auto-fixing code style issues..."

    puts "\n📏 Running RuboCop with auto-correct..."
    system('bundle exec rubocop --autocorrect-all')

    puts '✅ Auto-fix completed! Review changes before committing.'
  end

  desc 'Generate security and quality reports'
  task reports: :environment do
    puts "\n📊 Generating quality reports..."

    # Create reports directory
    FileUtils.mkdir_p('tmp/reports')

    puts "\n📋 Generating RuboCop report..."
    system('bundle exec rubocop --format html --out tmp/reports/rubocop.html')
    system('bundle exec rubocop --format json --out tmp/reports/rubocop.json')

    puts "\n🛡️  Generating Brakeman report..."
    system('bundle exec brakeman --config-file config/brakeman.yml --format html --output tmp/reports/brakeman.html')
    system('bundle exec brakeman --config-file config/brakeman.yml --format json --output tmp/reports/brakeman.json')

    puts "\n📦 Generating Bundler Audit report..."
    system('bundle exec bundler-audit check --format json > tmp/reports/bundler-audit.json')

    puts '✅ Reports generated in tmp/reports/'
    puts '   - tmp/reports/rubocop.html'
    puts '   - tmp/reports/brakeman.html'
    puts '   - tmp/reports/bundler-audit.json'
  end

  desc 'Check if code is ready for deployment'
  task deploy_ready: %i[security style test] do
    puts "\n🚀 Checking deployment readiness..."

    puts "\n📋 Checking for pending migrations..."
    system('bundle exec rails db:migrate:status') || abort('❌ Database migration check failed!')

    puts "\n🔑 Verifying Rails credentials..."
    system('bundle exec rails credentials:show > /dev/null') || abort('❌ Rails credentials verification failed!')

    puts "\n🎨 Testing asset compilation..."
    system('RAILS_ENV=production bundle exec rails assets:precompile') || abort('❌ Asset compilation failed!')

    puts "\n✅ Code is ready for deployment! 🚀"
  end

  desc 'Clean up generated files and reports'
  task clean: :environment do
    puts "\n🧹 Cleaning up generated files..."

    FileUtils.rm_rf('tmp/reports')
    FileUtils.rm_rf('coverage')
    FileUtils.rm_f('tmp/rubocop.json')
    FileUtils.rm_f('tmp/brakeman.json')

    puts '✅ Cleanup completed!'
  end
end

# Convenience aliases
task quality: 'quality:all'
task security: 'quality:security'
task style: 'quality:style'
