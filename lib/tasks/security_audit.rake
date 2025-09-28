namespace :security do
  desc "Audit controllers for missing authorization"
  task audit: :environment do
    puts "🔍 Security Audit: Checking all controllers for authorization..."
    puts "=" * 60
    
    controllers_path = Rails.root.join('app', 'controllers')
    controller_files = Dir.glob("#{controllers_path}/**/*_controller.rb")
    
    missing_auth = []
    has_auth = []
    
    controller_files.each do |file|
      next if file.include?('application_controller.rb')
      next if file.include?('madmin/') # Admin controllers handled separately
      next if file.include?('api/v1/base_controller.rb') # Base controller
      
      content = File.read(file)
      controller_name = File.basename(file, '.rb').camelize
      
      has_authenticate = content.include?('authenticate_user!')
      has_authorize = content.include?('authorize ') || content.include?('authorize(')
      has_policy_scope = content.include?('policy_scope')
      has_verify_authorized = content.include?('verify_authorized')
      
      if has_authenticate && (has_authorize || has_verify_authorized)
        has_auth << {
          file: file.gsub(Rails.root.to_s + '/', ''),
          controller: controller_name,
          methods: {
            authenticate: has_authenticate,
            authorize: has_authorize,
            policy_scope: has_policy_scope,
            verify_authorized: has_verify_authorized
          }
        }
      else
        missing_auth << {
          file: file.gsub(Rails.root.to_s + '/', ''),
          controller: controller_name,
          has_authenticate: has_authenticate,
          has_authorize: has_authorize
        }
      end
    end
    
    puts "✅ Controllers WITH proper authorization (#{has_auth.length}):"
    has_auth.each do |controller|
      puts "  - #{controller[:controller]}"
      puts "    📁 #{controller[:file]}"
      methods = controller[:methods]
      puts "    🔐 authenticate: #{methods[:authenticate]}, authorize: #{methods[:authorize]}, policy_scope: #{methods[:policy_scope]}, verify: #{methods[:verify_authorized]}"
      puts
    end
    
    puts "❌ Controllers MISSING authorization (#{missing_auth.length}):"
    missing_auth.each do |controller|
      puts "  - #{controller[:controller]}"
      puts "    📁 #{controller[:file]}"
      puts "    🔐 authenticate: #{controller[:has_authenticate]}, authorize: #{controller[:has_authorize]}"
      puts
    end
    
    puts "=" * 60
    puts "📊 Summary:"
    puts "  Total controllers: #{controller_files.length}"
    puts "  With authorization: #{has_auth.length}"
    puts "  Missing authorization: #{missing_auth.length}"
    puts "  Security coverage: #{((has_auth.length.to_f / (has_auth.length + missing_auth.length)) * 100).round(1)}%"
  end
end
