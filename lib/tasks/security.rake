namespace :security do
  desc 'Run all security checks'
  task all: [:brakeman, :bundle_audit, :secrets_scan]

  desc 'Run Brakeman security scan'
  task :brakeman do
    puts '🔒 Running Brakeman security scan...'
    sh 'bundle exec brakeman --config-file config/brakeman.yml --no-pager'
  end

  desc 'Run Bundler Audit for dependency vulnerabilities'
  task :bundle_audit do
    puts '📦 Checking for vulnerable dependencies...'
    sh 'bundle exec bundler-audit check --update'
  end

  desc 'Scan for potential secrets in codebase'
  task :secrets_scan do
    puts '🔍 Scanning for potential secrets...'
    
    # Patterns to detect potential secrets
    patterns = [
      { name: 'Password', regex: /password\s*=\s*['"][^'"]+['"]/i },
      { name: 'API Key', regex: /api[_-]?key\s*=\s*['"][^'"]+['"]/i },
      { name: 'Secret', regex: /secret\s*=\s*['"][^'"]+['"]/i },
      { name: 'Token', regex: /token\s*=\s*['"][^'"]+['"]/i },
      { name: 'Access Key', regex: /access[_-]?key\s*=\s*['"][^'"]+['"]/i },
    ]
    
    findings = []
    
    Dir.glob('**/*.rb').each do |file|
      next if file.include?('vendor/') || file.include?('node_modules/') || file.include?('tmp/')
      
      File.readlines(file).each_with_index do |line, index|
        # Skip comments
        next if line.strip.start_with?('#')
        
        patterns.each do |pattern|
          if line.match?(pattern[:regex])
            findings << {
              type: pattern[:name],
              file: file,
              line: index + 1,
              content: line.strip
            }
          end
        end
      end
    end
    
    if findings.empty?
      puts '✅ No potential secrets found'
    else
      puts "⚠️  Found #{findings.size} potential secret(s):"
      findings.each do |finding|
        puts "\n  #{finding[:type]} in #{finding[:file]}:#{finding[:line]}"
        puts "    #{finding[:content]}"
      end
      puts "\n⚠️  Please review these findings and ensure no actual secrets are committed"
    end
  end

  desc 'Generate security report'
  task :report do
    require 'fileutils'
    require 'json'
    
    report_dir = 'tmp/security'
    FileUtils.mkdir_p(report_dir)
    
    puts "📝 Generating security reports in #{report_dir}..."
    
    # Brakeman report
    puts '  Generating Brakeman report...'
    system("bundle exec brakeman --config-file config/brakeman.yml --format html --output #{report_dir}/brakeman.html --no-pager")
    system("bundle exec brakeman --config-file config/brakeman.yml --format json --output #{report_dir}/brakeman.json --no-pager")
    
    # Bundler Audit report
    puts '  Generating Bundler Audit report...'
    audit_output = `bundle exec bundler-audit check --update 2>&1`
    File.write("#{report_dir}/bundler_audit.txt", audit_output)
    
    puts "✅ Security reports generated!"
    puts "   - Brakeman HTML: #{report_dir}/brakeman.html"
    puts "   - Brakeman JSON: #{report_dir}/brakeman.json"
    puts "   - Bundler Audit: #{report_dir}/bundler_audit.txt"
  end

  desc 'Check security and fail if vulnerabilities found'
  task :ci do
    puts '🚀 Running CI security checks...'
    
    errors = []
    
    # Run Brakeman
    print '  Brakeman... '
    if system('bundle exec brakeman --config-file config/brakeman.yml --quiet --no-pager --exit-on-warn')
      puts '✅'
    else
      puts '❌'
      errors << 'Brakeman found security vulnerabilities'
    end
    
    # Run Bundler Audit
    print '  Bundler Audit... '
    if system('bundle exec bundler-audit check --update')
      puts '✅'
    else
      puts '❌'
      errors << 'Vulnerable dependencies detected'
    end
    
    if errors.empty?
      puts "\n✅ All security checks passed!"
    else
      puts "\n❌ Security checks failed:"
      errors.each { |error| puts "   - #{error}" }
      exit 1
    end
  end
end
