# frozen_string_literal: true

ActiveSupport.on_load(:active_support_cache) do
  next if ActiveSupport::Cache::Store.method_defined?(:expire)

  module CacheExpireCompat
    def expire(key, ttl)
      value = read(key)
      return false if value.nil?

      write(key, value, expires_in: ttl)
    end
  end

  ActiveSupport::Cache::Store.prepend(CacheExpireCompat)
end
