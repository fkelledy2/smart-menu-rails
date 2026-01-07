class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Configure read replica routing
  connects_to database: {
    writing: :primary,
    reading: :replica,
  }

  # Class methods for explicit replica routing
  class << self
    # Execute block on read replica with fallback to primary
    def on_replica(&)
      ActiveRecord::Base.connected_to(role: :reading, &)
    rescue ActiveRecord::ConnectionNotEstablished => e
      Rails.logger.warn "Read replica unavailable, falling back to primary: #{e.message}"
      ActiveRecord::Base.connected_to(role: :writing, &)
    end

    # Execute block on primary database
    def on_primary(&)
      ActiveRecord::Base.connected_to(role: :writing, &)
    end

    # Check if currently connected to replica
    def using_replica?
      connection.pool.db_config.name.to_s.include?('replica')
    rescue StandardError
      false
    end
  end
end
