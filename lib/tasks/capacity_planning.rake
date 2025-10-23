# frozen_string_literal: true

namespace :capacity do
  desc 'Generate capacity planning report'
  task report: :environment do
    puts "\n" + "="*80
    puts "CAPACITY PLANNING REPORT".center(80)
    puts "="*80 + "\n"
    
    report = CapacityPlanningService.generate_report([1, 10, 100])
    
    puts "\n📊 CURRENT BASELINE METRICS"
    puts "-" * 80
    report[:current_baseline].each do |key, value|
      puts "  #{key.to_s.humanize.ljust(30)}: #{value}"
    end
    
    report[:scenarios].each do |scenario_name, scenario|
      puts "\n\n🎯 SCENARIO: #{scenario_name.upcase}"
      puts "=" * 80
      
      puts "\n  📈 Projected Metrics:"
      scenario[:metrics].each do |key, value|
        puts "    #{key.to_s.humanize.ljust(28)}: #{value.to_s.rjust(10)}"
      end
      
      puts "\n  🖥️  Infrastructure Requirements:"
      infra = scenario[:infrastructure]
      
      puts "    Application Servers:"
      puts "      Count: #{infra[:app_servers][:count]}"
      puts "      Type: #{infra[:app_servers][:type]} (#{infra[:app_servers][:vcpu]} vCPU, #{infra[:app_servers][:ram_gb]} GB RAM)"
      if infra[:app_servers][:autoscaling]
        puts "      Auto-scaling: #{infra[:app_servers][:autoscaling][:min]}-#{infra[:app_servers][:autoscaling][:max]} instances"
      end
      
      puts "\n    Database:"
      puts "      Primary: #{infra[:database][:primary][:vcpu]} vCPU, #{infra[:database][:primary][:ram_gb]} GB RAM, #{infra[:database][:primary][:storage_gb]} GB storage"
      puts "      Read Replicas: #{infra[:database][:replicas]}"
      puts "      Sharding: #{infra[:database][:sharding] ? 'Yes' : 'No'}" if infra[:database].key?(:sharding)
      
      puts "\n    Cache (Redis):"
      puts "      Size: #{infra[:cache][:size_gb]} GB"
      puts "      Nodes: #{infra[:cache][:nodes]}"
      puts "      Clustering: #{infra[:cache][:clustering] ? 'Yes' : 'No'}" if infra[:cache].key?(:clustering)
      
      puts "\n    Additional Services:"
      puts "      Load Balancer: #{infra[:load_balancer] ? 'Yes' : 'No'}"
      puts "      CDN: #{infra[:cdn] ? 'Yes' : 'No'}"
      puts "      Message Queue: #{infra[:message_queue] ? 'Yes' : 'No'}"
      
      puts "\n  💰 Cost Estimate:"
      costs = scenario[:costs]
      puts "    Application Servers: $#{costs[:app_servers]}/month"
      puts "    Database: $#{costs[:database]}/month"
      puts "    Cache: $#{costs[:cache]}/month"
      puts "    Additional Services: $#{costs[:additional_services]}/month"
      puts "    " + "-" * 50
      puts "    Total Monthly: $#{costs[:total_monthly]}"
      puts "    Total Annual: $#{costs[:total_annual]}"
      
      puts "\n  💡 Recommendations:"
      scenario[:recommendations].each_with_index do |rec, idx|
        puts "    #{idx + 1}. #{rec}"
      end
    end
    
    puts "\n" + "="*80
    puts "Report generated at: #{report[:generated_at]}"
    puts "="*80 + "\n"
  end
  
  desc 'Check if infrastructure can handle target load'
  task :check_load, [:target_users] => :environment do |_t, args|
    target_users = args[:target_users]&.to_i || 10_000
    
    puts "\n" + "="*80
    puts "LOAD CAPACITY CHECK".center(80)
    puts "="*80 + "\n"
    
    result = CapacityPlanningService.can_handle_load?(target_users)
    
    puts "  Target Users: #{result[:target_users]}"
    puts "  Growth Multiplier: #{result[:growth_multiplier]}x"
    puts "  Can Handle: #{result[:can_handle] ? '✅ YES' : '❌ NO'}"
    
    unless result[:can_handle]
      puts "\n  Required Infrastructure Upgrades:"
      infra = result[:required_infrastructure]
      
      puts "    App Servers: #{infra[:app_servers][:count]}x #{infra[:app_servers][:type]}"
      puts "    Database: #{infra[:database][:primary][:vcpu]} vCPU, #{infra[:database][:primary][:ram_gb]} GB RAM"
      puts "    Database Replicas: #{infra[:database][:replicas]}"
      puts "    Redis Cache: #{infra[:cache][:size_gb]} GB"
      
      puts "\n  Estimated Monthly Cost: $#{result[:estimated_cost]}"
    end
    
    puts "\n" + "="*80 + "\n"
  end
  
  desc 'Show current system utilization'
  task utilization: :environment do
    puts "\n" + "="*80
    puts "CURRENT SYSTEM UTILIZATION".center(80)
    puts "="*80 + "\n"
    
    util = CapacityPlanningService.current_utilization
    
    puts "  Timestamp: #{util[:timestamp]}"
    
    if util[:database].present?
      puts "\n  📊 Database:"
      puts "    Pool Size: #{util[:database][:pool_size]}"
      puts "    Active Connections: #{util[:database][:active_connections]}"
      puts "    Available Connections: #{util[:database][:available_connections]}"
      puts "    Utilization: #{util[:database][:utilization_percent]}%"
    end
    
    if util[:cache].present?
      puts "\n  💾 Cache (Redis):"
      puts "    Used Memory: #{util[:cache][:used_memory_mb]} MB"
      puts "    Max Memory: #{util[:cache][:max_memory_mb]} MB"
      puts "    Utilization: #{util[:cache][:utilization_percent]}%"
      puts "    Connected Clients: #{util[:cache][:connected_clients]}"
      puts "    Hit Rate: #{util[:cache][:hit_rate]}%"
    end
    
    if util[:application].present?
      puts "\n  🖥️  Application:"
      puts "    Process Count: #{util[:application][:process_count]}"
      puts "    Memory Usage: #{util[:application][:memory_usage_mb]} MB"
    end
    
    puts "\n" + "="*80 + "\n"
  end
end
