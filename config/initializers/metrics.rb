# Metrics collection configuration - temporarily disabled
# TODO: Re-enable after fixing Rails initialization issue
=begin
  
  # Configure ActiveRecord to track database metrics
  if defined?(ActiveRecord)
    ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
      # Skip schema queries and internal Rails queries
      next if payload[:name] == 'SCHEMA' || payload[:sql].include?('SHOW TABLES')
      
      duration = finish - start
      table_name = extract_table_name(payload[:sql])
      query_type = extract_query_type(payload[:sql])
      
      MetricsCollector.increment(:db_queries_total, 1, query_type: query_type, table: table_name)
      MetricsCollector.observe(:db_query_duration, duration, query_type: query_type, table: table_name)
      
      # Track slow queries separately
      if duration > 0.1 # Queries slower than 100ms
        MetricsCollector.increment(:slow_db_queries_total, 1, query_type: query_type, table: table_name)
      end
    end
  end
  
  # Configure ActionController to track additional metrics
  if defined?(ActionController)
    ActiveSupport::Notifications.subscribe('process_action.action_controller') do |name, start, finish, id, payload|
      duration = finish - start
      controller = payload[:controller]
      action = payload[:action]
      status = payload[:status]
      
      # Track controller performance
      MetricsCollector.observe(
        :controller_action_duration,
        duration,
        controller: controller,
        action: action,
        status: status
      )
      
      # Track view rendering time if available
      if payload[:view_runtime]
        MetricsCollector.observe(
          :view_render_duration,
          payload[:view_runtime] / 1000.0, # Convert ms to seconds
          controller: controller,
          action: action
        )
      end
      
      # Track database time if available
      if payload[:db_runtime]
        MetricsCollector.observe(
          :controller_db_duration,
          payload[:db_runtime] / 1000.0, # Convert ms to seconds
          controller: controller,
          action: action
        )
      end
    end
  end
  
  # Configure ActionMailer metrics
  if defined?(ActionMailer)
    ActiveSupport::Notifications.subscribe('deliver.action_mailer') do |name, start, finish, id, payload|
      duration = finish - start
      mailer = payload[:mailer]
      
      MetricsCollector.increment(:emails_sent_total, 1, mailer: mailer)
      MetricsCollector.observe(:email_delivery_duration, duration, mailer: mailer)
    end
  end
  
  # Configure ActiveJob metrics
  if defined?(ActiveJob)
    ActiveSupport::Notifications.subscribe('perform.active_job') do |name, start, finish, id, payload|
      duration = finish - start
      job_class = payload[:job].class.name
      
      MetricsCollector.increment(:jobs_performed_total, 1, job_class: job_class)
      MetricsCollector.observe(:job_duration, duration, job_class: job_class)
    end
    
    ActiveSupport::Notifications.subscribe('enqueue.active_job') do |name, start, finish, id, payload|
      job_class = payload[:job].class.name
      MetricsCollector.increment(:jobs_enqueued_total, 1, job_class: job_class)
    end
    # Helper methods for extracting information from SQL queries
    def extract_table_name(sql)
      # Simple regex to extract table name from common SQL patterns
      case sql.upcase
      when /FROM\s+["`]?(\w+)["`]?/i
        $1
      when /UPDATE\s+["`]?(\w+)["`]?/i
        $1
      when /INSERT\s+INTO\s+["`]?(\w+)["`]?/i
        $1
      when /DELETE\s+FROM\s+["`]?(\w+)["`]?/i
        $1
      else
        'unknown'
      end
    rescue
      'unknown'
    end

    def extract_query_type(sql)
      case sql.upcase.strip
      when /^SELECT/
        'SELECT'
      when /^INSERT/
        'INSERT'
      when /^UPDATE/
        'UPDATE'
      when /^DELETE/
        'DELETE'
      when /^CREATE/
        'CREATE'
      when /^DROP/
        'DROP'
      when /^ALTER/
        'ALTER'
      else
        'OTHER'
      end
    rescue
      'OTHER'
    end
  end
end
=end
