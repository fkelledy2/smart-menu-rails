# frozen_string_literal: true

module Agents
  module Tools
    # Agents::Tools::BaseTool — abstract base for all agent tool wrappers.
    # Subclasses must implement:
    #   - .tool_name  [String]
    #   - .description [String]
    #   - .input_schema [Hash] — JSON Schema for input_params
    #   - .call(params) [Hash] — returns output hash
    class BaseTool
      def self.tool_name
        raise NotImplementedError, "#{name} must define .tool_name"
      end

      def self.description
        raise NotImplementedError, "#{name} must define .description"
      end

      def self.input_schema
        raise NotImplementedError, "#{name} must define .input_schema"
      end

      def self.call(params)
        raise NotImplementedError, "#{name} must define .call(params)"
      end
    end
  end
end
