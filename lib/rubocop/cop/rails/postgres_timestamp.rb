# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      class PostgresTimestamp < RuboCop::Cop::Base
        MSG = 'Use t.timestamptz for better timezone support.'
        RESTRICT_ON_SEND = [:datetime, :timestamps].freeze

        def_node_matcher :table_datetime_usage, <<~PATTERN
          (send lvar :datetime ...)
        PATTERN

        def_node_matcher :table_timestamps_usage, <<~PATTERN
          (send lvar :timestamps ...)
        PATTERN

        def on_send(node)
          return unless in_migration_file?
          return unless node.receiver&.name == :t

          add_offense(node, message: MSG) if table_datetime_usage(node) || table_timestamps_usage(node)
        end

        private

        def in_migration_file?
          processed_source.file_path&.include?('db/migrate/') || false
        end
      end
    end
  end
end
