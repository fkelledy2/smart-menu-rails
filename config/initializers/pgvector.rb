
vector_enabled_env = ENV['SMART_MENU_VECTOR_SEARCH_ENABLED']
vector_feature_enabled = if vector_enabled_env.nil? || vector_enabled_env.to_s.strip == ''
                           true
                         else
                           vector_enabled_env.to_s.downcase == 'true'
                         end

begin
  require 'pgvector' if vector_feature_enabled
rescue LoadError
  vector_feature_enabled = false
end

if vector_feature_enabled
  module PgvectorActiveRecord
    class VectorType < ActiveRecord::Type::Value
      def type
        :vector
      end

      def cast(value)
        return nil if value.nil?
        return value if value.is_a?(Pgvector::Vector)
        return Pgvector::Vector.new(value) if value.is_a?(Array)

        Pgvector::Vector.from_text(value.to_s)
      rescue StandardError
        nil
      end

      def deserialize(value)
        cast(value)
      end

      def serialize(value)
        v = cast(value)
        v&.to_s
      end
    end

    module PostgresAdapterTypeMap
      private

      def initialize_type_map
        super

        begin
          type_map.register_type('vector', PgvectorActiveRecord::VectorType.new)
        rescue StandardError
        end
      end
    end
  end

  ActiveSupport.on_load(:active_record_postgresqladapter) do
    unless ActiveRecord::ConnectionAdapters::PostgreSQLAdapter < PgvectorActiveRecord::PostgresAdapterTypeMap
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(PgvectorActiveRecord::PostgresAdapterTypeMap)
    end
  end
end
