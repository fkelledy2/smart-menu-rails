updates = {
  'plan.pro.key' => 150,
  'plan.business.key' => 300,
  'professional' => 150,
  'business' => 300,
}

dry_run = ENV['DRY_RUN'].to_s == 'true'

puts "DRY_RUN=#{dry_run}"

updates.each do |key, new_limit|
  plan = Plan.find_by(key: key)
  next unless plan

  old = plan.itemspermenu
  if old == new_limit
    puts "#{key}: already itemspermenu=#{old}"
    next
  end

  puts "#{key}: itemspermenu #{old.inspect} -> #{new_limit}"
  plan.update!(itemspermenu: new_limit) unless dry_run
end

puts 'Done.'
