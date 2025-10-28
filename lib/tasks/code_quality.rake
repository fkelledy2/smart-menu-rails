namespace :code_quality do
  desc 'Run all code quality checks'
  task all: %i[rubocop brakeman bundle_audit]

  desc 'Run RuboCop with auto-correct'
  task rubocop: :environment do
    puts '🔍 Running RuboCop with auto-correct...'
    sh 'bundle exec rubocop -A'
  end

  desc 'Run RuboCop without auto-correct'
  task rubocop_check: :environment do
    puts '🔍 Running RuboCop...'
    sh 'bundle exec rubocop'
  end

  desc 'Run Brakeman security scan'
  task brakeman: :environment do
    puts '🔒 Running Brakeman security scan...'
    sh 'bundle exec brakeman --config-file config/brakeman.yml --no-pager'
  end

  desc 'Run Bundler Audit'
  task bundle_audit: :environment do
    puts '📦 Running Bundler Audit...'
    sh 'bundle exec bundler-audit check --update'
  end

  desc 'Generate code quality report'
  task report: :environment do
    require 'fileutils'

    report_dir = 'tmp/code_quality'
    FileUtils.mkdir_p(report_dir)

    puts "📝 Generating code quality reports in #{report_dir}..."

    # RuboCop report
    puts '  Generating RuboCop reports...'
    system("bundle exec rubocop --format html --out #{report_dir}/rubocop.html")
    system("bundle exec rubocop --format json --out #{report_dir}/rubocop.json")

    # Brakeman report
    puts '  Generating Brakeman reports...'
    system("bundle exec brakeman --config-file config/brakeman.yml --format html --output #{report_dir}/brakeman.html --no-pager")
    system("bundle exec brakeman --config-file config/brakeman.yml --format json --output #{report_dir}/brakeman.json --no-pager")

    puts '✅ Reports generated successfully!'
    puts "   - RuboCop HTML: #{report_dir}/rubocop.html"
    puts "   - RuboCop JSON: #{report_dir}/rubocop.json"
    puts "   - Brakeman HTML: #{report_dir}/brakeman.html"
    puts "   - Brakeman JSON: #{report_dir}/brakeman.json"
  end

  desc 'Check code quality and fail if issues found'
  task ci: :environment do
    puts '🚀 Running CI code quality checks...'

    errors = []

    # Run RuboCop
    print '  RuboCop... '
    if system('bundle exec rubocop --format progress')
      puts '✅'
    else
      puts '❌'
      errors << 'RuboCop found style violations'
    end

    # Run Brakeman
    print '  Brakeman... '
    if system('bundle exec brakeman --config-file config/brakeman.yml --quiet --no-pager')
      puts '✅'
    else
      puts '❌'
      errors << 'Brakeman found security issues'
    end

    # Run Bundler Audit
    print '  Bundler Audit... '
    if system('bundle exec bundler-audit check --update')
      puts '✅'
    else
      puts '❌'
      errors << 'Bundler Audit found vulnerable dependencies'
    end

    if errors.empty?
      puts "\n✅ All code quality checks passed!"
    else
      puts "\n❌ Code quality checks failed:"
      errors.each { |error| puts "   - #{error}" }
      exit 1
    end
  end
end
