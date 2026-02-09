email = ENV.fetch('EMAIL', 'admin@mellow.menu').to_s.strip.downcase

user = User.find_by('LOWER(email) = ?', email)

if user.nil?
  puts "User not found for email=#{email.inspect}"
  exit 1
end

updates = {}
updates[:admin] = true if user.respond_to?(:admin) && !user.admin?
updates[:super_admin] = true if user.respond_to?(:super_admin) && !user.super_admin?

if updates.empty?
  puts "No changes needed. #{user.email} already has admin=#{user.admin?} super_admin=#{user.super_admin?}"
  exit 0
end

user.update!(updates)
puts "Updated #{user.email}: #{updates.inspect}"
